import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/task_completion_unit_of_work.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_task_link_commands.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/data/tasks_map_link_adapter.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_reconciliation.dart';
import 'package:namma_project/features/tasks/application/task_remote_reader.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/application/task_sync_service.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/mind_maps_test_support.dart';
import '../../../../support/tasks_test_support.dart';

void main() {
  late TemporaryDatabasePath temp;
  late FoundationDatabase db;
  late MindMapsTestSession session;
  late DriftTaskRepository repository;
  late DriftAwardLedger ledger;
  late TasksMapLinkAdapter bridge;
  final taskId = kMindMapsTestTaskId;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 15),
    );
    session = MindMapsTestSession();
    repository = DriftTaskRepository(
      database: db,
      codec: const TaskPayloadCodec(),
    );
    ledger = DriftAwardLedger(db);
    final service = TaskCompletionService(
      repository: repository,
      unitOfWork: DriftTaskCompletionUnitOfWork(
        database: db,
        codec: const TaskPayloadCodec(),
        awardLedger: ledger,
      ),
      session: session,
      nowUtc: () => DateTime.now().toUtc(),
    );
    bridge = TasksMapLinkAdapter(
      repository: repository,
      completionService: service,
      session: session,
    );
    final task = Task.create(
      id: taskId,
      accountId: kMindMapsTestAccountA,
      title: 'Shared task',
      scheduledDate: DateTime(2026, 10, 19),
      createdAt: DateTime.utc(2026, 10, 18),
      completionXp: 30,
    );
    expect(
      (await repository.commitTask(
        TaskWriteRequest(
          task: task,
          operationId: 'create-task',
          kind: ChangeKind.create,
          queuedAt: task.createdAt,
        ),
      )).failureOrNull,
      isNull,
    );
  });

  tearDown(() async {
    await session.dispose();
    await db.close();
    temp.dispose();
  });

  test(
    'preview chooser sees current owner; missing and foreign links reveal no data',
    () async {
      expect(
        (await bridge.ensurePickerReady(kMindMapsTestAccountA)).failureOrNull,
        isNull,
      );
      final tasks = await bridge
          .watchAccessibleTasks(kMindMapsTestAccountA)
          .first;
      expect(tasks.single.title, 'Shared task');
      final missing = (await bridge.readLinkedTask(
        kMindMapsTestAccountA,
        'missing',
      )).valueOrNull!;
      expect(missing.available, isFalse);
      expect(missing.title, isNull);
      session.switchTo(kMindMapsTestAccountB);
      expect(
        (await bridge.readLinkedTask(
          kMindMapsTestAccountA,
          taskId,
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await bridge.readLinkedTask(
          kMindMapsTestAccountB,
          taskId,
        )).valueOrNull!.title,
        isNull,
      );
    },
  );

  test(
    'repeated completion and reopening keep one lifetime XP award',
    () async {
      expect(
        (await bridge.complete(kMindMapsTestAccountA, taskId)).failureOrNull,
        isNull,
      );
      expect(
        (await bridge.complete(kMindMapsTestAccountA, taskId)).failureOrNull,
        isNull,
      );
      expect(
        (await bridge.readLinkedTask(
          kMindMapsTestAccountA,
          taskId,
        )).valueOrNull!.completed,
        isTrue,
      );
      expect(
        (await bridge.reopen(kMindMapsTestAccountA, taskId)).failureOrNull,
        isNull,
      );
      expect(
        (await bridge.complete(kMindMapsTestAccountA, taskId)).failureOrNull,
        isNull,
      );
      final award = (await ledger.readAward(
        accountId: kMindMapsTestAccountA,
        source: kTaskDoneAwardSource,
        sourceId: taskId,
      )).valueOrNull!;
      expect(award.amount, 30);
      expect((await ledger.watchAwards(kMindMapsTestAccountA).first).length, 1);
    },
  );

  test('link validates Task access; unlink never mutates the Task', () async {
    final maps = DriftMapRepository(
      database: db,
      codec: const MapPayloadCodec(),
    );
    final ids = MindMapsTestIds();
    final clock = MindMapsTestClock();
    final map = (await MapCommands(
      repository: maps,
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    ).createMap(title: 'Links')).valueOrNull!;
    final node =
        (await MapGraphCommands(
              repository: maps,
              session: session,
              nextId: ids.nextOperationId,
              nowUtc: clock.nextVersion,
            ).addNode(
              mapId: map.id,
              kind: MindMapNodeKind.task,
              title: 'Task idea',
            ))
            .valueOrNull!
            .nodes
            .single
            .after;
    final commands = MapTaskLinkCommands(
      repository: maps,
      tasks: bridge,
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    );
    expect(
      (await commands.setLink(
        ownerId: kMindMapsTestAccountA,
        mapId: map.id,
        nodeId: node.id,
        taskId: 'missing',
      )).failureOrNull,
      isNotNull,
    );
    expect(
      (await commands.setLink(
        ownerId: kMindMapsTestAccountA,
        mapId: map.id,
        nodeId: node.id,
        taskId: taskId,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await MapGraphCommands(
            repository: maps,
            session: session,
            nextId: ids.nextOperationId,
            nowUtc: clock.nextVersion,
          ).editNode(mapId: map.id, nodeId: node.id, title: 'Renamed idea'))
          .failureOrNull,
      isNull,
    );
    expect(
      (await maps.readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: map.id,
      )).valueOrNull!.nodes.last.taskId,
      taskId,
    );
    expect(
      (await commands.setLink(
        ownerId: kMindMapsTestAccountA,
        mapId: map.id,
        nodeId: node.id,
        taskId: null,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await maps.readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: map.id,
      )).valueOrNull!.nodes.last.taskId,
      isNull,
    );
    expect(
      (await repository.readTask(
        accountId: kMindMapsTestAccountA,
        taskId: taskId,
      )).valueOrNull!.isCompleted,
      isFalse,
    );
    session.switchTo(kMindMapsTestAccountB);
    expect(
      (await commands.setLink(
        ownerId: kMindMapsTestAccountA,
        mapId: map.id,
        nodeId: node.id,
        taskId: taskId,
      )).failureOrNull,
      isNotNull,
    );
  });

  test('authenticated picker waits for a complete initial Task sync', () async {
    final connectivity = TasksTestConnectivity();
    final sync = TaskSyncService(
      session: session,
      connectivity: connectivity,
      outbound: _NoPendingChanges(),
      remoteReader: _EmptyTasks(),
      reconciler: _NoTaskChanges(),
      awardReader: _EmptyAwards(),
      awardLedger: ledger,
    );
    addTearDown(() async {
      await sync.dispose();
      await connectivity.dispose();
    });
    final authenticated = TasksMapLinkAdapter(
      repository: repository,
      completionService: TaskCompletionService(
        repository: repository,
        unitOfWork: DriftTaskCompletionUnitOfWork(
          database: db,
          codec: const TaskPayloadCodec(),
          awardLedger: ledger,
        ),
        session: session,
      ),
      session: session,
      syncService: sync,
    );
    expect(
      (await authenticated.ensurePickerReady(
        kMindMapsTestAccountA,
      )).failureOrNull,
      isNotNull,
    );
    expect(sync.snapshot.initialSyncComplete, isFalse);
    connectivity.goOnline();
    expect(
      (await authenticated.ensurePickerReady(
        kMindMapsTestAccountA,
      )).failureOrNull,
      isNull,
    );
    expect(sync.snapshot.initialSyncComplete, isTrue);
    session.switchTo(kMindMapsTestAccountB);
    expect(
      (await authenticated.ensurePickerReady(
        kMindMapsTestAccountA,
      )).failureOrNull,
      isNotNull,
    );
    expect(
      (await authenticated.ensurePickerReady(
        kMindMapsTestAccountB,
      )).failureOrNull,
      isNull,
    );
    expect(sync.isReadyForAccount(kMindMapsTestAccountB), isTrue);
    expect(
      await authenticated.watchAccessibleTasks(kMindMapsTestAccountB).first,
      isEmpty,
    );
  });
}

final class _NoPendingChanges implements PendingSynchronizationEngine {
  @override
  Future<AppResult<SyncSummary>> synchronize() async => AppResult.success(
    const SyncSummary(
      acknowledged: 0,
      conflictsRecorded: 0,
      equalTimestampConflicts: 0,
      recoverableFailures: 0,
    ),
  );
}

final class _EmptyTasks implements TaskRemoteReaderPort {
  @override
  Future<AppResult<List<Task>>> readAllTasks(String owner) async =>
      AppResult.success(const []);
}

final class _EmptyAwards implements TaskAwardRemoteReaderPort {
  @override
  Future<AppResult<List<TaskCompletionAward>>> readAllTaskAwards(
    String owner,
  ) async => AppResult.success(const []);
}

final class _NoTaskChanges implements TaskReconciliationPort {
  @override
  Future<AppResult<TaskReconciliationSummary>> reconcile({
    required String accountId,
    required List<Task> remoteTasks,
  }) async => AppResult.success(
    const TaskReconciliationSummary(
      imported: 0,
      conflictsRecorded: 0,
      equalTimestampConflicts: 0,
    ),
  );
}
