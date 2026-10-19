import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/data/supabase_map_reader.dart';
import 'package:namma_project/features/mind_maps/data/supabase_map_sync_adapter.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import '../../../../support/mind_maps_test_support.dart';

void main() {
  final at = DateTime.utc(2026, 10, 18, 9);
  const codec = MapPayloadCodec();
  final map = MindMap(
    ownerId: kMindMapsTestAccountA,
    id: kMindMapsTestMapId,
    title: 'Map',
    centralNodeId: kMindMapsTestNodeId,
    revisionId: 'map-r1',
    createdAt: at,
    updatedAt: at,
  );
  final center = MindMapNode(
    ownerId: map.ownerId,
    mapId: map.id,
    id: kMindMapsTestNodeId,
    kind: MindMapNodeKind.central,
    title: 'Center',
    x: 0,
    y: 0,
    revisionId: 'node-r1',
    createdAt: at,
    updatedAt: at,
  );
  final branch = MindMapNode(
    ownerId: map.ownerId,
    mapId: map.id,
    id: '00000000-0000-4000-8102-000000000002',
    kind: MindMapNodeKind.branch,
    title: 'Branch',
    x: 1,
    y: 1,
    revisionId: 'node-r2',
    createdAt: at,
    updatedAt: at,
  );
  final slot = ParentSlot(
    ownerId: map.ownerId,
    mapId: map.id,
    childNodeId: branch.id,
    parentNodeId: center.id,
    revisionId: 'slot-r1',
    updatedAt: at,
  );
  final link = SideLink(
    ownerId: map.ownerId,
    mapId: map.id,
    firstNodeId: center.id,
    secondNodeId: branch.id,
    revisionId: 'side-r1',
    updatedAt: at,
  );

  test(
    'outbound validates four identities and stable receipt on retry',
    () async {
      final gateway = _Gateway(map.ownerId);
      final adapter = SupabaseMapSyncAdapter(gateway: gateway);
      final changes = [
        _change(kMindMapEntityType, map.id, codec.encodeMap(map), at),
        _change(
          kMindMapNodeEntityType,
          '${map.id}:${center.id}',
          codec.encodeNode(center),
          at,
        ),
        _change(
          kMindMapParentSlotEntityType,
          '${map.id}:${slot.id}',
          codec.encodeParentSlot(slot),
          at,
        ),
        _change(
          kMindMapSideLinkEntityType,
          '${map.id}:${link.id}',
          codec.encodeSideLink(link),
          at,
        ),
      ];
      for (final change in changes) {
        expect(
          (await adapter.dispatchChange(change)).valueOrNull,
          isA<DispatchAcknowledged>(),
        );
      }
      expect(gateway.operations, hasLength(4));
      expect(
        (await adapter.dispatchChange(changes.first)).valueOrNull,
        isA<DispatchAcknowledged>(),
      );
      expect(gateway.operations.last, changes.first.operationId);
      gateway.fail = true;
      expect(
        (await adapter.dispatchChange(changes.first)).failureOrNull,
        isNotNull,
      );
      gateway.fail = false;
      gateway.wrongOwner = true;
      expect(
        (await adapter.dispatchChange(changes.first)).failureOrNull,
        isNotNull,
      );
      expect(
        (await adapter.dispatchChange(
          _change('unknown', map.id, codec.encodeMap(map), at),
        )).failureOrNull,
        isNotNull,
      );
    },
  );

  test(
    'reader publishes only complete owner pages including tombstones',
    () async {
      final gateway = _Gateway(map.ownerId);
      final deleted = MindMapNode(
        ownerId: map.ownerId,
        mapId: map.id,
        id: '00000000-0000-4000-8102-000000000003',
        kind: MindMapNodeKind.note,
        title: 'Deleted',
        x: 2,
        y: 2,
        revisionId: 'node-r3',
        createdAt: at,
        updatedAt: at.add(const Duration(minutes: 1)),
        deletedAt: at.add(const Duration(minutes: 1)),
      );
      gateway.rows[kMindMapEntityType] = [
        _row(kMindMapEntityType, map.ownerId, map.id, codec.encodeMap(map), at),
      ];
      gateway.rows[kMindMapNodeEntityType] = [
        _row(
          kMindMapNodeEntityType,
          map.ownerId,
          map.id,
          codec.encodeNode(center),
          at,
          nodeId: center.id,
        ),
        _row(
          kMindMapNodeEntityType,
          map.ownerId,
          map.id,
          codec.encodeNode(deleted),
          deleted.updatedAt,
          nodeId: deleted.id,
          deletedAt: deleted.deletedAt,
        ),
      ];
      gateway.rows[kMindMapParentSlotEntityType] = [
        _row(
          kMindMapParentSlotEntityType,
          map.ownerId,
          map.id,
          codec.encodeParentSlot(slot),
          at,
          nodeId: slot.childNodeId,
        ),
      ];
      gateway.rows[kMindMapSideLinkEntityType] = [
        _row(
          kMindMapSideLinkEntityType,
          map.ownerId,
          map.id,
          codec.encodeSideLink(link),
          at,
          nodeId: link.firstNodeId,
          secondId: link.secondNodeId,
        ),
      ];
      gateway.rows[kMapConflictEntityType] = [
        {
          'owner': map.ownerId,
          'conflict_id': 'conflict-1',
          'map_id': map.id,
          'entity_type': kMindMapNodeEntityType,
          'entity_id': '${map.id}:${deleted.id}',
          'active_payload': jsonDecode(codec.encodeNode(deleted)),
          'active_updated_at': deleted.updatedAt.toIso8601String(),
          'retained_payload': jsonDecode(codec.encodeNode(center)),
          'retained_updated_at': center.updatedAt.toIso8601String(),
        },
      ];
      final reader = SupabaseMapReader(gateway: gateway, pageSize: 1);
      final result = await reader.readAll(map.ownerId);
      expect(result.failureOrNull, isNull);
      expect(result.valueOrNull!.nodes, hasLength(2));
      expect(result.valueOrNull!.nodes.last.isDeleted, isTrue);
      expect(result.valueOrNull!.parentSlots, hasLength(1));
      expect(result.valueOrNull!.sideLinks, hasLength(1));
      expect(result.valueOrNull!.conflicts, hasLength(1));
      final adapter = SupabaseMapSyncAdapter(gateway: gateway);
      final version = await adapter.obtainRemoteVersion(
        entityType: kMindMapNodeEntityType,
        entityId: '${map.id}:${deleted.id}',
      );
      expect(version.failureOrNull, isNull);
      expect(version.valueOrNull?.versionTimestamp, deleted.updatedAt);
      gateway.failType = kMindMapSideLinkEntityType;
      expect((await reader.readAll(map.ownerId)).failureOrNull, isNotNull);
      gateway.failType = null;
      gateway.rows[kMindMapNodeEntityType]!.first['owner'] =
          kMindMapsTestAccountB;
      expect((await reader.readAll(map.ownerId)).failureOrNull, isNotNull);
      gateway.rows[kMindMapNodeEntityType] = [];
      expect(
        (await reader.readAll(map.ownerId)).failureOrNull,
        isNotNull,
        reason: 'a map without its central node is an incomplete pass',
      );
      gateway.rows[kMindMapNodeEntityType] = [
        _row(
          kMindMapNodeEntityType,
          map.ownerId,
          map.id,
          codec.encodeNode(center),
          at,
          nodeId: center.id,
        ),
      ];
      gateway.rows[kMapConflictEntityType]!.first['retained_payload'] = {
        ...jsonDecode(codec.encodeNode(center)) as Map<String, dynamic>,
        'ownerId': kMindMapsTestAccountB,
      };
      expect((await reader.readAll(map.ownerId)).failureOrNull, isNotNull);
    },
  );
}

OutboundChange _change(String type, String id, String payload, DateTime at) =>
    OutboundChange(
      operationId: 'op-$type',
      accountId: kMindMapsTestAccountA,
      entityType: type,
      entityId: id,
      kind: ChangeKind.create,
      payload: payload,
      versionTimestamp: at,
    );

Map<String, dynamic> _row(
  String type,
  String owner,
  String mapId,
  String payload,
  DateTime at, {
  String? nodeId,
  String? secondId,
  DateTime? deletedAt,
}) => {
  'owner': owner,
  if (type == kMindMapEntityType) 'id': mapId,
  if (type != kMindMapEntityType) 'map_id': mapId,
  if (type == kMindMapNodeEntityType) 'node_id': nodeId,
  if (type == kMindMapParentSlotEntityType) 'child_node_id': nodeId,
  if (type == kMindMapSideLinkEntityType) 'first_node_id': nodeId,
  if (type == kMindMapSideLinkEntityType) 'second_node_id': secondId,
  'payload': jsonDecode(payload),
  'updated_at': at.toIso8601String(),
  'deleted_at': deletedAt?.toIso8601String(),
};

final class _Gateway implements SupabaseMapGateway {
  _Gateway(this.account);
  String account;
  bool fail = false;
  bool wrongOwner = false;
  String? failType;
  final operations = <String>[];
  final rows = <String, List<Map<String, dynamic>>>{};
  @override
  String? get currentAccountId => account;
  @override
  Future<Map<String, dynamic>> applyChange({
    required String expectedOwnerId,
    required String entityType,
    required String mapId,
    required String entityId,
    required Map<String, dynamic> payload,
    required String operationId,
    required String kind,
    required DateTime updatedAt,
  }) async {
    operations.add(operationId);
    if (fail) throw StateError('offline');
    return {
      'owner': wrongOwner ? kMindMapsTestAccountB : expectedOwnerId,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation_id': operationId,
      'payload': payload,
      'updated_at': updatedAt.toIso8601String(),
      'conflict_detected': false,
    };
  }

  @override
  Future<MapRemotePage> fetchPage({
    required String expectedOwnerId,
    required String entityType,
    required int pageSize,
    String? cursor,
  }) async {
    if (failType == entityType) throw StateError('partial page');
    final offset = cursor == null ? 0 : int.parse(cursor);
    final values = rows[entityType] ?? [];
    final page = values.skip(offset).take(pageSize).toList();
    return MapRemotePage(
      rows: page,
      nextCursor: page.length == pageSize ? '${offset + page.length}' : null,
    );
  }
}
