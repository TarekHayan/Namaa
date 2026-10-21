import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/mind_maps_strings_adapter.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_editor_history.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_queries.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';
import 'package:namma_project/features/mind_maps/presentation/map_canvas.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/mind_maps_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline graph edits, detach, delete and undo survive restart', (
    tester,
  ) async {
    final temp = TemporaryDatabasePath();
    final path = temp.allocate();
    final key = List<int>.generate(32, (i) => 0xa0 + i);
    var db = await FoundationDatabase.openEncrypted(path: path, key: key);
    DriftMapRepository store() =>
        DriftMapRepository(database: db, codec: const MapPayloadCodec());
    var repo = store();
    final ids = MindMapsTestIds();
    final clock = MindMapsTestClock();
    const session = TasksPreviewSession();
    final map = (await MapCommands(
      repository: repo,
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    ).createMap(title: 'Project')).valueOrNull!;
    final commands = MapGraphCommands(
      repository: repo,
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    );
    final history = MapEditorHistory(
      repository: repo,
      session: session,
      ownerId: kTasksPreviewAccountId,
      mapId: map.id,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    );
    addTearDown(() async {
      await db.close();
      temp.dispose();
    });
    Future<String> add(
      String title,
      MindMapNodeKind kind, [
      String? parent,
    ]) async => (await commands.addNode(
      mapId: map.id,
      kind: kind,
      title: title,
      parentId: parent,
    )).valueOrNull!.nodes.single.after.id;
    final a = await add('A', MindMapNodeKind.mainIdea, map.centralNodeId);
    final b = await add('B', MindMapNodeKind.branch, a);
    final c = await add('C', MindMapNodeKind.note, b);
    final d = await add('D', MindMapNodeKind.mainIdea, map.centralNodeId);
    final e = await add('E', MindMapNodeKind.branch, a);
    expect(
      (await commands.setParent(
        mapId: map.id,
        childId: e,
        parentId: b,
      )).failureOrNull,
      isNull,
    );
    history.record(
      (await commands.setParent(
        mapId: map.id,
        childId: b,
        parentId: d,
      )).valueOrNull!,
    );
    expect(
      (await commands.setParent(
        mapId: map.id,
        childId: d,
        parentId: c,
      )).failureOrNull,
      isNotNull,
    );
    history.record(
      (await commands.setParent(
        mapId: map.id,
        childId: b,
        parentId: null,
      )).valueOrNull!,
    );
    expect((await history.undo()).failureOrNull, isNull);
    expect((await history.redo()).failureOrNull, isNull);
    expect((await history.undo()).failureOrNull, isNull);
    history.record(
      (await commands.setSideLink(
        mapId: map.id,
        firstId: a,
        secondId: c,
        connected: true,
      )).valueOrNull!,
    );
    history.record(
      (await commands.editNode(
        mapId: map.id,
        nodeId: c,
        x: 230,
        y: -40,
        status: MindMapNodeStatus.completed,
      )).valueOrNull!,
    );
    expect(
      (await commands.editNode(
        mapId: map.id,
        nodeId: a,
        status: MindMapNodeStatus.inProgress,
      )).failureOrNull,
      isNull,
    );
    history.record(
      (await commands.deleteNode(
        mapId: map.id,
        nodeId: d,
        confirmed: true,
      )).valueOrNull!,
    );
    expect((await history.undo()).failureOrNull, isNull);
    expect((await history.redo()).failureOrNull, isNull);
    await db.close();
    db = await FoundationDatabase.openEncrypted(path: path, key: key);
    repo = store();
    final graph = (await repo.readGraph(
      ownerId: kTasksPreviewAccountId,
      mapId: map.id,
    )).valueOrNull!;
    expect(
      graph.nodes.map((node) => node.id),
      containsAll([map.centralNodeId, a, b, c, e]),
    );
    expect(graph.nodes.any((node) => node.id == d), false);
    expect(graph.parentSlots.any((slot) => slot.childNodeId == b), false);
    expect(
      graph.parentSlots
          .singleWhere((slot) => slot.childNodeId == c)
          .parentNodeId,
      b,
    );
    expect(
      graph.parentSlots
          .singleWhere((slot) => slot.childNodeId == e)
          .parentNodeId,
      b,
    );
    expect(graph.sideLinks.single.id, MindMapsTestIds.sideLinkId(a, c));
    final note = graph.nodes.singleWhere((node) => node.id == c);
    expect(
      (note.x, note.y, note.status),
      (230, -40, MindMapNodeStatus.completed),
    );
    expect(
      graph.nodes.singleWhere((node) => node.id == a).status,
      MindMapNodeStatus.inProgress,
    );
    expect(
      graph.nodes.singleWhere((node) => node.id == b).status,
      MindMapNodeStatus.notStarted,
    );
    expect(MapQueries.summary(graph).progressPercent, 20);
    expect(await db.rawScalar('SELECT count(*) FROM task_records'), 0);
    expect(await db.rawScalar('SELECT count(*) FROM xp_awards'), 0);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => MapCanvas(
              graph: graph,
              selectedId: map.centralNodeId,
              onSelect: (_) {},
              onMove: (_, _, _) async => false,
              strings: resolveMindMapsStrings(context),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(kMindMapCanvasKey), findsOneWidget);
    for (final id in [a, b, c, e]) {
      expect(find.byKey(ValueKey('mind-map-canvas-node-$id')), findsOneWidget);
    }
    expect(find.byKey(ValueKey('mind-map-canvas-node-$d')), findsNothing);
    expect(find.text('C'), findsOneWidget);
  });
}
