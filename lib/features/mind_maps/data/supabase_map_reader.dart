import 'dart:convert';

import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/application/map_remote_reader.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/data/supabase_map_sync_adapter.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

/// A failed page invalidates the entire pass; no partial graph is published.
final class SupabaseMapReader implements MapRemoteReaderPort {
  SupabaseMapReader({
    required SupabaseMapGateway gateway,
    MapPayloadCodec codec = const MapPayloadCodec(),
    this.pageSize = kMapRemotePageSize,
  }) : _gateway = gateway,
       _codec = codec;

  final SupabaseMapGateway _gateway;
  final MapPayloadCodec _codec;
  final int pageSize;

  @override
  Future<AppResult<MapRemoteSnapshot>> readAll(String ownerId) async {
    try {
      if (pageSize < 1) throw ArgumentError.value(pageSize, 'pageSize');
      final maps = <MindMap>[];
      final nodes = <MindMapNode>[];
      final slots = <ParentSlot>[];
      final links = <SideLink>[];
      final conflicts = <MapRemoteConflict>[];
      for (final type in [
        kMindMapEntityType,
        kMindMapNodeEntityType,
        kMindMapParentSlotEntityType,
        kMindMapSideLinkEntityType,
        kMapConflictEntityType,
      ]) {
        String? cursor;
        final seen = <String>{};
        do {
          final page = await _gateway.fetchPage(
            expectedOwnerId: ownerId,
            entityType: type,
            pageSize: pageSize,
            cursor: cursor,
          );
          if (page.rows.length > pageSize ||
              (page.rows.isEmpty && page.nextCursor != null)) {
            throw StateError('Incomplete Map page');
          }
          for (final row in page.rows) {
            if (row['owner'] != ownerId) throw StateError('Foreign Map owner');
            if (type == kMapConflictEntityType) {
              if (row['active_payload'] is! Map ||
                  row['retained_payload'] is! Map) {
                throw StateError('Invalid Map conflict');
              }
              final active = Map<String, dynamic>.from(
                row['active_payload'] as Map,
              );
              final retained = Map<String, dynamic>.from(
                row['retained_payload'] as Map,
              );
              if (active['ownerId'] != ownerId ||
                  retained['ownerId'] != ownerId ||
                  !kMapEntityTypes.contains(row['entity_type'])) {
                throw StateError('Foreign Map conflict payload');
              }
              conflicts.add(
                MapRemoteConflict(
                  id: row['conflict_id'] as String,
                  ownerId: ownerId,
                  mapId: row['map_id'] as String,
                  entityType: row['entity_type'] as String,
                  entityId: row['entity_id'] as String,
                  activePayload: jsonEncode(row['active_payload']),
                  activeAt: DateTime.parse(
                    row['active_updated_at'] as String,
                  ).toUtc(),
                  retainedPayload: jsonEncode(row['retained_payload']),
                  retainedAt: DateTime.parse(
                    row['retained_updated_at'] as String,
                  ).toUtc(),
                ),
              );
              continue;
            }
            final payload = Map<String, dynamic>.from(row['payload'] as Map);
            final remoteId = mapRemoteEntityId(type, row);
            final payloadId = switch (type) {
              kMindMapEntityType => payload['id'],
              kMindMapNodeEntityType => '${payload['mapId']}:${payload['id']}',
              kMindMapParentSlotEntityType =>
                '${payload['mapId']}:parent:${payload['childNodeId']}',
              _ =>
                '${payload['mapId']}:side:${payload['firstNodeId']}:${payload['secondNodeId']}',
            };
            if (payload['ownerId'] != ownerId ||
                payloadId != remoteId ||
                (type != kMindMapEntityType &&
                    payload['mapId'] != row['map_id']) ||
                !_sameInstant(payload['updatedAt'], row['updated_at']) ||
                !_sameInstant(payload['deletedAt'], row['deleted_at'])) {
              throw StateError('Map page identity or version mismatch');
            }
            switch (type) {
              case kMindMapEntityType:
                maps.add(_codec.decodeMap(jsonEncode(payload)));
              case kMindMapNodeEntityType:
                nodes.add(_codec.decodeNode(jsonEncode(payload)));
              case kMindMapParentSlotEntityType:
                slots.add(_codec.decodeParentSlot(jsonEncode(payload)));
              case kMindMapSideLinkEntityType:
                links.add(_codec.decodeSideLink(jsonEncode(payload)));
            }
          }
          cursor = page.nextCursor;
          if (cursor != null && !seen.add(cursor)) {
            throw StateError('Repeated Map cursor');
          }
        } while (cursor != null);
      }
      for (final map in maps.where((value) => !value.isDeleted)) {
        if (!nodes.any(
          (node) =>
              node.ownerId == map.ownerId &&
              node.mapId == map.id &&
              node.id == map.centralNodeId &&
              node.kind == MindMapNodeKind.central &&
              !node.isDeleted,
        )) {
          throw StateError('Map central node missing from complete pass');
        }
      }
      return AppResult.success(
        MapRemoteSnapshot(
          maps: maps,
          nodes: nodes,
          parentSlots: slots,
          sideLinks: links,
          conflicts: conflicts,
        ),
      );
    } catch (error) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.cloud,
          messageKey: 'mind_maps.sync.failed',
          occurredAt: DateTime.now().toUtc(),
          technicalCause: error.runtimeType.toString(),
        ),
      );
    }
  }

  static bool _sameInstant(Object? first, Object? second) {
    if (first == null || second == null) return first == null && second == null;
    if (first is! String || second is! String) return false;
    final left = DateTime.tryParse(first);
    final right = DateTime.tryParse(second);
    return left != null && right != null && left.toUtc() == right.toUtc();
  }
}
