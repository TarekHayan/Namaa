import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/mind_maps_strings_adapter.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/application/map_editor_history.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/application/map_task_link_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_task_link_port.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';
import 'package:namma_project/features/mind_maps/presentation/map_editor_cubit.dart';
import 'package:namma_project/features/mind_maps/presentation/map_editor_screen.dart';
import 'package:namma_project/features/mind_maps/presentation/map_editor_state.dart';
import 'package:namma_project/features/mind_maps/presentation/map_task_picker.dart';

import '../../../support/mind_maps_test_support.dart';

void main() {
  testWidgets('accessible chooser shows only Task projections and returns ID', (
    tester,
  ) async {
    final port = _Tasks();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                port.chosen = await showMapTaskPicker(
                  context: context,
                  tasks: port,
                  ownerId: 'owner',
                  strings: resolveMindMapsStrings(context),
                );
              },
              child: const Text('Open chooser'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open chooser'));
    await tester.pumpAndSettle();
    expect(find.byKey(kMindMapTaskPickerKey), findsOneWidget);
    expect(find.text('Write proposal'), findsOneWidget);
    expect(find.text('Foreign title'), findsNothing);
    await tester.tap(find.text('Write proposal'));
    await tester.pumpAndSettle();
    expect(port.chosen, 'task');
  });

  testWidgets('editor links, completes, reopens, repairs and unlinks', (
    tester,
  ) async {
    final at = DateTime.utc(2026, 10, 19);
    final session = MindMapsTestSession();
    final repo = _GraphStore(
      MapGraph(
        map: MindMap(
          ownerId: kMindMapsTestAccountA,
          id: 'map',
          title: 'Plan',
          centralNodeId: 'center',
          revisionId: 'v',
          createdAt: at,
          updatedAt: at,
        ),
        nodes: [
          MindMapNode(
            ownerId: kMindMapsTestAccountA,
            mapId: 'map',
            id: 'center',
            kind: MindMapNodeKind.central,
            title: 'Plan',
            x: 0,
            y: 0,
            revisionId: 'v',
            createdAt: at,
            updatedAt: at,
          ),
          MindMapNode(
            ownerId: kMindMapsTestAccountA,
            mapId: 'map',
            id: 'idea',
            kind: MindMapNodeKind.task,
            title: 'Idea',
            x: 10,
            y: 10,
            revisionId: 'v',
            createdAt: at,
            updatedAt: at,
          ),
        ],
        parentSlots: const [],
        sideLinks: const [],
      ),
    );
    final tasks = _LiveTasks();
    final cubit = MapEditorCubit(
      repository: repo,
      commands: MapGraphCommands(repository: repo, session: session),
      history: MapEditorHistory(
        repository: repo,
        session: session,
        ownerId: kMindMapsTestAccountA,
        mapId: 'map',
      ),
      tasks: tasks,
      taskLinks: MapTaskLinkCommands(
        repository: repo,
        tasks: tasks,
        session: session,
      ),
      ownerId: kMindMapsTestAccountA,
      mapId: 'map',
    );
    addTearDown(() async {
      await session.dispose();
      await repo.close();
      await tasks.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: MapEditorScreen(
          cubit: cubit,
          stringsResolver: resolveMindMapsStrings,
        ),
      ),
    );
    await tester.pumpAndSettle();
    cubit.select('idea');
    await tester.pumpAndSettle();
    expect(cubit.state, isA<MapEditorReady>());
    expect(find.byKey(kMindMapEditorKey), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(kMindMapLinkTaskKey),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(kMindMapLinkTaskKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byKey(kMindMapTaskPickerKey), findsOneWidget);
    expect(find.text('Write proposal'), findsOneWidget);
    await tester.tap(find.text('Write proposal'));
    await tester.pumpAndSettle();
    expect((cubit.state as MapEditorReady).graph.nodes.last.taskId, 'task');
    await tester.scrollUntilVisible(
      find.byKey(kMindMapCompleteTaskKey),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(kMindMapCompleteTaskKey));
    await tester.pumpAndSettle();
    expect((cubit.state as MapEditorReady).summary.completedCount, 1);
    await tester.ensureVisible(find.byKey(kMindMapCompleteTaskKey));
    await tester.tap(find.byKey(kMindMapCompleteTaskKey));
    await tester.pumpAndSettle();
    expect((cubit.state as MapEditorReady).summary.completedCount, 0);
    tasks.unavailable = true;
    tasks.publish();
    await tester.pump();
    await tester.pump();
    expect((cubit.state as MapEditorReady).linkedTasks['task']!.available, false);
    await tester.scrollUntilVisible(
      find.text('Linked task unavailable').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Linked task unavailable'), findsOneWidget);
    expect(find.text('Write proposal'), findsNothing);
    await tester.ensureVisible(find.byKey(kMindMapLinkTaskKey));
    await tester.tap(find.byKey(kMindMapLinkTaskKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.tap(find.text('Other task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect((cubit.state as MapEditorReady).graph.nodes.last.taskId, 'other');
    await tester.ensureVisible(find.text('Unlink task'));
    await tester.tap(find.text('Unlink task'));
    await tester.pump();
    expect((cubit.state as MapEditorReady).graph.nodes.last.taskId, isNull);
    expect(tasks.completes, 1);
    expect(tasks.reopens, 1);
  });
}

final class _GraphStore implements MapRepository {
  _GraphStore(this.graph);
  MapGraph graph;
  final changes = StreamController<MapGraph>.broadcast(sync: true);
  @override
  Future<AppResult<MapGraph?>> readGraph({
    required String ownerId,
    required String mapId,
  }) async => AppResult.success(
    graph.map.ownerId == ownerId && graph.map.id == mapId ? graph : null,
  );
  @override
  Stream<MapGraph?> watchGraph({
    required String ownerId,
    required String mapId,
  }) => Stream.multi((controller) {
    final sub = changes.stream.listen(controller.add);
    controller.add(graph);
    controller.onCancel = sub.cancel;
  });
  @override
  Stream<List<MapGraph>> watchGraphs(String ownerId) => watchGraph(
    ownerId: ownerId,
    mapId: graph.map.id,
  ).map((value) => value == null ? [] : [value]);
  @override
  Future<AppResult<void>> commit(MapWriteBatch batch) async {
    if (!await batch.verifyOwner()) throw StateError('owner changed');
    final nodes = {for (final node in graph.nodes) node.id: node};
    for (final change in batch.nodes) {
      nodes[change.value.id] = change.value;
    }
    graph = MapGraph(
      map: graph.map,
      nodes: nodes.values,
      parentSlots: graph.parentSlots,
      sideLinks: graph.sideLinks,
    );
    changes.add(graph);
    return AppResult.success(null);
  }

  Future<void> close() => changes.close();
}

final class _LiveTasks implements MapTaskLinkPort {
  final changes = StreamController<List<MapLinkedTask>>.broadcast(sync: true);
  bool completed = false;
  bool unavailable = false;
  int completes = 0;
  int reopens = 0;
  MapLinkedTask get task => unavailable
      ? const MapLinkedTask.unavailable('task')
      : MapLinkedTask.available(
          id: 'task',
          title: 'Write proposal',
          completed: completed,
          completionChangedAt: DateTime.utc(2026),
        );
  MapLinkedTask get other => MapLinkedTask.available(
    id: 'other',
    title: 'Other task',
    completed: false,
    completionChangedAt: DateTime.utc(2026),
  );
  void publish() => changes.add([task, other]);
  @override
  Future<AppResult<void>> ensurePickerReady(String owner) async =>
      AppResult.success(null);
  @override
  Stream<List<MapLinkedTask>> watchAccessibleTasks(String owner) {
    late StreamController<List<MapLinkedTask>> controller;
    StreamSubscription<List<MapLinkedTask>>? subscription;
    controller = StreamController<List<MapLinkedTask>>(
      onListen: () {
        subscription = changes.stream.listen(controller.add);
        controller.add([task, other]);
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }
  @override
  Future<AppResult<MapLinkedTask>> readLinkedTask(
    String owner,
    String id,
  ) async => AppResult.success(id == 'task' ? task : other);
  @override
  Future<AppResult<void>> complete(String owner, String id) async {
    completed = true;
    completes++;
    publish();
    return AppResult.success(null);
  }

  @override
  Future<AppResult<void>> reopen(String owner, String id) async {
    completed = false;
    reopens++;
    publish();
    return AppResult.success(null);
  }

  Future<void> close() => changes.close();
}

final class _Tasks implements MapTaskLinkPort {
  String? chosen;
  @override
  Future<AppResult<void>> ensurePickerReady(String owner) async =>
      AppResult.success(null);
  @override
  Stream<List<MapLinkedTask>> watchAccessibleTasks(String owner) =>
      Stream.value([
        MapLinkedTask.available(
          id: 'task',
          title: 'Write proposal',
          completed: false,
          completionChangedAt: DateTime.utc(2026),
        ),
        const MapLinkedTask.unavailable('foreign'),
      ]);
  @override
  Future<AppResult<MapLinkedTask>> readLinkedTask(
    String owner,
    String id,
  ) async => AppResult.success(const MapLinkedTask.unavailable('foreign'));
  @override
  Future<AppResult<void>> complete(String owner, String id) async =>
      AppResult.success(null);
  @override
  Future<AppResult<void>> reopen(String owner, String id) async =>
      AppResult.success(null);
}
