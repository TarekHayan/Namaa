import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/task_completion_unit_of_work.dart';
import 'package:namma_project/core/data/sync/synchronization_coordinator.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_sync_service.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/supabase_task_reader.dart';
import 'package:namma_project/features/tasks/data/supabase_task_sync_adapter.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/data/task_reconciler.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/tasks_test_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'ten offline restart cycles and two clients converge to one lifetime award',
    (tester) async {
      final remote = _SharedCompletionRemote();
      final clock = TasksTestClock();
      final ids = _OperationIds();
      final firstPath = TemporaryDatabasePath();
      final secondPath = TemporaryDatabasePath();
      addTearDown(firstPath.dispose);
      addTearDown(secondPath.dispose);

      var clientA = await _CompletionClient.open(
        path: firstPath.allocate(),
        accountId: kTasksTestAccountA,
        remote: remote,
        clock: clock,
        ids: ids,
      );
      addTearDown(() => clientA.dispose());

      final task = (await clientA.commands.createTask(
        const CreateTaskInput(title: 'Offline completion', completionXp: 35),
      )).valueOrNull!;

      for (var cycle = 0; cycle < 10; cycle += 1) {
        clock.advance(const Duration(minutes: 1));
        expect(
          (await clientA.completion.completeTask(task.id)).failureOrNull,
          isNull,
        );
        expect(
          await clientA.awards.watchAwards(kTasksTestAccountA).first,
          hasLength(1),
        );

        final persistedPath = clientA.database.resolvedPath;
        await clientA.dispose();
        clientA = await _CompletionClient.open(
          path: persistedPath,
          accountId: kTasksTestAccountA,
          remote: remote,
          clock: clock,
          ids: ids,
        );
        expect(
          await clientA.awards.watchAwards(kTasksTestAccountA).first,
          hasLength(1),
          reason: 'the first award must survive every offline restart',
        );

        clientA.connectivity.goOnline();
        final synchronized = await clientA.sync.synchronize();
        expect(synchronized.failureOrNull, isNull);
        expect(remote.awardsFor(kTasksTestAccountA), hasLength(1));
        clientA.connectivity.goOffline();

        clock.advance(const Duration(minutes: 1));
        expect(
          (await clientA.completion.reopenTask(task.id)).failureOrNull,
          isNull,
        );
      }

      clock.advance(const Duration(minutes: 1));
      final finalCompletion = await clientA.completion.completeTask(task.id);
      expect(finalCompletion.failureOrNull, isNull);
      final finalCompletedAt = finalCompletion.valueOrNull!.completedAt;
      clientA.connectivity.goOnline();
      expect((await clientA.sync.synchronize()).failureOrNull, isNull);
      expect(remote.awardsFor(kTasksTestAccountA), hasLength(1));
      expect(
        remote.operationIds.toSet(),
        hasLength(remote.operationIds.length),
      );

      final clientB = await _CompletionClient.open(
        path: secondPath.allocate(),
        accountId: kTasksTestAccountA,
        remote: remote,
        clock: clock,
        ids: ids,
      );
      addTearDown(clientB.dispose);
      clientB.connectivity.goOnline();
      expect((await clientB.sync.synchronize()).failureOrNull, isNull);

      final taskOnB = (await clientB.tasks.readTask(
        accountId: kTasksTestAccountA,
        taskId: task.id,
      )).valueOrNull!;
      final awardsOnB = await clientB.awards
          .watchAwards(kTasksTestAccountA)
          .first;
      expect(taskOnB.completedAt, finalCompletedAt);
      expect(awardsOnB, hasLength(1));
      expect(awardsOnB.single.amount, 35);

      clientB.connectivity.goOffline();
      clock.advance(const Duration(minutes: 1));
      expect(
        (await clientB.completion.reopenTask(task.id)).failureOrNull,
        isNull,
      );
      clientB.connectivity.goOnline();
      expect((await clientB.sync.synchronize()).failureOrNull, isNull);

      expect((await clientA.sync.synchronize()).failureOrNull, isNull);
      final reopenedOnA = (await clientA.tasks.readTask(
        accountId: kTasksTestAccountA,
        taskId: task.id,
      )).valueOrNull!;
      expect(reopenedOnA.completedAt, isNull);
      expect(
        await clientA.awards.watchAwards(kTasksTestAccountA).first,
        hasLength(1),
      );
      expect(remote.awardsFor(kTasksTestAccountA), hasLength(1));
    },
  );

  testWidgets('a losing offline completion keeps its award on both clients', (
    tester,
  ) async {
    final remote = _SharedCompletionRemote();
    final clock = TasksTestClock();
    final ids = _OperationIds();
    final firstPath = TemporaryDatabasePath();
    final secondPath = TemporaryDatabasePath();
    addTearDown(firstPath.dispose);
    addTearDown(secondPath.dispose);

    final clientA = await _CompletionClient.open(
      path: firstPath.allocate(),
      accountId: kTasksTestAccountA,
      remote: remote,
      clock: clock,
      ids: ids,
    );
    addTearDown(clientA.dispose);
    final task = (await clientA.commands.createTask(
      const CreateTaskInput(title: 'Open on both devices', completionXp: 35),
    )).valueOrNull!;
    clientA.connectivity.goOnline();
    expect((await clientA.sync.synchronize()).failureOrNull, isNull);
    clientA.connectivity.goOffline();

    final clientB = await _CompletionClient.open(
      path: secondPath.allocate(),
      accountId: kTasksTestAccountA,
      remote: remote,
      clock: clock,
      ids: ids,
    );
    addTearDown(clientB.dispose);
    clientB.connectivity.goOnline();
    expect((await clientB.sync.synchronize()).failureOrNull, isNull);

    clock.advance(const Duration(minutes: 1));
    final completed = (await clientA.completion.completeTask(
      task.id,
    )).valueOrNull!;
    clock.advance(const Duration(minutes: 1));
    expect(
      (await clientB.commands.editTask(
        EditTaskInput(taskId: task.id, title: 'Newer device edit'),
      )).failureOrNull,
      isNull,
    );
    expect((await clientB.sync.synchronize()).failureOrNull, isNull);

    clientA.connectivity.goOnline();
    expect((await clientA.sync.synchronize()).failureOrNull, isNull);
    expect((await clientB.sync.synchronize()).failureOrNull, isNull);

    final activeOnA = (await clientA.tasks.readTask(
      accountId: kTasksTestAccountA,
      taskId: task.id,
    )).valueOrNull!;
    expect(activeOnA.title, 'Newer device edit');
    expect(activeOnA.completedAt, isNull);
    expect(remote.awardsFor(kTasksTestAccountA), hasLength(1));
    for (final client in <_CompletionClient>[clientA, clientB]) {
      final awards = await client.awards.watchAwards(kTasksTestAccountA).first;
      expect(awards, hasLength(1));
      expect(awards.single.amount, 35);
      expect(awards.single.awardedAt, completed.completedAt);
    }
    expect(
      await clientA.tasks.watchConflicts(kTasksTestAccountA).first,
      isNotEmpty,
    );
  });

  testWidgets('two offline completions converge to the first remote award', (
    tester,
  ) async {
    final remote = _SharedCompletionRemote();
    final clock = TasksTestClock();
    final ids = _OperationIds();
    final firstPath = TemporaryDatabasePath();
    final secondPath = TemporaryDatabasePath();
    addTearDown(firstPath.dispose);
    addTearDown(secondPath.dispose);

    final clientA = await _CompletionClient.open(
      path: firstPath.allocate(),
      accountId: kTasksTestAccountA,
      remote: remote,
      clock: clock,
      ids: ids,
    );
    addTearDown(clientA.dispose);
    final task = (await clientA.commands.createTask(
      const CreateTaskInput(title: 'Two offline completions', completionXp: 35),
    )).valueOrNull!;
    clientA.connectivity.goOnline();
    expect((await clientA.sync.synchronize()).failureOrNull, isNull);
    clientA.connectivity.goOffline();

    final clientB = await _CompletionClient.open(
      path: secondPath.allocate(),
      accountId: kTasksTestAccountA,
      remote: remote,
      clock: clock,
      ids: ids,
    );
    addTearDown(clientB.dispose);
    clientB.connectivity.goOnline();
    expect((await clientB.sync.synchronize()).failureOrNull, isNull);
    clientB.connectivity.goOffline();

    clock.advance(const Duration(minutes: 1));
    final firstLocal = (await clientA.completion.completeTask(
      task.id,
    )).valueOrNull!;
    clock.advance(const Duration(minutes: 1));
    final firstRemote = (await clientB.completion.completeTask(
      task.id,
    )).valueOrNull!;
    clientB.connectivity.goOnline();
    expect((await clientB.sync.synchronize()).failureOrNull, isNull);
    expect(remote.awardsFor(kTasksTestAccountA), hasLength(1));

    expect(
      (await clientA.awards.watchAwards(kTasksTestAccountA).first)
          .single
          .awardedAt,
      firstLocal.completedAt,
    );
    clientA.connectivity.goOnline();
    expect((await clientA.sync.synchronize()).failureOrNull, isNull);

    final awardOnA =
        (await clientA.awards.watchAwards(kTasksTestAccountA).first).single;
    final awardOnB =
        (await clientB.awards.watchAwards(kTasksTestAccountA).first).single;
    expect(awardOnA, awardOnB);
    expect(awardOnA.awardedAt, firstRemote.completedAt);
    expect(awardOnA.amount, 35);
    expect(remote.awardsFor(kTasksTestAccountA), hasLength(1));
    expect(
      await clientA.tasks.watchConflicts(kTasksTestAccountA).first,
      isNotEmpty,
    );
  });
}

final class _CompletionClient {
  _CompletionClient._({
    required this.database,
    required this.tasks,
    required this.awards,
    required this.commands,
    required this.completion,
    required this.connectivity,
    required this.sync,
  });

  static final _key = List<int>.generate(32, (index) => 0x41 + index);

  final FoundationDatabase database;
  final DriftTaskRepository tasks;
  final DriftAwardLedger awards;
  final TaskCommands commands;
  final TaskCompletionService completion;
  final TasksTestConnectivity connectivity;
  final TaskSyncService sync;
  bool _disposed = false;

  static Future<_CompletionClient> open({
    required String path,
    required String accountId,
    required _SharedCompletionRemote remote,
    required TasksTestClock clock,
    required _OperationIds ids,
  }) async {
    const codec = TaskPayloadCodec();
    final database = await FoundationDatabase.openEncrypted(
      path: path,
      key: _key,
    );
    final tasks = DriftTaskRepository(database: database, codec: codec);
    final awards = DriftAwardLedger(database);
    final session = _Session(accountId);
    final connectivity = TasksTestConnectivity();
    final gateway = _CompletionGateway(accountId: accountId, remote: remote);
    final localStore = DriftLocalStore(database);
    final reader = SupabaseTaskReader(gateway: gateway, codec: codec);
    final outbound = SynchronizationCoordinator(
      localStore: localStore,
      cloudSession: session,
      cloudSync: SupabaseTaskSyncAdapter(gateway: gateway),
      now: clock.utcNow,
    );
    final sync = TaskSyncService(
      session: session,
      connectivity: connectivity,
      outbound: outbound,
      remoteReader: reader,
      reconciler: TaskReconciler(
        repository: tasks,
        localStore: localStore,
        codec: codec,
        detectedAt: clock.utcNow,
      ),
      awardReader: reader,
      awardLedger: awards,
    );
    final taskIds = TasksTestIds();
    final commands = TaskCommands(
      repository: tasks,
      session: session,
      nowUtc: clock.utcNow,
      localDate: clock.localDate,
      nextTaskId: taskIds.nextTaskId,
      nextOperationId: ids.next,
    );
    final completion = TaskCompletionService(
      repository: tasks,
      unitOfWork: DriftTaskCompletionUnitOfWork(
        database: database,
        codec: codec,
        awardLedger: awards,
      ),
      session: session,
      nowUtc: clock.utcNow,
      nextOperationId: ids.next,
    );
    return _CompletionClient._(
      database: database,
      tasks: tasks,
      awards: awards,
      commands: commands,
      completion: completion,
      connectivity: connectivity,
      sync: sync,
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
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

final class _OperationIds {
  int _value = 0;

  String next() {
    _value += 1;
    return 'completion-operation-${_value.toString().padLeft(4, '0')}';
  }
}

final class _SharedCompletionRemote {
  final Map<String, Map<String, dynamic>> _tasks = {};
  final Map<String, Map<String, dynamic>> _awards = {};
  final Map<String, Map<String, dynamic>> _receipts = {};
  final List<String> operationIds = [];

  List<Map<String, dynamic>> tasksFor(String accountId) => _tasks.entries
      .where((entry) => entry.key.startsWith('$accountId/'))
      .map((entry) => entry.value)
      .toList();

  List<Map<String, dynamic>> awardsFor(String accountId) => _awards.entries
      .where((entry) => entry.key.startsWith('$accountId/'))
      .map((entry) => entry.value)
      .toList();
}

final class _CompletionGateway implements SupabaseTaskGateway {
  _CompletionGateway({required this.accountId, required this.remote});

  final String accountId;
  final _SharedCompletionRemote remote;

  @override
  Future<Map<String, dynamic>> applyTaskChange({
    required String expectedAccountId,
    required String id,
    required Map<String, dynamic> payload,
    required String operationId,
    required String kind,
    required DateTime updatedAt,
  }) async {
    if (expectedAccountId != accountId) {
      throw StateError('Authenticated account changed before Task upload');
    }
    final receiptKey = '$accountId/$operationId';
    final replay = remote._receipts[receiptKey];
    if (replay != null) return {...replay, 'replayed': true};

    final rowKey = '$accountId/$id';
    final existing = remote._tasks[rowKey];
    final incomingDeletedAt = kind == 'delete' ? updatedAt : null;
    final incomingWins =
        existing == null ||
        updatedAt.isAfter(DateTime.parse(existing['updated_at'] as String));
    final storedPayload = existing?['payload'] as Map<String, dynamic>?;
    final activePayload = kind == 'delete' && storedPayload != null
        ? storedPayload
        : <String, dynamic>{
            ...payload,
            if (storedPayload?.containsKey('completionXp') ?? false)
              'completionXp': storedPayload!['completionXp'],
          };
    final incoming = <String, dynamic>{
      'id': id,
      'owner': accountId,
      'payload': activePayload,
      'operation_id': operationId,
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': incomingDeletedAt?.toIso8601String(),
      'conflict_detected': existing != null,
      'retained_payload': incomingWins ? (existing?['payload']) : payload,
      'retained_updated_at': incomingWins
          ? (existing?['updated_at'])
          : updatedAt.toIso8601String(),
      'retained_deleted_at': incomingWins
          ? (existing?['deleted_at'])
          : incomingDeletedAt?.toIso8601String(),
      'replayed': false,
    };
    if (incomingWins) {
      remote._tasks[rowKey] = incoming;
    }

    final completedAt = kind == 'delete'
        ? null
        : payload['completedAt'] as String?;
    if (completedAt != null) {
      remote._awards.putIfAbsent(
        '$accountId/$kTaskDoneAwardSource/$id',
        () => <String, dynamic>{
          'owner': accountId,
          'source': kTaskDoneAwardSource,
          'source_id': id,
          'amount': (storedPayload ?? payload)['completionXp'] as int,
          'awarded_at': completedAt,
        },
      );
    }

    final active = remote._tasks[rowKey]!;
    final receipt = <String, dynamic>{
      ...active,
      'operation_id': operationId,
      'conflict_detected': existing != null,
      'retained_payload': incoming['retained_payload'],
      'retained_updated_at': incoming['retained_updated_at'],
      'retained_deleted_at': incoming['retained_deleted_at'],
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
    final rows = remote.tasksFor(accountId)
      ..sort(
        (left, right) =>
            (left['id'] as String).compareTo(right['id'] as String),
      );
    final page = _page(rows, pageSize, cursor);
    return TaskRemotePage(rows: page.rows, nextCursor: page.nextCursor);
  }

  @override
  Future<TaskAwardRemotePage> fetchTaskAwardPage({
    required int pageSize,
    String? cursor,
  }) async {
    final rows = remote.awardsFor(accountId)
      ..sort(
        (left, right) => (left['source_id'] as String).compareTo(
          right['source_id'] as String,
        ),
      );
    final page = _page(rows, pageSize, cursor);
    return TaskAwardRemotePage(rows: page.rows, nextCursor: page.nextCursor);
  }

  _Page _page(List<Map<String, dynamic>> rows, int size, String? cursor) {
    final start = cursor == null ? 0 : int.parse(cursor);
    final requestedEnd = start + size;
    final end = requestedEnd < rows.length ? requestedEnd : rows.length;
    return _Page(
      rows: rows.sublist(start, end),
      nextCursor: end < rows.length ? '$end' : null,
    );
  }
}

final class _Page {
  const _Page({required this.rows, this.nextCursor});

  final List<Map<String, dynamic>> rows;
  final String? nextCursor;
}
