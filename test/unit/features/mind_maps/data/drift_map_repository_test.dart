import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/mind_maps_test_support.dart';

final _key = List<int>.generate(32, (index) => 0x80 + index);

void main() {
  late TemporaryDatabasePath temp;
  late FoundationDatabase db;
  late MindMapsTestSession session;
  late DriftMapRepository repo;
  late MapCommands commands;
  late MindMapsTestIds ids;
  late MindMapsTestClock clock;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: _key,
    );
    session = MindMapsTestSession();
    ids = MindMapsTestIds();
    clock = MindMapsTestClock();
    repo = DriftMapRepository(database: db, codec: const MapPayloadCodec());
    commands = MapCommands(
      repository: repo,
      session: session,
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
    'create, rename, describe and confirmed delete are atomic and owner scoped',
    () async {
      final created = await commands.createMap(
        title: '  First map  ',
        description: 'notes',
      );
      expect(created.failureOrNull, isNull);
      final map = created.valueOrNull!;
      expect(map.title, 'First map');
      final graph = (await repo.readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: map.id,
      )).valueOrNull!;
      expect(graph.nodes.single.id, map.centralNodeId);
      expect(graph.nodes.single.kind, MindMapNodeKind.central);
      expect(graph.nodes.single.title, 'First map');
      expect(await db.rawScalar('SELECT count(*) FROM pending_changes'), 2);

      final renamed = await commands.renameMap(mapId: map.id, title: 'Renamed');
      expect(renamed.failureOrNull, isNull);
      expect(
        (await repo.readGraph(
          ownerId: kMindMapsTestAccountA,
          mapId: map.id,
        )).valueOrNull!.nodes.single.title,
        'First map',
        reason: 'renaming must not overwrite edited central content',
      );
      final described = await commands.describeMap(
        mapId: map.id,
        description: 'new description',
      );
      expect(described.valueOrNull!.description, 'new description');
      expect(
        (await repo.readGraph(
          ownerId: kMindMapsTestAccountB,
          mapId: map.id,
        )).valueOrNull,
        isNull,
      );
      expect(
        (await commands.deleteMap(
          mapId: map.id,
          confirmed: false,
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await repo.readGraph(
          ownerId: kMindMapsTestAccountA,
          mapId: map.id,
        )).valueOrNull,
        isNotNull,
      );
      expect(
        (await commands.deleteMap(
          mapId: map.id,
          confirmed: true,
        )).failureOrNull,
        isNull,
      );
      expect(
        (await repo.readGraph(
          ownerId: kMindMapsTestAccountA,
          mapId: map.id,
        )).valueOrNull,
        isNull,
      );
      expect(
        await db.rawScalar(
          'SELECT count(*) FROM mind_map_records WHERE deleted_at IS NOT NULL',
        ),
        1,
      );
      expect(await db.rawScalar('SELECT count(*) FROM pending_changes'), 5);
    },
  );

  test(
    'duplicate copies all graph IDs and relationships but preserves Task ID after restart',
    () async {
      final source = (await commands.createMap(title: 'Source')).valueOrNull!;
      final childA = MindMapNode(
        ownerId: source.ownerId,
        mapId: source.id,
        id: ids.nextNodeId(),
        kind: MindMapNodeKind.task,
        title: 'Task idea',
        x: 10,
        y: 20,
        taskId: kMindMapsTestTaskId,
        revisionId: ids.nextOperationId(),
        createdAt: clock.nextVersion(),
        updatedAt: clock.nextVersion(),
      );
      final childB = MindMapNode(
        ownerId: source.ownerId,
        mapId: source.id,
        id: ids.nextNodeId(),
        kind: MindMapNodeKind.note,
        title: 'Note',
        x: 30,
        y: 40,
        revisionId: ids.nextOperationId(),
        createdAt: clock.nextVersion(),
        updatedAt: clock.nextVersion(),
      );
      final slot = ParentSlot(
        ownerId: source.ownerId,
        mapId: source.id,
        childNodeId: childA.id,
        parentNodeId: source.centralNodeId,
        revisionId: ids.nextOperationId(),
        updatedAt: clock.nextVersion(),
      );
      final link = SideLink(
        ownerId: source.ownerId,
        mapId: source.id,
        firstNodeId: childA.id,
        secondNodeId: childB.id,
        revisionId: ids.nextOperationId(),
        updatedAt: clock.nextVersion(),
      );
      final seeded = await repo.commit(
        MapWriteBatch(
          ownerId: source.ownerId,
          queuedAt: clock.nextVersion(),
          verifyOwner: () async => true,
          nodes: [
            for (final node in [childA, childB])
              MapChange(
                value: node,
                operationId: ids.nextOperationId(),
                kind: ChangeKind.create,
              ),
          ],
          parentSlots: [
            MapChange(
              value: slot,
              operationId: ids.nextOperationId(),
              kind: ChangeKind.create,
            ),
          ],
          sideLinks: [
            MapChange(
              value: link,
              operationId: ids.nextOperationId(),
              kind: ChangeKind.create,
            ),
          ],
        ),
      );
      expect(seeded.failureOrNull, isNull);
      final copy = (await commands.duplicateMap(mapId: source.id)).valueOrNull!;
      expect(copy.id, isNot(source.id));
      expect(copy.centralNodeId, isNot(source.centralNodeId));
      final copied = (await repo.readGraph(
        ownerId: source.ownerId,
        mapId: copy.id,
      )).valueOrNull!;
      expect(copied.nodes, hasLength(3));
      expect(copied.parentSlots, hasLength(1));
      expect(copied.sideLinks, hasLength(1));
      expect(
        copied.nodes.map((n) => n.id).toSet().intersection({
          source.centralNodeId,
          childA.id,
          childB.id,
        }),
        isEmpty,
      );
      expect(
        copied.nodes.singleWhere((n) => n.title == 'Task idea').taskId,
        kMindMapsTestTaskId,
      );
      expect(copied.parentSlots.single.parentNodeId, copy.centralNodeId);
      expect(copied.sideLinks.single.firstNodeId, isNot(link.firstNodeId));

      final path = db.resolvedPath;
      await db.close();
      db = await FoundationDatabase.openEncrypted(path: path, key: _key);
      repo = DriftMapRepository(database: db, codec: const MapPayloadCodec());
      final restarted = (await repo.readGraph(
        ownerId: source.ownerId,
        mapId: copy.id,
      )).valueOrNull!;
      expect(restarted.nodes, hasLength(3));
      expect(restarted.sideLinks, hasLength(1));
      expect(
        restarted.nodes.singleWhere((n) => n.title == 'Task idea').taskId,
        kMindMapsTestTaskId,
      );
    },
  );

  test(
    'blank name and switched session leave confirmed data unchanged',
    () async {
      expect((await commands.createMap(title: ' ')).failureOrNull, isNotNull);
      expect(await db.rawScalar('SELECT count(*) FROM mind_map_records'), 0);
      final map = (await commands.createMap(title: 'Owner A')).valueOrNull!;
      session.switchTo(kMindMapsTestAccountB);
      expect(
        (await commands.renameMap(
          mapId: map.id,
          title: 'Foreign',
          expectedOwnerId: kMindMapsTestAccountA,
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await repo.readGraph(
          ownerId: kMindMapsTestAccountA,
          mapId: map.id,
        )).valueOrNull!.map.title,
        'Owner A',
      );
    },
  );

  test('failure between data write and outbox rolls back both', () async {
    final failing = DriftMapRepository(
      database: db,
      codec: const MapPayloadCodec(),
      beforeOutboxWrite: () async => throw StateError('injected'),
    );
    final command = MapCommands(
      repository: failing,
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    );
    expect(
      (await command.createMap(title: 'Rollback')).failureOrNull,
      isNotNull,
    );
    expect(await db.rawScalar('SELECT count(*) FROM mind_map_records'), 0);
    expect(await db.rawScalar('SELECT count(*) FROM mind_map_node_records'), 0);
    expect(await db.rawScalar('SELECT count(*) FROM pending_changes'), 0);
  });

  test('development preview and real account maps remain separate', () async {
    final accountMap = (await commands.createMap(
      title: 'Private account map',
    )).valueOrNull!;
    session.switchTo(kTasksPreviewAccountId);
    expect(await repo.watchGraphs(kTasksPreviewAccountId).first, isEmpty);
    expect(
      (await repo.readGraph(
        ownerId: kTasksPreviewAccountId,
        mapId: accountMap.id,
      )).valueOrNull,
      isNull,
    );
    final previewMap = (await commands.createMap(
      title: 'Preview map',
    )).valueOrNull!;
    expect(
      (await repo.watchGraphs(kTasksPreviewAccountId).first).map(
        (graph) => graph.map.id,
      ),
      [previewMap.id],
    );
    session.switchTo(kMindMapsTestAccountA);
    expect(
      (await repo.watchGraphs(kMindMapsTestAccountA).first).map(
        (graph) => graph.map.id,
      ),
      [accountMap.id],
    );
    expect(
      (await repo.readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: previewMap.id,
      )).valueOrNull,
      isNull,
    );
  });

  test(
    'cannot replace the protected central node through a repository write',
    () async {
      final source = (await commands.createMap(
        title: 'Protected',
      )).valueOrNull!;
      final attempted = MindMap(
        ownerId: source.ownerId,
        id: source.id,
        title: source.title,
        centralNodeId: ids.nextNodeId(),
        revisionId: ids.nextOperationId(),
        createdAt: source.createdAt,
        updatedAt: clock.nextVersion(),
      );
      final result = await repo.commit(
        MapWriteBatch(
          ownerId: source.ownerId,
          queuedAt: clock.nextVersion(),
          verifyOwner: () async => true,
          maps: [
            MapChange(
              value: attempted,
              operationId: ids.nextOperationId(),
              kind: ChangeKind.update,
              expectedRevisionId: source.revisionId,
            ),
          ],
        ),
      );
      expect(result.failureOrNull, isNotNull);
      expect(
        (await repo.readGraph(
          ownerId: source.ownerId,
          mapId: source.id,
        )).valueOrNull!.map.centralNodeId,
        source.centralNodeId,
      );
    },
  );
}
