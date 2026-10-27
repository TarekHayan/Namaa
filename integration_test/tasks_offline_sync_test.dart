import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/sync/synchronization_coordinator.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_sync_service.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/supabase_task_reader.dart';
import 'package:namma_project/features/tasks/data/supabase_task_sync_adapter.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/data/task_reconciler.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/tasks_test_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'authenticated offline create/edit/delete survives restart and converges to a second client',
    (tester) async {
      final remote = _SharedTaskRemote();
      final clock = TasksTestClock();
      final firstPath = TemporaryDatabasePath();
      final secondPath = TemporaryDatabasePath();
      final foreignPath = TemporaryDatabasePath();
      addTearDown(firstPath.dispose);
      addTearDown(secondPath.dispose);
      addTearDown(foreignPath.dispose);

      var clientA = await _TestClient.open(
        path: firstPath.allocate(),
        accountId: kTasksTestAccountA,
        remote: remote,
        clock: clock,
      );
      addTearDown(() => clientA.dispose());

      final kept = (await clientA.commands.createTask(
        const CreateTaskInput(title: 'Offline draft'),
      )).valueOrNull!;
      await clientA.commands.editTask(
        EditTaskInput(
          taskId: kept.id,
          title: 'Offline edited',
          description: 'Persisted before reconnect',
        ),
      );
      final deleted = (await clientA.commands.createTask(
        const CreateTaskInput(title: 'Delete offline'),
      )).valueOrNull!;
      await clientA.commands.deleteTask(deleted.id);

      expect(remote.rowsFor(kTasksTestAccountA), isEmpty);
      expect(
        (await clientA.repository.readTask(
          accountId: kTasksTestAccountA,
          taskId: kept.id,
        )).valueOrNull?.title,
        'Offline edited',
      );

      final firstDatabasePath = clientA.database.resolvedPath;
      await clientA.dispose();
      clientA = await _TestClient.open(
        path: firstDatabasePath,
        accountId: kTasksTestAccountA,
        remote: remote,
        clock: clock,
      );
      expect(
        (await clientA.repository.readTask(
          accountId: kTasksTestAccountA,
          taskId: kept.id,
        )).valueOrNull?.title,
        'Offline edited',
      );

      clientA.connectivity.goOnline();
      final upload = await clientA.sync.synchronize();
      expect(upload.failureOrNull, isNull);
      expect(clientA.sync.snapshot.initialSyncComplete, isTrue);
      expect(remote.rowsFor(kTasksTestAccountA), hasLength(2));
      expect(remote.operationIds.toSet().length, remote.operationIds.length);

      clientA.connectivity.goOffline();
      final offlineRetry = await clientA.sync.synchronize();
      expect(offlineRetry.failureOrNull, isNotNull);
      expect(
        clientA.sync.snapshot.status,
        TaskInitialSyncStatus.ready,
        reason: 'a later offline failure must not revoke initial readiness',
      );

      final clientB = await _TestClient.open(
        path: secondPath.allocate(),
        accountId: kTasksTestAccountA,
        remote: remote,
        clock: clock,
      );
      addTearDown(clientB.dispose);
      clientB.connectivity.goOnline();
      final download = await clientB.sync.synchronize();

      expect(download.failureOrNull, isNull);
      expect(clientB.sync.snapshot.initialSyncComplete, isTrue);
      final visibleOnB = await clientB.repository
          .watchTasks(kTasksTestAccountA)
          .first;
      expect(visibleOnB.map((task) => task.title), <String>['Offline edited']);
      expect(
        (await clientB.repository.readTask(
          accountId: kTasksTestAccountA,
          taskId: deleted.id,
        )).valueOrNull?.isDeleted,
        isTrue,
        reason: 'a replayed delete remains a tombstone and cannot resurrect',
      );

      final foreignClient = await _TestClient.open(
        path: foreignPath.allocate(),
        accountId: kTasksTestAccountB,
        remote: remote,
        clock: clock,
      );
      addTearDown(foreignClient.dispose);
      foreignClient.connectivity.goOnline();
      await foreignClient.sync.synchronize();

      expect(
        await foreignClient.repository.watchTasks(kTasksTestAccountB).first,
        isEmpty,
      );
      expect(remote.rowsFor(kTasksTestAccountB), isEmpty);
    },
  );
}

final class _TestClient {
  _TestClient._({
    required this.database,
    required this.repository,
    required this.commands,
    required this.connectivity,
    required this.sync,
  });

  static final _key = List<int>.generate(32, (index) => 0x20 + index);

  final FoundationDatabase database;
  final DriftTaskRepository repository;
  final TaskCommands commands;
  final TasksTestConnectivity connectivity;
  final TaskSyncService sync;
  bool _disposed = false;

  static Future<_TestClient> open({
    required String path,
    required String accountId,
    required _SharedTaskRemote remote,
    required TasksTestClock clock,
  }) async {
    const codec = TaskPayloadCodec();
    final database = await FoundationDatabase.openEncrypted(
      path: path,
      key: _key,
    );
    final repository = DriftTaskRepository(database: database, codec: codec);
    final session = _Session(accountId);
    final connectivity = TasksTestConnectivity();
    final gateway = _AccountTaskGateway(accountId: accountId, remote: remote);
    final localStore = DriftLocalStore(database);
    final outbound = SynchronizationCoordinator(
      localStore: localStore,
      cloudSession: session,
      cloudSync: SupabaseTaskSyncAdapter(gateway: gateway),
      now: clock.utcNow,
    );
    final reconciler = TaskReconciler(
      repository: repository,
      localStore: localStore,
      codec: codec,
      detectedAt: clock.utcNow,
    );
    final reader = SupabaseTaskReader(gateway: gateway, codec: codec);
    final awardLedger = DriftAwardLedger(database);
    final sync = TaskSyncService(
      session: session,
      connectivity: connectivity,
      outbound: outbound,
      remoteReader: reader,
      reconciler: reconciler,
      awardReader: reader,
      awardLedger: awardLedger,
    );
    final ids = TasksTestIds();
    final commands = TaskCommands(
      repository: repository,
      session: session,
      nowUtc: clock.utcNow,
      localDate: clock.localDate,
      nextTaskId: ids.nextTaskId,
      nextOperationId: ids.nextOperationId,
    );
    return _TestClient._(
      database: database,
      repository: repository,
      commands: commands,
      connectivity: connectivity,
      sync: sync,
    );
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await sync.dispose();
    await connectivity.dispose();
    await database.close();
  }
}

final class _Session implements CloudSessionPort {
  const _Session(this.accountId);

  final String accountId;

  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.success(
        CloudSyncContext(accountId: accountId),
      );

  @override
  Stream<CloudSessionSnapshot> observeSession() =>
      Stream<CloudSessionSnapshot>.value(
        CloudSessionSnapshot(
          status: CloudSessionStatus.signedIn,
          accountId: accountId,
        ),
      );
}

final class _SharedTaskRemote {
  final Map<String, Map<String, dynamic>> _rows =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _receipts =
      <String, Map<String, dynamic>>{};
  final List<String> operationIds = <String>[];

  List<Map<String, dynamic>> rowsFor(String accountId) => _rows.entries
      .where((entry) => entry.key.startsWith('$accountId/'))
      .map((entry) => entry.value)
      .toList();
}

final class _AccountTaskGateway implements SupabaseTaskGateway {
  _AccountTaskGateway({required this.accountId, required this.remote});

  final String accountId;
  final _SharedTaskRemote remote;

  @override
  Future<Map<String, dynamic>> applyTaskChange({
    required String expectedAccountId,
    required String id,
    required Map<String, dynamic> payload,
    required String operationId,
    required String kind,
    required DateTime updatedAt,
    DateTime? baseUpdatedAt,
  }) async {
    if (expectedAccountId != accountId) {
      throw StateError('Authenticated account changed before Task upload');
    }
    final receiptKey = '$accountId/$operationId';
    final replay = remote._receipts[receiptKey];
    if (replay != null) {
      return <String, dynamic>{...replay, 'replayed': true};
    }

    final rowKey = '$accountId/$id';
    final existing = remote._rows[rowKey];
    final incomingDeletedAt = kind == 'delete' ? updatedAt : null;
    final incoming = <String, dynamic>{
      'id': id,
      'owner': accountId,
      'payload': payload,
      'operation_id': operationId,
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': incomingDeletedAt?.toIso8601String(),
      'conflict_detected': existing != null,
      'retained_payload': existing?['payload'],
      'retained_updated_at': existing?['updated_at'],
      'retained_deleted_at': existing?['deleted_at'],
      'replayed': false,
    };
    if (existing == null ||
        updatedAt.isAfter(DateTime.parse(existing['updated_at'] as String))) {
      remote._rows[rowKey] = incoming;
    }
    final result = remote._rows[rowKey]!;
    final receipt = <String, dynamic>{
      ...result,
      'operation_id': operationId,
      'conflict_detected': existing != null,
      'retained_payload': existing?['payload'],
      'retained_updated_at': existing?['updated_at'],
      'retained_deleted_at': existing?['deleted_at'],
      'replayed': false,
    };
    remote._receipts[receiptKey] = receipt;
    remote.operationIds.add(operationId);
    return receipt;
  }

  @override
  Future<TaskRemotePage> fetchTaskPage({
    required int pageSize,
    String? cursor,
  }) async {
    final rows = remote.rowsFor(accountId)
      ..sort(
        (left, right) =>
            (left['id'] as String).compareTo(right['id'] as String),
      );
    final start = cursor == null ? 0 : int.parse(cursor);
    final requestedEnd = start + pageSize;
    final end = requestedEnd < rows.length ? requestedEnd : rows.length;
    return TaskRemotePage(
      rows: rows.sublist(start, end),
      nextCursor: end < rows.length ? '$end' : null,
    );
  }

  @override
  Future<TaskAwardRemotePage> fetchTaskAwardPage({
    required int pageSize,
    String? cursor,
  }) async => const TaskAwardRemotePage(rows: <Map<String, dynamic>>[]);
}
