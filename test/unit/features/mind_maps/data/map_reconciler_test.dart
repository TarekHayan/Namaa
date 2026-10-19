import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/features/mind_maps/application/map_remote_reader.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/data/map_reconciler.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/mind_maps_test_support.dart';

final _key = List<int>.generate(32, (i) => 0x90 + i);
final _at = DateTime.utc(2026, 10, 18, 9);
final _later = DateTime.utc(2026, 10, 18, 10);
const _codec = MapPayloadCodec();

void main() {
  late TemporaryDatabasePath temp;
  late FoundationDatabase db;
  late DriftMapRepository repo;
  late MapReconciler reconciler;
  late MindMap map;
  late MindMapNode center;

  setUp(() async {
    temp = TemporaryDatabasePath();
    db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: _key,
    );
    repo = DriftMapRepository(database: db, codec: _codec);
    reconciler = MapReconciler(store: repo, localStore: DriftLocalStore(db));
    map = MindMap(
      ownerId: kMindMapsTestAccountA,
      id: kMindMapsTestMapId,
      title: 'Map',
      centralNodeId: kMindMapsTestNodeId,
      revisionId: 'map-r1',
      createdAt: _at,
      updatedAt: _at,
    );
    center = _node(
      kMindMapsTestNodeId,
      'Center',
      _at,
      kind: MindMapNodeKind.central,
    );
    expect(
      (await repo.applyInbound(
        entityType: kMindMapEntityType,
        payload: _codec.encodeMap(map),
      )).failureOrNull,
      isNull,
    );
    expect(
      (await repo.applyInbound(
        entityType: kMindMapNodeEntityType,
        payload: _codec.encodeNode(center),
      )).failureOrNull,
      isNull,
    );
  });
  tearDown(() async {
    await db.close();
    temp.dispose();
  });

  test(
    'different nodes merge while older same-node version is retained',
    () async {
      final local = _node(
        '00000000-0000-4000-8102-000000000002',
        'Local edit',
        _later,
      );
      final older = _node(local.id, 'Old remote', _at);
      final independent = _node(
        '00000000-0000-4000-8102-000000000003',
        'Independent remote',
        _later,
      );
      await repo.applyInbound(
        entityType: kMindMapNodeEntityType,
        payload: _codec.encodeNode(local),
      );
      final result = await reconciler.reconcile(
        ownerId: map.ownerId,
        remote: _snapshot(maps: [map], nodes: [center, older, independent]),
      );
      expect(result.failureOrNull, isNull);
      expect(result.valueOrNull!.imported, 1);
      expect(result.valueOrNull!.conflictsRecorded, 1);
      final graph = (await repo.readGraph(
        ownerId: map.ownerId,
        mapId: map.id,
      )).valueOrNull!;
      expect(
        graph.nodes.map((node) => node.title),
        containsAll(['Center', 'Local edit', 'Independent remote']),
      );
      expect(
        (await repo.watchConflicts(map.ownerId, map.id).first)
            .single
            .retainedLabel,
        'Old remote',
      );
    },
  );

  test(
    'newer node tombstone wins and equal-time mismatch stays unresolved',
    () async {
      final local = _node('00000000-0000-4000-8102-000000000002', 'Local', _at);
      await repo.applyInbound(
        entityType: kMindMapNodeEntityType,
        payload: _codec.encodeNode(local),
      );
      final equal = _node(local.id, 'Other', _at);
      final tied = await reconciler.reconcile(
        ownerId: map.ownerId,
        remote: _snapshot(maps: [map], nodes: [center, equal]),
      );
      expect(tied.failureOrNull, isNull);
      expect(tied.valueOrNull!.equalTimestampConflicts, 1);
      expect(
        (await repo.readGraph(
          ownerId: map.ownerId,
          mapId: map.id,
        )).valueOrNull!.nodes.last.title,
        'Local',
      );
      final deleted = _node(local.id, 'Deleted', _later, deleted: true);
      final resolved = await reconciler.reconcile(
        ownerId: map.ownerId,
        remote: _snapshot(maps: [map], nodes: [center, deleted]),
      );
      expect(resolved.failureOrNull, isNull);
      expect(
        (await repo.readGraph(
          ownerId: map.ownerId,
          mapId: map.id,
        )).valueOrNull!.nodes,
        hasLength(1),
      );
    },
  );

  test('newer side role replaces local parent pair atomically', () async {
    final branch = _node('00000000-0000-4000-8102-000000000002', 'Branch', _at);
    final parent = ParentSlot(
      ownerId: map.ownerId,
      mapId: map.id,
      childNodeId: branch.id,
      parentNodeId: center.id,
      revisionId: 'parent-r1',
      updatedAt: _at,
    );
    final side = SideLink(
      ownerId: map.ownerId,
      mapId: map.id,
      firstNodeId: center.id,
      secondNodeId: branch.id,
      revisionId: 'side-r1',
      updatedAt: _later,
    );
    await repo.applyInbound(
      entityType: kMindMapNodeEntityType,
      payload: _codec.encodeNode(branch),
    );
    await repo.applyInbound(
      entityType: kMindMapParentSlotEntityType,
      payload: _codec.encodeParentSlot(parent),
    );
    final result = await reconciler.reconcile(
      ownerId: map.ownerId,
      remote: _snapshot(
        maps: [map],
        nodes: [center, branch],
        sideLinks: [side],
      ),
    );
    expect(result.failureOrNull, isNull);
    final graph = (await repo.readGraph(
      ownerId: map.ownerId,
      mapId: map.id,
    )).valueOrNull!;
    expect(graph.parentSlots, isEmpty);
    expect(graph.sideLinks, hasLength(1));
    expect(await repo.watchConflicts(map.ownerId, map.id).first, isNotEmpty);
  });

  test(
    'foreign page is rejected without changing local account data',
    () async {
      final foreign = MindMap(
        ownerId: kMindMapsTestAccountB,
        id: map.id,
        title: 'Foreign',
        centralNodeId: center.id,
        revisionId: 'foreign',
        createdAt: _at,
        updatedAt: _later,
      );
      final result = await reconciler.reconcile(
        ownerId: map.ownerId,
        remote: _snapshot(maps: [foreign], nodes: [center]),
      );
      expect(result.failureOrNull, isNotNull);
      expect(
        (await repo.readGraph(
          ownerId: map.ownerId,
          mapId: map.id,
        )).valueOrNull!.map.title,
        'Map',
      );
    },
  );
}

MindMapNode _node(
  String id,
  String title,
  DateTime at, {
  MindMapNodeKind kind = MindMapNodeKind.branch,
  bool deleted = false,
}) => MindMapNode(
  ownerId: kMindMapsTestAccountA,
  mapId: kMindMapsTestMapId,
  id: id,
  kind: kind,
  title: title,
  x: 0,
  y: 0,
  revisionId: 'node-$id',
  createdAt: _at,
  updatedAt: at,
  deletedAt: deleted ? at : null,
);

MapRemoteSnapshot _snapshot({
  required List<MindMap> maps,
  required List<MindMapNode> nodes,
  List<ParentSlot> slots = const [],
  List<SideLink> sideLinks = const [],
}) => MapRemoteSnapshot(
  maps: maps,
  nodes: nodes,
  parentSlots: slots,
  sideLinks: sideLinks,
  conflicts: [],
);
