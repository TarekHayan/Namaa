import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

/// Published only after every graph stream and conflict page has completed.
final class MapRemoteSnapshot {
  MapRemoteSnapshot({
    required Iterable<MindMap> maps,
    required Iterable<MindMapNode> nodes,
    required Iterable<ParentSlot> parentSlots,
    required Iterable<SideLink> sideLinks,
    required Iterable<MapRemoteConflict> conflicts,
  }) : maps = List.unmodifiable(maps),
       nodes = List.unmodifiable(nodes),
       parentSlots = List.unmodifiable(parentSlots),
       sideLinks = List.unmodifiable(sideLinks),
       conflicts = List.unmodifiable(conflicts);

  final List<MindMap> maps;
  final List<MindMapNode> nodes;
  final List<ParentSlot> parentSlots;
  final List<SideLink> sideLinks;
  final List<MapRemoteConflict> conflicts;
}

final class MapRemoteConflict {
  const MapRemoteConflict({
    required this.id,
    required this.ownerId,
    required this.mapId,
    required this.entityType,
    required this.entityId,
    required this.activePayload,
    required this.activeAt,
    required this.retainedPayload,
    required this.retainedAt,
  });
  final String id;
  final String ownerId;
  final String mapId;
  final String entityType;
  final String entityId;
  final String activePayload;
  final DateTime activeAt;
  final String retainedPayload;
  final DateTime retainedAt;
}

abstract interface class MapRemoteReaderPort {
  Future<AppResult<MapRemoteSnapshot>> readAll(String ownerId);
}
