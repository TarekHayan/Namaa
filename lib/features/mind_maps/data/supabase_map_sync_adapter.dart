import 'dart:convert';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kMapRemotePageSize = 100;
const kMapConflictEntityType = 'mind_map_conflict';
const kMapEntityTypes = <String>{
  kMindMapEntityType,
  kMindMapNodeEntityType,
  kMindMapParentSlotEntityType,
  kMindMapSideLinkEntityType,
};

final class MapRemotePage {
  const MapRemotePage({required this.rows, this.nextCursor});
  final List<Map<String, dynamic>> rows;
  final String? nextCursor;
}

abstract interface class SupabaseMapGateway {
  String? get currentAccountId;
  Future<Map<String, dynamic>> applyChange({
    required String expectedOwnerId,
    required String entityType,
    required String mapId,
    required String entityId,
    required Map<String, dynamic> payload,
    required String operationId,
    required String kind,
    required DateTime updatedAt,
    DateTime? baseUpdatedAt,
  });
  Future<MapRemotePage> fetchPage({
    required String expectedOwnerId,
    required String entityType,
    required int pageSize,
    String? cursor,
  });
}

final class SupabaseMapGatewayImpl implements SupabaseMapGateway {
  SupabaseMapGatewayImpl(this._client);
  final SupabaseClient _client;

  @override
  String? get currentAccountId => _client.auth.currentUser?.id;

  void _checkOwner(String expected) {
    if (currentAccountId != expected) {
      throw StateError('Map sync account changed');
    }
  }

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
    DateTime? baseUpdatedAt,
  }) async {
    _checkOwner(expectedOwnerId);
    final result = await _client.rpc<dynamic>(
      'apply_mind_map_change_v2',
      params: {
        'p_entity_type': entityType,
        'p_map_id': mapId,
        'p_entity_id': entityId,
        'p_payload': payload,
        'p_operation_id': operationId,
        'p_updated_at': updatedAt.toUtc().toIso8601String(),
        'p_kind': kind,
        'p_base_updated_at': baseUpdatedAt?.toUtc().toIso8601String(),
      },
    );
    _checkOwner(expectedOwnerId);
    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    if (result is Map) return Map<String, dynamic>.from(result);
    throw StateError('Map mutation returned no receipt');
  }

  @override
  Future<MapRemotePage> fetchPage({
    required String expectedOwnerId,
    required String entityType,
    required int pageSize,
    String? cursor,
  }) async {
    _checkOwner(expectedOwnerId);
    final table = switch (entityType) {
      kMindMapEntityType => 'mind_maps',
      kMindMapNodeEntityType => 'mind_map_nodes',
      kMindMapParentSlotEntityType => 'mind_map_parent_slots',
      kMindMapSideLinkEntityType => 'mind_map_side_links',
      kMapConflictEntityType => 'mind_map_conflicts',
      _ => throw const FormatException('Unsupported Map entity type'),
    };
    final offset = cursor == null ? 0 : int.parse(cursor);
    if (offset < 0 || pageSize < 1) throw const FormatException('Invalid page');
    final primary = switch (entityType) {
      kMindMapEntityType => 'id',
      kMindMapNodeEntityType ||
      kMindMapParentSlotEntityType ||
      kMindMapSideLinkEntityType => 'map_id',
      _ => 'conflict_id',
    };
    var query = _client
        .from(table)
        .select()
        .eq('owner', expectedOwnerId)
        .order(primary);
    if (entityType == kMindMapNodeEntityType) {
      query = query.order('node_id');
    } else if (entityType == kMindMapParentSlotEntityType) {
      query = query.order('child_node_id');
    } else if (entityType == kMindMapSideLinkEntityType) {
      query = query.order('first_node_id').order('second_node_id');
    }
    final result = await query.range(offset, offset + pageSize - 1);
    _checkOwner(expectedOwnerId);
    final rows = [
      for (final row in result) Map<String, dynamic>.from(row as Map),
    ];
    return MapRemotePage(
      rows: rows,
      nextCursor: rows.length == pageSize ? '${offset + rows.length}' : null,
    );
  }
}

final class SupabaseMapSyncAdapter implements CloudSyncPort {
  SupabaseMapSyncAdapter({required SupabaseMapGateway gateway})
    : _gateway = gateway;
  final SupabaseMapGateway _gateway;
  final MapPayloadCodec _codec = const MapPayloadCodec();

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    try {
      if (!kMapEntityTypes.contains(change.entityType)) {
        throw const FormatException('Unsupported Map entity type');
      }
      final payload = Map<String, dynamic>.from(
        jsonDecode(change.payload) as Map,
      );
      final mapId = change.entityType == kMindMapEntityType
          ? change.entityId
          : payload['mapId'] as String;
      final decoded = switch (change.entityType) {
        kMindMapEntityType => _codec.decodeMap(change.payload),
        kMindMapNodeEntityType => _codec.decodeNode(change.payload),
        kMindMapParentSlotEntityType => _codec.decodeParentSlot(change.payload),
        _ => _codec.decodeSideLink(change.payload),
      };
      final owner = switch (decoded) {
        final dynamic value => value.ownerId as String,
      };
      final updatedAt = switch (decoded) {
        final dynamic value => value.updatedAt as DateTime,
      };
      final deletedAt = switch (decoded) {
        final dynamic value => value.deletedAt as DateTime?,
      };
      final expectedId = switch (change.entityType) {
        kMindMapEntityType => payload['id'],
        kMindMapNodeEntityType => '$mapId:${payload['id']}',
        kMindMapParentSlotEntityType =>
          '$mapId:parent:${payload['childNodeId']}',
        _ => '$mapId:side:${payload['firstNodeId']}:${payload['secondNodeId']}',
      };
      if (owner != change.accountId ||
          expectedId != change.entityId ||
          updatedAt != change.versionTimestamp ||
          (deletedAt != null) != (change.kind == ChangeKind.delete)) {
        throw const FormatException('Map operation identity mismatch');
      }
      final row = await _gateway.applyChange(
        expectedOwnerId: change.accountId,
        entityType: change.entityType,
        mapId: mapId,
        entityId: change.entityId,
        payload: payload,
        operationId: change.operationId,
        kind: change.kind.name,
        updatedAt: change.versionTimestamp,
        baseUpdatedAt: change.baseUpdatedAt,
      );
      if (row['owner'] != change.accountId ||
          row['operation_id'] != change.operationId ||
          row['entity_type'] != change.entityType ||
          row['entity_id'] != change.entityId) {
        throw StateError('Map receipt identity mismatch');
      }
      if (row['payload'] case final Map<String, dynamic> receiptPayload) {
        if (receiptPayload['ownerId'] != change.accountId) {
          throw StateError('Foreign Map receipt payload');
        }
      } else {
        throw StateError('Map receipt payload missing');
      }
      if (row['conflict_detected'] == true) {
        final resultAt = DateTime.parse(row['updated_at'] as String).toUtc();
        final retainedAt = row['retained_updated_at'] == null
            ? null
            : DateTime.parse(row['retained_updated_at'] as String).toUtc();
        final competingAt = resultAt == change.versionTimestamp
            ? retainedAt
            : resultAt;
        final competing = resultAt == change.versionTimestamp
            ? row['retained_payload']
            : row['payload'];
        if (competingAt != null) {
          return AppResult.success(
            DispatchVersionConflict(
              remoteVersionTimestamp: competingAt,
              remotePayload: competing == null ? null : jsonEncode(competing),
            ),
          );
        }
      }
      return AppResult.success(
        DispatchAcknowledged(
          acknowledgementId: change.operationId,
          remoteVersionTimestamp: DateTime.parse(
            row['updated_at'] as String,
          ).toUtc(),
        ),
      );
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async {
    try {
      if (!kMapEntityTypes.contains(entityType)) {
        throw const FormatException('Unsupported Map entity type');
      }
      final owner = _gateway.currentAccountId;
      if (owner == null) throw StateError('Not authenticated');
      String? cursor;
      final seen = <String>{};
      do {
        final page = await _gateway.fetchPage(
          expectedOwnerId: owner,
          entityType: entityType,
          pageSize: kMapRemotePageSize,
          cursor: cursor,
        );
        for (final row in page.rows) {
          if (row['owner'] != owner) throw StateError('Foreign Map owner');
          final id = mapRemoteEntityId(entityType, row);
          if (id == entityId) {
            final payload = Map<String, dynamic>.from(row['payload'] as Map);
            if (payload['ownerId'] != owner ||
                DateTime.parse(payload['updatedAt'] as String).toUtc() !=
                    DateTime.parse(row['updated_at'] as String).toUtc() ||
                (payload['deletedAt'] == null) != (row['deleted_at'] == null)) {
              throw StateError('Map remote version identity mismatch');
            }
            return AppResult.success(
              RemoteVersion(
                entityType: entityType,
                entityId: id,
                versionTimestamp: DateTime.parse(
                  row['updated_at'] as String,
                ).toUtc(),
                payload: jsonEncode(payload),
              ),
            );
          }
        }
        cursor = page.nextCursor;
        if (cursor != null && !seen.add(cursor)) {
          throw StateError('Repeated Map cursor');
        }
      } while (cursor != null);
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }
}

String mapRemoteEntityId(
  String type,
  Map<String, dynamic> row,
) => switch (type) {
  kMindMapEntityType => row['id'] as String,
  kMindMapNodeEntityType => '${row['map_id']}:${row['node_id']}',
  kMindMapParentSlotEntityType =>
    '${row['map_id']}:parent:${row['child_node_id']}',
  kMindMapSideLinkEntityType =>
    '${row['map_id']}:side:${row['first_node_id']}:${row['second_node_id']}',
  _ => throw const FormatException('Unsupported Map entity type'),
};

AppFailure _failure(Object error) => AppFailure.recoverable(
  category: AppFailureCategory.cloud,
  messageKey: 'mind_maps.sync.failed',
  occurredAt: DateTime.now().toUtc(),
  technicalCause: error.runtimeType.toString(),
);
