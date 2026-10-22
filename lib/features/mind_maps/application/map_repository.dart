import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/map_graph.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

export 'package:namma_project/features/mind_maps/domain/map_graph.dart';

final class MapChange<T> {
  const MapChange({
    required this.value,
    required this.operationId,
    required this.kind,
    this.expectedRevisionId,
  });
  final T value;
  final String operationId;
  final ChangeKind kind;
  final String? expectedRevisionId;
}

/// The store commits every changed graph record and its outbox entry together.
final class MapWriteBatch {
  MapWriteBatch({
    required this.ownerId,
    required this.queuedAt,
    required this.verifyOwner,
    Iterable<MapChange<MindMap>> maps = const [],
    Iterable<MapChange<MindMapNode>> nodes = const [],
    Iterable<MapChange<ParentSlot>> parentSlots = const [],
    Iterable<MapChange<SideLink>> sideLinks = const [],
  }) : maps = List.unmodifiable(maps),
       nodes = List.unmodifiable(nodes),
       parentSlots = List.unmodifiable(parentSlots),
       sideLinks = List.unmodifiable(sideLinks);

  final String ownerId;
  final DateTime queuedAt;
  final Future<bool> Function() verifyOwner;
  final List<MapChange<MindMap>> maps;
  final List<MapChange<MindMapNode>> nodes;
  final List<MapChange<ParentSlot>> parentSlots;
  final List<MapChange<SideLink>> sideLinks;
}

abstract interface class MapRepository {
  Future<AppResult<MapGraph?>> readGraph({
    required String ownerId,
    required String mapId,
  });

  Stream<List<MapGraph>> watchGraphs(String ownerId);

  Stream<MapGraph?> watchGraph({
    required String ownerId,
    required String mapId,
  });

  Future<AppResult<void>> commit(MapWriteBatch batch);
}
