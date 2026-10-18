import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/map_graph_rules.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import 'map_payload_codec.dart';

const kMindMapEntityType = 'mind_map';
const kMindMapNodeEntityType = 'mind_map_node';
const kMindMapParentSlotEntityType = 'mind_map_parent_slot';
const kMindMapSideLinkEntityType = 'mind_map_side_link';

/// Encrypted local graph store. A batch and every pending operation commit or
/// roll back together; the cloud dispatch path is added in Phase 7.
final class DriftMapRepository implements MapRepository {
  DriftMapRepository({
    required FoundationDatabase database,
    required MapPayloadCodec codec,
    this.beforeOutboxWrite,
  }) : _db = database,
       _codec = codec;

  final FoundationDatabase _db;
  final MapPayloadCodec _codec;
  final Future<void> Function()? beforeOutboxWrite;

  @override
  Future<AppResult<MapGraph?>> readGraph({
    required String ownerId,
    required String mapId,
  }) async {
    try {
      final row =
          await (_db.select(_db.mindMapRecords)..where(
                (t) => t.accountId.equals(ownerId) & t.mapId.equals(mapId),
              ))
              .getSingleOrNull();
      if (row == null || row.deletedAt != null) {
        return const AppResult.success(null);
      }
      return AppResult.success(await _graphFor(_mapFromRow(row)));
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Stream<List<MapGraph>> watchGraphs(String ownerId) => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          _db.mindMapRecords,
          _db.mindMapNodeRecords,
          _db.mindMapParentSlots,
          _db.mindMapSideLinks,
        },
      )
      .watch()
      .asyncMap((_) => _graphsFor(ownerId));

  @override
  Stream<MapGraph?> watchGraph({
    required String ownerId,
    required String mapId,
  }) => watchGraphs(ownerId).map((graphs) {
    for (final graph in graphs) {
      if (graph.map.id == mapId) return graph;
    }
    return null;
  });

  Future<List<MapGraph>> _graphsFor(String ownerId) async {
    final rows = await (_db.select(
      _db.mindMapRecords,
    )..where((t) => t.accountId.equals(ownerId) & t.deletedAt.isNull())).get();
    return List.unmodifiable(
      await Future.wait(rows.map((row) => _graphFor(_mapFromRow(row)))),
    );
  }

  Future<MapGraph> _graphFor(MindMap map) async {
    final ownerId = map.ownerId;
    final mapId = map.id;
    final nodeRows =
        await (_db.select(_db.mindMapNodeRecords)..where(
              (t) =>
                  t.accountId.equals(ownerId) &
                  t.mapId.equals(mapId) &
                  t.deletedAt.isNull(),
            ))
            .get();
    final nodes = nodeRows.map(_nodeFromRow).toList();
    final liveIds = nodes.map((node) => node.id).toSet();
    final slotRows =
        await (_db.select(_db.mindMapParentSlots)..where(
              (t) =>
                  t.accountId.equals(ownerId) &
                  t.mapId.equals(mapId) &
                  t.deletedAt.isNull(),
            ))
            .get();
    final linkRows =
        await (_db.select(_db.mindMapSideLinks)..where(
              (t) =>
                  t.accountId.equals(ownerId) &
                  t.mapId.equals(mapId) &
                  t.deletedAt.isNull(),
            ))
            .get();
    return MapGraph(
      map: map,
      nodes: nodes,
      parentSlots: [
        for (final row in slotRows)
          if (liveIds.contains(row.childNodeId) &&
              liveIds.contains(row.parentNodeId))
            _slotFromRow(row),
      ],
      sideLinks: [
        for (final row in linkRows)
          if (liveIds.contains(row.firstNodeId) &&
              liveIds.contains(row.secondNodeId))
            _linkFromRow(row),
      ],
    );
  }

  @override
  Future<AppResult<void>> commit(MapWriteBatch batch) async {
    try {
      if (!batch.queuedAt.isUtc || batch.ownerId.trim().isEmpty) {
        throw ArgumentError('Invalid map batch owner or clock');
      }
      await _db.transaction(() async {
        if (!await batch.verifyOwner()) throw const _OwnerChanged();
        for (final change in batch.maps) {
          final map = change.value;
          _sameOwner(batch.ownerId, map.ownerId);
          final current =
              await (_db.select(_db.mindMapRecords)..where(
                    (t) =>
                        t.accountId.equals(map.ownerId) &
                        t.mapId.equals(map.id),
                  ))
                  .getSingleOrNull();
          _checkRevision(
            change,
            current?.revisionId,
            currentDeleted: current?.deletedAt != null,
          );
          if (current != null && current.centralNodeId != map.centralNodeId) {
            throw StateError('Cannot replace a map central node');
          }
          if (change.kind == ChangeKind.create &&
              !batch.nodes.any(
                (entry) =>
                    entry.value.ownerId == map.ownerId &&
                    entry.value.mapId == map.id &&
                    entry.value.id == map.centralNodeId &&
                    entry.value.kind == MindMapNodeKind.central &&
                    !entry.value.isDeleted,
              )) {
            throw StateError('Map creation requires its central node');
          }
          await _db
              .into(_db.mindMapRecords)
              .insertOnConflictUpdate(
                MindMapRecordsCompanion.insert(
                  accountId: map.ownerId,
                  mapId: map.id,
                  title: map.title,
                  description: Value(map.description),
                  centralNodeId: map.centralNodeId,
                  settingsJson: jsonEncode(
                    jsonDecode(_codec.encodeMap(map))['settings'],
                  ),
                  revisionId: map.revisionId,
                  createdAt: map.createdAt,
                  updatedAt: map.updatedAt,
                  deletedAt: Value(map.deletedAt),
                ),
              );
          await beforeOutboxWrite?.call();
          await _queue(
            change,
            ownerId: batch.ownerId,
            entityType: kMindMapEntityType,
            entityId: map.id,
            payload: _codec.encodeMap(map),
            version: map.updatedAt,
            queuedAt: batch.queuedAt,
          );
        }
        for (final change in batch.nodes) {
          final node = change.value;
          _sameOwner(batch.ownerId, node.ownerId);
          final current =
              await (_db.select(_db.mindMapNodeRecords)..where(
                    (t) =>
                        t.accountId.equals(node.ownerId) &
                        t.mapId.equals(node.mapId) &
                        t.nodeId.equals(node.id),
                  ))
                  .getSingleOrNull();
          _checkRevision(
            change,
            current?.revisionId,
            currentDeleted: current?.deletedAt != null,
          );
          final owningMap =
              await (_db.select(_db.mindMapRecords)..where(
                    (t) =>
                        t.accountId.equals(node.ownerId) &
                        t.mapId.equals(node.mapId),
                  ))
                  .getSingleOrNull();
          if (owningMap == null ||
              owningMap.deletedAt != null ||
              (node.id == owningMap.centralNodeId) !=
                  (node.kind == MindMapNodeKind.central) ||
              (current != null && current.kind != node.kind.name)) {
            throw StateError('Invalid central node identity');
          }
          await _db
              .into(_db.mindMapNodeRecords)
              .insertOnConflictUpdate(
                MindMapNodeRecordsCompanion.insert(
                  accountId: node.ownerId,
                  mapId: node.mapId,
                  nodeId: node.id,
                  kind: node.kind.name,
                  title: node.title,
                  description: Value(node.description),
                  x: node.x,
                  y: node.y,
                  status: node.status.name,
                  statusChangedAt: Value(node.statusChangedAt),
                  priority: node.priority.name,
                  appearanceJson: jsonEncode(
                    jsonDecode(_codec.encodeNode(node))['appearance'],
                  ),
                  taskId: Value(node.taskId),
                  revisionId: node.revisionId,
                  createdAt: node.createdAt,
                  updatedAt: node.updatedAt,
                  deletedAt: Value(node.deletedAt),
                ),
              );
          await beforeOutboxWrite?.call();
          await _queue(
            change,
            ownerId: batch.ownerId,
            entityType: kMindMapNodeEntityType,
            entityId: '${node.mapId}:${node.id}',
            payload: _codec.encodeNode(node),
            version: node.updatedAt,
            queuedAt: batch.queuedAt,
          );
        }
        for (final change in batch.parentSlots) {
          final slot = change.value;
          _sameOwner(batch.ownerId, slot.ownerId);
          final current =
              await (_db.select(_db.mindMapParentSlots)..where(
                    (t) =>
                        t.accountId.equals(slot.ownerId) &
                        t.mapId.equals(slot.mapId) &
                        t.childNodeId.equals(slot.childNodeId),
                  ))
                  .getSingleOrNull();
          _checkRevision(
            change,
            current?.revisionId,
            currentDeleted: current?.deletedAt != null,
          );
          await _db
              .into(_db.mindMapParentSlots)
              .insertOnConflictUpdate(
                MindMapParentSlotsCompanion.insert(
                  accountId: slot.ownerId,
                  mapId: slot.mapId,
                  childNodeId: slot.childNodeId,
                  parentNodeId: slot.parentNodeId,
                  appearanceJson: jsonEncode(
                    jsonDecode(_codec.encodeParentSlot(slot))['appearance'],
                  ),
                  revisionId: slot.revisionId,
                  updatedAt: slot.updatedAt,
                  deletedAt: Value(slot.deletedAt),
                ),
              );
          await beforeOutboxWrite?.call();
          await _queue(
            change,
            ownerId: batch.ownerId,
            entityType: kMindMapParentSlotEntityType,
            entityId: '${slot.mapId}:${slot.id}',
            payload: _codec.encodeParentSlot(slot),
            version: slot.updatedAt,
            queuedAt: batch.queuedAt,
          );
        }
        for (final change in batch.sideLinks) {
          final link = change.value;
          _sameOwner(batch.ownerId, link.ownerId);
          final current =
              await (_db.select(_db.mindMapSideLinks)..where(
                    (t) =>
                        t.accountId.equals(link.ownerId) &
                        t.mapId.equals(link.mapId) &
                        t.firstNodeId.equals(link.firstNodeId) &
                        t.secondNodeId.equals(link.secondNodeId),
                  ))
                  .getSingleOrNull();
          _checkRevision(
            change,
            current?.revisionId,
            currentDeleted: current?.deletedAt != null,
          );
          await _db
              .into(_db.mindMapSideLinks)
              .insertOnConflictUpdate(
                MindMapSideLinksCompanion.insert(
                  accountId: link.ownerId,
                  mapId: link.mapId,
                  firstNodeId: link.firstNodeId,
                  secondNodeId: link.secondNodeId,
                  appearanceJson: jsonEncode(
                    jsonDecode(_codec.encodeSideLink(link))['appearance'],
                  ),
                  revisionId: link.revisionId,
                  updatedAt: link.updatedAt,
                  deletedAt: Value(link.deletedAt),
                ),
              );
          await beforeOutboxWrite?.call();
          await _queue(
            change,
            ownerId: batch.ownerId,
            entityType: kMindMapSideLinkEntityType,
            entityId: '${link.mapId}:${link.id}',
            payload: _codec.encodeSideLink(link),
            version: link.updatedAt,
            queuedAt: batch.queuedAt,
          );
        }
        final touched = <String>{
          ...batch.maps.map((entry) => entry.value.id),
          ...batch.nodes.map((entry) => entry.value.mapId),
          ...batch.parentSlots.map((entry) => entry.value.mapId),
          ...batch.sideLinks.map((entry) => entry.value.mapId),
        };
        for (final mapId in touched) {
          await _validateSavedGraph(batch.ownerId, mapId);
        }
      });
      return const AppResult.success(null);
    } on _OwnerChanged {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.authorization,
          messageKey: 'mind_maps.error.account',
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    } on _StaleRevision {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'mind_maps.error.stale',
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  void _sameOwner(String expected, String actual) {
    if (actual != expected) throw const _OwnerChanged();
  }

  void _checkRevision<T>(
    MapChange<T> change,
    String? existing, {
    bool currentDeleted = false,
  }) {
    if (change.kind == ChangeKind.create &&
        existing != null &&
        !currentDeleted) {
      throw const _StaleRevision();
    }
    if (change.kind != ChangeKind.create &&
        (existing == null || existing != change.expectedRevisionId)) {
      throw const _StaleRevision();
    }
  }

  Future<void> _validateSavedGraph(String ownerId, String mapId) async {
    final row =
        await (_db.select(_db.mindMapRecords)..where(
              (t) => t.accountId.equals(ownerId) & t.mapId.equals(mapId),
            ))
            .getSingleOrNull();
    if (row == null) throw StateError('Graph map missing');
    if (row.deletedAt != null) return;
    final graph = await _graphFor(_mapFromRow(row));
    final rules = MapGraphRules(graph);
    if (rules.node(row.centralNodeId)?.kind != MindMapNodeKind.central) {
      throw StateError('Graph central node missing');
    }
    final rawSlots =
        await (_db.select(_db.mindMapParentSlots)..where(
              (t) =>
                  t.accountId.equals(ownerId) &
                  t.mapId.equals(mapId) &
                  t.deletedAt.isNull(),
            ))
            .get();
    final rawLinks =
        await (_db.select(_db.mindMapSideLinks)..where(
              (t) =>
                  t.accountId.equals(ownerId) &
                  t.mapId.equals(mapId) &
                  t.deletedAt.isNull(),
            ))
            .get();
    if (rawSlots.length != graph.parentSlots.length ||
        rawLinks.length != graph.sideLinks.length) {
      throw StateError('Dangling graph relationship');
    }
    final pairs = <String>{};
    String pair(String a, String b) =>
        a.compareTo(b) < 0 ? '$a\u0000$b' : '$b\u0000$a';
    for (final slot in graph.parentSlots) {
      if (!rules.canParent(slot.childNodeId, slot.parentNodeId) ||
          !pairs.add(pair(slot.childNodeId, slot.parentNodeId))) {
        throw StateError('Invalid parent relationship');
      }
    }
    for (final link in graph.sideLinks) {
      if (!pairs.add(pair(link.firstNodeId, link.secondNodeId))) {
        throw StateError('Duplicate graph pair');
      }
    }
  }

  Future<void> _queue<T>(
    MapChange<T> change, {
    required String ownerId,
    required String entityType,
    required String entityId,
    required String payload,
    required DateTime version,
    required DateTime queuedAt,
  }) => _db
      .into(_db.pendingChanges)
      .insert(
        PendingChangesCompanion.insert(
          operationId: change.operationId,
          accountId: ownerId,
          entityType: entityType,
          entityId: entityId,
          kind: change.kind,
          state: PendingChangeState.pending,
          serializedChange: payload,
          createdAt: queuedAt,
          versionTimestamp: version,
        ),
      );

  MindMap _mapFromRow(MindMapRecord row) => _codec.decodeMap(
    jsonEncode({
      'ownerId': row.accountId,
      'id': row.mapId,
      'title': row.title,
      'description': row.description,
      'centralNodeId': row.centralNodeId,
      'settings': jsonDecode(row.settingsJson),
      'revisionId': row.revisionId,
      'createdAt': row.createdAt.toUtc().toIso8601String(),
      'updatedAt': row.updatedAt.toUtc().toIso8601String(),
      'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
    }),
  );

  MindMapNode _nodeFromRow(MindMapNodeRecord row) => _codec.decodeNode(
    jsonEncode({
      'ownerId': row.accountId,
      'mapId': row.mapId,
      'id': row.nodeId,
      'kind': row.kind,
      'title': row.title,
      'description': row.description,
      'x': row.x,
      'y': row.y,
      'status': row.status,
      'statusChangedAt': row.statusChangedAt?.toUtc().toIso8601String(),
      'priority': row.priority,
      'appearance': jsonDecode(row.appearanceJson),
      'taskId': row.taskId,
      'revisionId': row.revisionId,
      'createdAt': row.createdAt.toUtc().toIso8601String(),
      'updatedAt': row.updatedAt.toUtc().toIso8601String(),
      'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
    }),
  );

  ParentSlot _slotFromRow(MindMapParentSlot row) => _codec.decodeParentSlot(
    jsonEncode({
      'ownerId': row.accountId,
      'mapId': row.mapId,
      'childNodeId': row.childNodeId,
      'parentNodeId': row.parentNodeId,
      'appearance': jsonDecode(row.appearanceJson),
      'revisionId': row.revisionId,
      'updatedAt': row.updatedAt.toUtc().toIso8601String(),
      'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
    }),
  );

  SideLink _linkFromRow(MindMapSideLink row) => _codec.decodeSideLink(
    jsonEncode({
      'ownerId': row.accountId,
      'mapId': row.mapId,
      'firstNodeId': row.firstNodeId,
      'secondNodeId': row.secondNodeId,
      'appearance': jsonDecode(row.appearanceJson),
      'revisionId': row.revisionId,
      'updatedAt': row.updatedAt.toUtc().toIso8601String(),
      'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
    }),
  );

  AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: 'mind_maps.error.save',
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}

final class _OwnerChanged implements Exception {
  const _OwnerChanged();
}

final class _StaleRevision implements Exception {
  const _StaleRevision();
}
