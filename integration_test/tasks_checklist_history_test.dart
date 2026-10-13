import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/sync/synchronization_coordinator.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_remote_reader.dart';
import 'package:namma_project/features/tasks/application/task_review_queries.dart';
import 'package:namma_project/features/tasks/application/task_sync_service.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/data/task_reconciler.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/tasks/domain/task_rules.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/tasks_test_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'offline checklist edits survive restart and converge without step XP',
    (tester) async {
      final remote = _SharedRemote();
      final clock = TasksTestClock();
      final firstPath = TemporaryDatabasePath();
      final secondPath = TemporaryDatabasePath();
      addTearDown(firstPath.dispose);
      addTearDown(secondPath.dispose);

      var clientA = await _Client.open(
        path: firstPath.allocate(),
        remote: remote,
        clock: clock,
      );
      addTearDown(() => clientA.dispose());

      final created = (await clientA.commands.createTask(
        CreateTaskInput(
          title: 'Offline checklist',
          scheduledDate: DateTime(2026, 10, 7),
        ),
      )).valueOrNull!;
      clock.advance(const Duration(minutes: 1));
      final first = (await clientA.commands.addChecklistItem(
        taskId: created.id,
        text: 'First step',
      )).valueOrNull!.checklistItems.single;
      clock.advance(const Duration(minutes: 1));
      final second = (await clientA.commands.addChecklistItem(
        taskId: created.id,
        text: 'Second step',
      )).valueOrNull!.checklistItems.last;
      clock.advance(const Duration(minutes: 1));
      await clientA.commands.editChecklistItem(
        taskId: created.id,
        itemId: first.id,
        text: 'Edited first step',
      );
      clock.advance(const Duration(minutes: 1));
      await clientA.commands.setChecklistItemCompleted(
        taskId: created.id,
        itemId: second.id,
        completed: true,
      );
      clock.advance(const Duration(minutes: 1));
      await clientA.commands.removeChecklistItem(
        taskId: created.id,
        itemId: first.id,
      );

      expect(remote.tasksFor(kTasksTestAccountA), isEmpty);
      expect(
        await clientA.awards.watchAwards(kTasksTestAccountA).first,
        isEmpty,
        reason: 'checklist progress has no XP side effect',
      );

      final databasePath = clientA.database.resolvedPath;
      await clientA.dispose();
      clientA = await _Client.open(
        path: databasePath,
        remote: remote,
        clock: clock,
      );
      final restored = (await clientA.tasks.readTask(
        accountId: kTasksTestAccountA,
        taskId: created.id,
      )).valueOrNull!;
      expect(restored.checklistItems, hasLength(1));
      expect(restored.checklistItems.single.id, second.id);
      expect(restored.checklistItems.single.completed, isTrue);
      expect(restored.isCompleted, isFalse);

      clientA.connectivity.goOnline();
      expect((await clientA.sync.synchronize()).failureOrNull, isNull);
      expect(remote.tasksFor(kTasksTestAccountA), hasLength(1));

      final clientB = await _Client.open(
        path: secondPath.allocate(),
        remote: remote,
        clock: clock,
      );
      addTearDown(clientB.dispose);
      clientB.connectivity.goOnline();
      expect((await clientB.sync.synchronize()).failureOrNull, isNull);

      final onA = (await clientA.tasks.readTask(
        accountId: kTasksTestAccountA,
        taskId: created.id,
      )).valueOrNull!;
      final onB = (await clientB.tasks.readTask(
        accountId: kTasksTestAccountA,
        taskId: created.id,
      )).valueOrNull!;
      expect(onB, onA);

      for (final snapshot in <List<Task>>[
        await clientA.tasks.watchTasks(kTasksTestAccountA).first,
        await clientB.tasks.watchTasks(kTasksTestAccountA).first,
      ]) {
        expect(TaskRules.all(snapshot).map((task) => task.id), <String>[
          created.id,
        ]);
        expect(
          TaskRules.matrix(
            snapshot,
          ).values.expand((tasks) => tasks).map((task) => task.id),
          <String>[created.id],
        );
        expect(
          TaskReviewQueries.overdue(
            snapshot,
            localDate: clock.localDate(),
            nowUtc: clock.utcNow(),
          ).map((Task task) => task.id),
          <String>[created.id],
        );
        expect(TaskReviewQueries.completedHistory(snapshot), isEmpty);
      }

      expect(
        await clientA.awards.watchAwards(kTasksTestAccountA).first,
        isEmpty,
      );
      expect(
        await clientB.awards.watchAwards(kTasksTestAccountA).first,
        isEmpty,
      );
    },
  );
}

final class _Client {
  _Client._({
    required this.database,
    required this.tasks,
    required this.awards,
    required this.commands,
    required this.connectivity,
    required this.sync,
  });

  static final List<int> _key = List<int>.generate(32, (index) => 0x51 + index);

  final FoundationDatabase database;
  final DriftTaskRepository tasks;
  final DriftAwardLedger awards;
  final TaskCommands commands;
  final TasksTestConnectivity connectivity;
  final TaskSyncService sync;
  bool _disposed = false;

  static Future<_Client> open({
    required String path,
    required _SharedRemote remote,
    required TasksTestClock clock,
  }) async {
    const codec = TaskPayloadCodec();
    final database = await FoundationDatabase.openEncrypted(
      path: path,
      key: _key,
    );
    final tasks = DriftTaskRepository(database: database, codec: codec);
    final awards = DriftAwardLedger(database);
    const session = _Session();
    final connectivity = TasksTestConnectivity();
    final localStore = DriftLocalStore(database);
    final outbound = SynchronizationCoordinator(
      localStore: localStore,
      cloudSession: session,
      cloudSync: remote,
      now: clock.utcNow,
    );
    final reconciler = TaskReconciler(
      repository: tasks,
      localStore: localStore,
      codec: codec,
      detectedAt: clock.utcNow,
    );
    final sync = TaskSyncService(
      session: session,
      connectivity: connectivity,
      outbound: outbound,
      remoteReader: remote,
      reconciler: reconciler,
      awardReader: remote,
      awardLedger: awards,
    );
    final ids = TasksTestIds();
    var checklistId = 0;
    final commands = TaskCommands(
      repository: tasks,
      session: session,
      nowUtc: clock.utcNow,
      localDate: clock.localDate,
      nextTaskId: ids.nextTaskId,
      nextOperationId: ids.nextOperationId,
      nextChecklistItemId: () => 'integration-step-${++checklistId}',
    );
    return _Client._(
      database: database,
      tasks: tasks,
      awards: awards,
      commands: commands,
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
  const _Session();

  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.success(
        const CloudSyncContext(accountId: kTasksTestAccountA),
      );

  @override
  Stream<CloudSessionSnapshot> observeSession() =>
      Stream<CloudSessionSnapshot>.value(
        const CloudSessionSnapshot(
          status: CloudSessionStatus.signedIn,
          accountId: kTasksTestAccountA,
        ),
      );
}

final class _SharedRemote
    implements CloudSyncPort, TaskRemoteReaderPort, TaskAwardRemoteReaderPort {
  _SharedRemote() : _codec = const TaskPayloadCodec();

  final TaskPayloadCodec _codec;
  final Map<String, Task> _tasks = <String, Task>{};
  final Set<String> _receipts = <String>{};

  List<Task> tasksFor(String accountId) => _tasks.values
      .where((task) => task.accountId == accountId)
      .toList(growable: false);

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    final receipt = '${change.accountId}/${change.operationId}';
    if (!_receipts.add(receipt)) {
      return AppResult<DispatchOutcome>.success(
        DispatchAcknowledged(acknowledgementId: receipt),
      );
    }
    final task = _codec.decode(change.payload);
    if (task.accountId != change.accountId || task.id != change.entityId) {
      throw StateError('Task ownership or identity mismatch');
    }
    _tasks['${task.accountId}/${task.id}'] = task;
    return AppResult<DispatchOutcome>.success(
      DispatchAcknowledged(
        acknowledgementId: receipt,
        remoteVersionTimestamp: task.updatedAt,
      ),
    );
  }

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async {
    final task = _tasks['$kTasksTestAccountA/$entityId'];
    return AppResult<RemoteVersion?>.success(
      task == null
          ? null
          : RemoteVersion(
              entityType: entityType,
              entityId: entityId,
              versionTimestamp: task.updatedAt,
              payload: _codec.encode(task),
            ),
    );
  }

  @override
  Future<AppResult<List<Task>>> readAllTasks(String accountId) async =>
      AppResult<List<Task>>.success(tasksFor(accountId));

  @override
  Future<AppResult<List<TaskCompletionAward>>> readAllTaskAwards(
    String accountId,
  ) async => AppResult<List<TaskCompletionAward>>.success(
    const <TaskCompletionAward>[],
  );
}
