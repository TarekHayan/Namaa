import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_editor_history.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/mind_maps_test_support.dart';

void main() {
  late TemporaryDatabasePath temp;
  late FoundationDatabase db;
  late MindMapsTestSession session;
  late DriftMapRepository repo;
  late MapGraphCommands commands;
  late MapEditorHistory history;
  late String mapId;
  late MindMapsTestIds ids;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 30),
    );
    session = MindMapsTestSession();
    ids = MindMapsTestIds();
    final clock = MindMapsTestClock();
    repo = DriftMapRepository(database: db, codec: const MapPayloadCodec());
    final maps = MapCommands(
      repository: repo,
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    );
    mapId = (await maps.createMap(title: 'Ideas')).valueOrNull!.id;
    commands = MapGraphCommands(
      repository: repo,
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    );
    history = MapEditorHistory(
      repository: repo,
      session: session,
      ownerId: kMindMapsTestAccountA,
      mapId: mapId,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    );
  });
  tearDown(() async {
    await session.dispose();
    await db.close();
    temp.dispose();
  });

  test(
    'undo/redo node, relation, position and settings without Task/XP writes',
    () async {
      final center = (await repo.readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: mapId,
      )).valueOrNull!.map.centralNodeId;
      final added = (await commands.addNode(
        mapId: mapId,
        kind: MindMapNodeKind.branch,
        title: 'A',
        parentId: center,
      )).valueOrNull!;
      history.record(added);
      final nodeId = added.nodes.single.after.id;
      final moved = (await commands.editNode(
        mapId: mapId,
        nodeId: nodeId,
        x: 25,
        status: MindMapNodeStatus.completed,
      )).valueOrNull!;
      history.record(moved);
      final settings = (await commands.updateSettings(
        mapId: mapId,
        settings: const MindMapSettings(spacing: 180),
      )).valueOrNull!;
      history.record(settings);
      expect((await history.undo()).failureOrNull, isNull);
      expect((await history.undo()).failureOrNull, isNull);
      var graph = (await repo.readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: mapId,
      )).valueOrNull!;
      expect(graph.map.settings.spacing, 120);
      expect(graph.nodes.singleWhere((n) => n.id == nodeId).x, 0);
      expect((await history.undo()).failureOrNull, isNull);
      graph = (await repo.readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: mapId,
      )).valueOrNull!;
      expect(graph.nodes.any((n) => n.id == nodeId), false);
      expect(graph.parentSlots, isEmpty);
      expect((await history.redo()).failureOrNull, isNull);
      expect((await history.redo()).failureOrNull, isNull);
      expect((await history.redo()).failureOrNull, isNull);
      graph = (await repo.readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: mapId,
      )).valueOrNull!;
      expect(graph.nodes.singleWhere((n) => n.id == nodeId).x, 25);
      expect(graph.map.settings.spacing, 180);
      expect(await db.rawScalar('SELECT count(*) FROM task_records'), 0);
      expect(await db.rawScalar('SELECT count(*) FROM xp_awards'), 0);
      expect(
        await db.rawScalar(
          "SELECT count(*) FROM pending_changes WHERE entity_type NOT LIKE 'mind_map%'",
        ),
        0,
      );
    },
  );

  test(
    'external same-node edit rejects undo and leaves confirmed state',
    () async {
      final added = (await commands.addNode(
        mapId: mapId,
        kind: MindMapNodeKind.note,
        title: 'A',
      )).valueOrNull!;
      history.record(added);
      final id = added.nodes.single.after.id;
      expect(
        (await commands.editNode(
          mapId: mapId,
          nodeId: id,
          title: 'External',
        )).failureOrNull,
        isNull,
      );
      expect((await history.undo()).failureOrNull, isNotNull);
      expect(history.canUndo, true);
      expect(
        (await repo.readGraph(
          ownerId: kMindMapsTestAccountA,
          mapId: mapId,
        )).valueOrNull!.nodes.singleWhere((n) => n.id == id).title,
        'External',
      );
    },
  );
}
