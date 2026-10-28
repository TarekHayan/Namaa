import 'dart:convert';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/sync_versions.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/mind_maps/application/map_reconciliation.dart';
import 'package:namma_project/features/mind_maps/application/map_remote_reader.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/domain/map_graph_rules.dart';

/// Reconciles independent records in one encrypted transaction. Both the
/// winner and the retained loser are durable before watchers see a new graph.
final class MapReconciler implements MapReconciliationPort {
  MapReconciler({
    required MapReconciliationStorePort store,
    required LocalStorePort localStore,
    MapPayloadCodec codec = const MapPayloadCodec(),
    DateTime Function()? detectedAt,
  }) : _store = store,
       _localStore = localStore,
       _codec = codec,
       _detectedAt = detectedAt ?? (() => DateTime.now().toUtc());

  final MapReconciliationStorePort _store;
  final LocalStorePort _localStore;
  final MapPayloadCodec _codec;
  final DateTime Function() _detectedAt;

  @override
  Future<AppResult<MapReconciliationSummary>> reconcile({
    required String ownerId,
    required MapRemoteSnapshot remote,
  }) async {
    if (remote.maps.any((e) => e.ownerId != ownerId) ||
        remote.nodes.any((e) => e.ownerId != ownerId) ||
        remote.parentSlots.any((e) => e.ownerId != ownerId) ||
        remote.sideLinks.any((e) => e.ownerId != ownerId) ||
        remote.conflicts.any((e) => e.ownerId != ownerId)) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    return _store.runInTransaction(() async {
      var imported = 0;
      var conflicts = 0;
      var equal = 0;
      final records = <_Record>[
        for (final map in remote.maps)
          _Record(
            kMindMapEntityType,
            map.id,
            _codec.encodeMap(map),
            map.updatedAt,
          ),
        for (final node in remote.nodes)
          _Record(
            kMindMapNodeEntityType,
            '${node.mapId}:${node.id}',
            _codec.encodeNode(node),
            node.updatedAt,
          ),
        for (final slot in remote.parentSlots)
          _Record(
            kMindMapParentSlotEntityType,
            '${slot.mapId}:${slot.id}',
            _codec.encodeParentSlot(slot),
            slot.updatedAt,
          ),
        for (final link in remote.sideLinks)
          _Record(
            kMindMapSideLinkEntityType,
            '${link.mapId}:${link.id}',
            _codec.encodeSideLink(link),
            link.updatedAt,
          ),
      ];
      final pendingRead = await _localStore.readPendingChanges(ownerId);
      if (pendingRead.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      final pendingVersions = PendingSyncVersions.index(
        pendingRead.valueOrNull!,
      );
      for (final record in records) {
        final read = await _store.readPayload(
          ownerId: ownerId,
          entityType: record.type,
          entityId: record.id,
        );
        if (read.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        final localPayload = read.valueOrNull;
        if (localPayload == null) {
          final allowed = await _allowRelationship(ownerId, record);
          if (allowed.failureOrNull case final failure?) {
            return AppResult.failure(failure);
          }
          if (!allowed.valueOrNull!) {
            conflicts++;
            continue;
          }
          final applied = await _store.applyInbound(
            entityType: record.type,
            payload: record.payload,
          );
          if (applied.failureOrNull case final failure?) {
            return AppResult.failure(failure);
          }
          imported++;
          continue;
        }
        if (localPayload == record.payload) continue;
        final localAt = DateTime.parse(
          (jsonDecode(localPayload) as Map<String, dynamic>)['updatedAt']
              as String,
        ).toUtc();
        final comparison = record.updatedAt.compareTo(localAt);
        final pending = await _store.hasPendingChange(
          ownerId: ownerId,
          entityType: record.type,
          entityId: record.id,
        );
        if (pending.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        if (pending.valueOrNull == true &&
            comparison != 0 &&
            (pendingVersions[(record.type, record.id)]?.knows(
                  record.updatedAt,
                ) ??
                false)) {
          // Remote is the base of the queued edit: keep local for upload.
          continue;
        }
        if (comparison > 0) {
          final allowed = await _allowRelationship(ownerId, record);
          if (allowed.failureOrNull case final failure?) {
            return AppResult.failure(failure);
          }
          if (!allowed.valueOrNull!) {
            conflicts++;
            continue;
          }
        }
        if (pending.valueOrNull != true && comparison > 0) {
          final applied = await _store.applyInbound(
            entityType: record.type,
            payload: record.payload,
          );
          if (applied.failureOrNull case final failure?) {
            return AppResult.failure(failure);
          }
          imported++;
          continue;
        }
        final recorded = await _recordConflict(
          id: syncConflictId(
            accountId: ownerId,
            entityType: record.type,
            entityId: record.id,
            activeAt: comparison > 0 ? record.updatedAt : localAt,
            retainedAt: comparison > 0 ? localAt : record.updatedAt,
            activePayload: comparison > 0 ? record.payload : localPayload,
            retainedPayload: comparison > 0 ? localPayload : record.payload,
          ),
          ownerId: ownerId,
          entityType: record.type,
          entityId: record.id,
          activePayload: comparison > 0 ? record.payload : localPayload,
          activeAt: comparison > 0 ? record.updatedAt : localAt,
          activeSource: comparison > 0
              ? VersionSource.remote
              : VersionSource.local,
          retainedPayload: comparison > 0 ? localPayload : record.payload,
          retainedAt: comparison > 0 ? localAt : record.updatedAt,
          retainedSource: comparison > 0
              ? VersionSource.local
              : VersionSource.remote,
        );
        if (recorded.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        conflicts++;
        if (comparison == 0) equal++;
        if (comparison > 0) {
          final applied = await _store.applyInbound(
            entityType: record.type,
            payload: record.payload,
          );
          if (applied.failureOrNull case final failure?) {
            return AppResult.failure(failure);
          }
          imported++;
        }
      }
      for (final conflict in remote.conflicts) {
        final recorded = await _recordConflict(
          id: 'map-server-${conflict.id}',
          ownerId: ownerId,
          entityType: conflict.entityType,
          entityId: conflict.entityId,
          activePayload: conflict.activePayload,
          activeAt: conflict.activeAt,
          activeSource: VersionSource.remote,
          retainedPayload: conflict.retainedPayload,
          retainedAt: conflict.retainedAt,
          retainedSource: VersionSource.remote,
        );
        if (recorded.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        conflicts++;
        if (conflict.activeAt == conflict.retainedAt) equal++;
      }
      return AppResult.success(
        MapReconciliationSummary(
          imported: imported,
          conflictsRecorded: conflicts,
          equalTimestampConflicts: equal,
        ),
      );
    });
  }

  Future<AppResult<bool>> _allowRelationship(
    String ownerId,
    _Record record,
  ) async {
    if (record.type != kMindMapParentSlotEntityType &&
        record.type != kMindMapSideLinkEntityType) {
      return const AppResult.success(true);
    }
    final value = jsonDecode(record.payload) as Map<String, dynamic>;
    if (value['deletedAt'] != null) return const AppResult.success(true);
    final mapId = value['mapId'] as String;
    final read = await _store.readGraph(ownerId: ownerId, mapId: mapId);
    if (read.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final graph = read.valueOrNull;
    if (graph == null) return const AppResult.success(true);
    final rules = MapGraphRules(graph);
    String first;
    String second;
    String? collisionPayload;
    DateTime? collisionAt;
    String? collisionType;
    if (record.type == kMindMapParentSlotEntityType) {
      final slot = _codec.decodeParentSlot(record.payload);
      first = slot.childNodeId;
      second = slot.parentNodeId;
      final side = rules.sideLink(first, second);
      if (side != null) {
        collisionPayload = _codec.encodeSideLink(side);
        collisionAt = side.updatedAt;
        collisionType = kMindMapSideLinkEntityType;
      } else if (rules.canParent(first, second)) {
        return const AppResult.success(true);
      }
    } else {
      final side = _codec.decodeSideLink(record.payload);
      first = side.firstNodeId;
      second = side.secondNodeId;
      if (rules.sideLink(first, second) != null) {
        return const AppResult.success(
          true,
        ); // Same independently versioned pair.
      }
      for (final slot in graph.parentSlots) {
        if ((slot.childNodeId == first && slot.parentNodeId == second) ||
            (slot.childNodeId == second && slot.parentNodeId == first)) {
          collisionPayload = _codec.encodeParentSlot(slot);
          collisionAt = slot.updatedAt;
          collisionType = kMindMapParentSlotEntityType;
          break;
        }
      }
      if (collisionPayload == null && rules.canSideLink(first, second)) {
        return const AppResult.success(true);
      }
    }
    if (collisionPayload != null &&
        collisionAt != null &&
        collisionType != null &&
        record.updatedAt.isAfter(collisionAt)) {
      final source = jsonDecode(collisionPayload) as Map<String, dynamic>;
      source['updatedAt'] = record.updatedAt.toIso8601String();
      source['deletedAt'] = record.updatedAt.toIso8601String();
      final tombstone = await _store.applyInbound(
        entityType: collisionType,
        payload: jsonEncode(source),
      );
      if (tombstone.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      final recorded = await _recordConflict(
        id: _conflictId(
          ownerId,
          record.type,
          record.id,
          collisionPayload,
          record.payload,
        ),
        ownerId: ownerId,
        entityType: record.type,
        entityId: record.id,
        activePayload: record.payload,
        activeAt: record.updatedAt,
        activeSource: VersionSource.remote,
        retainedPayload: collisionPayload,
        retainedAt: collisionAt,
        retainedSource: VersionSource.local,
      );
      if (recorded.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      return const AppResult.success(true);
    }
    final retained = collisionPayload ?? record.payload;
    final recorded = await _recordConflict(
      id: _conflictId(
        ownerId,
        record.type,
        record.id,
        retained,
        record.payload,
      ),
      ownerId: ownerId,
      entityType: record.type,
      entityId: record.id,
      activePayload: retained,
      activeAt: collisionAt ?? record.updatedAt,
      activeSource: VersionSource.local,
      retainedPayload: record.payload,
      retainedAt: record.updatedAt,
      retainedSource: VersionSource.remote,
    );
    if (recorded.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    return const AppResult.success(false);
  }

  Future<AppResult<void>> _recordConflict({
    required String id,
    required String ownerId,
    required String entityType,
    required String entityId,
    required String activePayload,
    required DateTime activeAt,
    required VersionSource activeSource,
    required String retainedPayload,
    required DateTime retainedAt,
    required VersionSource retainedSource,
  }) => _localStore.recordConflict(
    ConflictRecordInput(
      conflictId: id,
      accountId: ownerId,
      entityType: entityType,
      entityId: entityId,
      activeVersion: RecordVersionInput(
        source: activeSource,
        versionTimestamp: activeAt,
        payload: activePayload,
      ),
      retainedVersion: RecordVersionInput(
        source: retainedSource,
        versionTimestamp: retainedAt,
        payload: retainedPayload,
      ),
      detectedAt: _detectedAt(),
    ),
  );

  static String _conflictId(
    String owner,
    String type,
    String id,
    String first,
    String second,
  ) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode('$owner|$type|$id|$first|$second')) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return 'map-inbound-$owner-$type-$id-${hash.toRadixString(16)}';
  }

  static AppFailure _failure(AppFailureCategory category) =>
      AppFailure.recoverable(
        category: category,
        messageKey: 'mind_maps.sync.failed',
        occurredAt: DateTime.now().toUtc(),
      );
}

final class _Record {
  const _Record(this.type, this.id, this.payload, this.updatedAt);
  final String type;
  final String id;
  final String payload;
  final DateTime updatedAt;
}
