import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/task_completion_unit_of_work.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_queries.dart';
import 'package:namma_project/features/mind_maps/application/map_task_link_commands.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/data/tasks_map_link_adapter.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/today/data/tasks_today_adapter.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/mind_maps_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'two preview maps share one Task and one XP award after restart',
    (tester) async {
      final temp = TemporaryDatabasePath();
      final path = temp.allocate();
      final key = List<int>.generate(32, (i) => i + 47);
      var db = await FoundationDatabase.openEncrypted(path: path, key: key);
      const session = TasksPreviewSession();
      final ids = MindMapsTestIds();
      final clock = MindMapsTestClock();
      DriftMapRepository maps() =>
          DriftMapRepository(database: db, codec: const MapPayloadCodec());
      DriftTaskRepository tasks() =>
          DriftTaskRepository(database: db, codec: const TaskPayloadCodec());
      final task = Task.create(
        id: kMindMapsTestTaskId,
        accountId: kTasksPreviewAccountId,
        title: 'One shared task',
        scheduledDate: DateTime(2026, 10, 19),
        createdAt: DateTime.utc(2026, 10, 18),
        completionXp: 25,
      );
      expect(
        (await tasks().commitTask(
          TaskWriteRequest(
            task: task,
            operationId: 'create-task',
            kind: ChangeKind.create,
            queuedAt: task.createdAt,
          ),
        )).failureOrNull,
        isNull,
      );
      final mapCommands = MapCommands(
        repository: maps(),
        session: session,
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      );
      final first = (await mapCommands.createMap(title: 'First')).valueOrNull!;
      final second = (await mapCommands.createMap(
        title: 'Second',
      )).valueOrNull!;
      final graphCommands = MapGraphCommands(
        repository: maps(),
        session: session,
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      );
      final firstNode = (await graphCommands.addNode(
        mapId: first.id,
        kind: MindMapNodeKind.task,
        title: 'First reference',
      )).valueOrNull!.nodes.single.after.id;
      final secondNode = (await graphCommands.addNode(
        mapId: second.id,
        kind: MindMapNodeKind.task,
        title: 'Second reference',
      )).valueOrNull!.nodes.single.after.id;
      TaskCompletionService taskService() => TaskCompletionService(
        repository: tasks(),
        unitOfWork: DriftTaskCompletionUnitOfWork(
          database: db,
          codec: const TaskPayloadCodec(),
          awardLedger: DriftAwardLedger(db),
        ),
        session: session,
        currentLocalDate: () => DateTime(2026, 10, 19),
      );
      TasksMapLinkAdapter bridge() => TasksMapLinkAdapter(
        repository: tasks(),
        completionService: taskService(),
        session: session,
      );
      final links = MapTaskLinkCommands(
        repository: maps(),
        tasks: bridge(),
        session: session,
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      );
      expect(
        (await links.setLink(
          ownerId: kTasksPreviewAccountId,
          mapId: first.id,
          nodeId: firstNode,
          taskId: task.id,
        )).failureOrNull,
        isNull,
      );
      expect(
        (await links.setLink(
          ownerId: kTasksPreviewAccountId,
          mapId: second.id,
          nodeId: secondNode,
          taskId: task.id,
        )).failureOrNull,
        isNull,
      );
      Future<void> verifyLinkedViews(bool completed) async {
        final projection = (await bridge().readLinkedTask(
          kTasksPreviewAccountId,
          task.id,
        )).valueOrNull!;
        expect(projection.completed, completed);
        for (final mapId in [first.id, second.id]) {
          final graph = (await maps().readGraph(
            ownerId: kTasksPreviewAccountId,
            mapId: mapId,
          )).valueOrNull!;
          expect(
            MapQueries.summary(
              graph,
              tasks: {task.id: projection},
            ).completedCount,
            completed ? 1 : 0,
          );
        }
        final awards = await DriftAwardLedger(
          db,
        ).watchAwards(kTasksPreviewAccountId).first;
        expect(awards, hasLength(1));
      }

      // Ten alternating map/Tasks completion and reopening journeys. Both
      // linked maps must agree after every transition, with one lifetime XP.
      for (var scenario = 0; scenario < 10; scenario++) {
        final fromMap = scenario.isEven;
        final completed = fromMap
            ? await bridge().complete(kTasksPreviewAccountId, task.id)
            : await taskService().completeTask(
                task.id,
                expectedAccountId: kTasksPreviewAccountId,
              );
        expect(completed.failureOrNull, isNull, reason: 'scenario $scenario');
        await verifyLinkedViews(true);
        final reopened = fromMap
            ? await taskService().reopenTask(
                task.id,
                expectedAccountId: kTasksPreviewAccountId,
              )
            : await bridge().reopen(kTasksPreviewAccountId, task.id);
        expect(reopened.failureOrNull, isNull, reason: 'scenario $scenario');
        await verifyLinkedViews(false);
      }
      // Today invokes the same owner command. Both linked maps still observe
      // the one Task, with the lifetime award unchanged.
      final today = TasksTodayAdapter(
        tasks(),
        completionService: taskService(),
      );
      expect(
        (await today.setCompleted(
          ownerId: kTasksPreviewAccountId,
          taskId: task.id,
          expectedLocalDate: TodayLocalDate(2026, 10, 19),
          completed: true,
        )).failureOrNull,
        isNull,
      );
      await verifyLinkedViews(true);
      expect(
        (await today.setCompleted(
          ownerId: kTasksPreviewAccountId,
          taskId: task.id,
          expectedLocalDate: TodayLocalDate(2026, 10, 19),
          completed: false,
        )).failureOrNull,
        isNull,
      );
      await verifyLinkedViews(false);
      expect(
        (await bridge().complete(
          kTasksPreviewAccountId,
          task.id,
        )).failureOrNull,
        isNull,
      );
      await db.close();
      db = await FoundationDatabase.openEncrypted(path: path, key: key);
      addTearDown(() async {
        await db.close();
        temp.dispose();
      });
      final projection = (await bridge().readLinkedTask(
        kTasksPreviewAccountId,
        task.id,
      )).valueOrNull!;
      expect(projection.completed, isTrue);
      for (final mapId in [first.id, second.id]) {
        final graph = (await maps().readGraph(
          ownerId: kTasksPreviewAccountId,
          mapId: mapId,
        )).valueOrNull!;
        expect(
          MapQueries.summary(
            graph,
            tasks: {task.id: projection},
          ).completedCount,
          1,
        );
      }
      final awards = await DriftAwardLedger(
        db,
      ).watchAwards(kTasksPreviewAccountId).first;
      expect(awards, hasLength(1));
      expect(awards.single.source, kTaskDoneAwardSource);
      expect(awards.single.amount, 25);
    },
  );
}
