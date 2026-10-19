import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/mind_maps_test_support.dart';

void main() {
  late TemporaryDatabasePath temp;
  late FoundationDatabase db;
  late MindMapsTestSession session;
  late DriftMapRepository repo;
  late MindMapsTestIds ids;
  late MindMapsTestClock clock;
  late MapCommands maps;
  late MapGraphCommands commands;
  late String mapId;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (i) => i + 50),
    );
    session = MindMapsTestSession();
    ids = MindMapsTestIds();
    clock = MindMapsTestClock();
    repo = DriftMapRepository(database: db, codec: const MapPayloadCodec());
    maps = MapCommands(
      repository: repo,
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    );
    commands = MapGraphCommands(
      repository: repo,
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    );
    mapId = (await maps.createMap(title: 'Map')).valueOrNull!.id;
  });
  tearDown(() async {
    await session.dispose();
    await db.close();
    temp.dispose();
  });

  test('add, edit, reparent, detach and delete retain descendants', () async {
    final center = (await repo.readGraph(
      ownerId: kMindMapsTestAccountA,
      mapId: mapId,
    )).valueOrNull!.map.centralNodeId;
    final a = (await commands.addNode(
      mapId: mapId,
      kind: MindMapNodeKind.mainIdea,
      title: 'A',
      parentId: center,
    )).valueOrNull!.nodes.single.after.id;
    final b = (await commands.addNode(
      mapId: mapId,
      kind: MindMapNodeKind.branch,
      title: 'B',
      parentId: a,
    )).valueOrNull!.nodes.single.after.id;
    final c = (await commands.addNode(
      mapId: mapId,
      kind: MindMapNodeKind.note,
      title: 'C',
      parentId: b,
    )).valueOrNull!.nodes.single.after.id;
    expect(
      (await commands.setParent(
        mapId: mapId,
        childId: a,
        parentId: c,
      )).failureOrNull,
      isNotNull,
    );
    expect(
      (await commands.setSideLink(
        mapId: mapId,
        firstId: a,
        secondId: b,
        connected: true,
      )).failureOrNull,
      isNotNull,
    );
    expect(
      (await commands.editNode(
        mapId: mapId,
        nodeId: b,
        title: '  ',
        x: 12,
      )).failureOrNull,
      isNotNull,
    );
    expect(
      (await commands.editNode(
        mapId: mapId,
        nodeId: b,
        title: 'Moved',
        x: 12,
        y: 13,
        status: MindMapNodeStatus.completed,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await commands.deleteNode(
        mapId: mapId,
        nodeId: b,
        confirmed: true,
      )).failureOrNull,
      isNull,
    );
    final graph = (await repo.readGraph(
      ownerId: kMindMapsTestAccountA,
      mapId: mapId,
    )).valueOrNull!;
    expect(graph.nodes.map((n) => n.id), containsAll([center, a, c]));
    expect(graph.nodes.any((n) => n.id == b), false);
    expect(graph.parentSlots.any((s) => s.childNodeId == c), false);
    expect(
      (await commands.setParent(
        mapId: mapId,
        childId: c,
        parentId: a,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await repo.readGraph(ownerId: kMindMapsTestAccountA, mapId: mapId))
          .valueOrNull!
          .parentSlots
          .singleWhere((s) => s.childNodeId == c)
          .parentNodeId,
      a,
    );
  });

  test('side link is one pair and owner switch rejects edits', () async {
    final a = (await commands.addNode(
      mapId: mapId,
      kind: MindMapNodeKind.note,
      title: 'A',
    )).valueOrNull!.nodes.single.after.id;
    final b = (await commands.addNode(
      mapId: mapId,
      kind: MindMapNodeKind.note,
      title: 'B',
    )).valueOrNull!.nodes.single.after.id;
    expect(
      (await commands.setSideLink(
        mapId: mapId,
        firstId: a,
        secondId: b,
        connected: true,
      )).failureOrNull,
      isNull,
    );
    expect(
      (await commands.setSideLink(
        mapId: mapId,
        firstId: b,
        secondId: a,
        connected: true,
      )).failureOrNull,
      isNotNull,
    );
    expect(
      (await commands.setSideLink(
        mapId: mapId,
        firstId: b,
        secondId: a,
        connected: false,
      )).failureOrNull,
      isNull,
    );
    session.switchTo(kMindMapsTestAccountB);
    expect(
      (await commands.editNode(
        mapId: mapId,
        nodeId: a,
        title: 'Intrusion',
        expectedOwnerId: kMindMapsTestAccountA,
      )).failureOrNull,
      isNotNull,
    );
  });

  test(
    'central deletion and failed graph save leave confirmed state unchanged',
    () async {
      final center = (await repo.readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: mapId,
      )).valueOrNull!.map.centralNodeId;
      expect(
        (await commands.deleteNode(
          mapId: mapId,
          nodeId: center,
          confirmed: true,
        )).failureOrNull,
        isNotNull,
      );
      final failingRepo = DriftMapRepository(
        database: db,
        codec: const MapPayloadCodec(),
        beforeOutboxWrite: () async => throw StateError('test rollback'),
      );
      final failingCommands = MapGraphCommands(
        repository: failingRepo,
        session: session,
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      );
      expect(
        (await failingCommands.addNode(
          mapId: mapId,
          kind: MindMapNodeKind.note,
          title: 'Unsaved',
        )).failureOrNull,
        isNotNull,
      );
      final graph = (await repo.readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: mapId,
      )).valueOrNull!;
      expect(graph.nodes.single.id, center);
      expect(graph.parentSlots, isEmpty);
    },
  );
}
