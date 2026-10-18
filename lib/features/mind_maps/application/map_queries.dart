import '../domain/mind_map.dart';
import '../domain/mind_map_node.dart';
import 'map_repository.dart';

final class MapSummary {
  const MapSummary({
    required this.map,
    required this.nodeCount,
    required this.completedCount,
    required this.progressPercent,
  });
  final MindMap map;
  final int nodeCount;
  final int completedCount;
  final int progressPercent;
}

abstract final class MapQueries {
  static MapSummary summary(MapGraph graph) {
    final liveNodes = graph.nodes.where((node) => !node.isDeleted).toList();
    // Linked Task state is projected through the Task bridge in US3. Until
    // then, a linked node cannot claim completion from map-owned status.
    final completed = liveNodes
        .where(
          (node) =>
              node.taskId == null && node.status == MindMapNodeStatus.completed,
        )
        .length;
    final count = liveNodes.length;
    return MapSummary(
      map: graph.map,
      nodeCount: count,
      completedCount: completed,
      progressPercent: count == 0
          ? 0
          : ((100 * completed / count) + 0.5).floor(),
    );
  }

  static List<MapSummary> search({
    required String ownerId,
    required Iterable<MapGraph> graphs,
    required String text,
  }) {
    final query = text.trim().toLowerCase();
    final result = [
      for (final graph in graphs)
        if (graph.map.ownerId == ownerId &&
            !graph.map.isDeleted &&
            (query.isEmpty ||
                graph.map.title.toLowerCase().contains(query) ||
                (graph.map.description ?? '').toLowerCase().contains(query)))
          summary(graph),
    ];
    result.sort((a, b) {
      final time = b.map.updatedAt.compareTo(a.map.updatedAt);
      return time != 0 ? time : a.map.id.compareTo(b.map.id);
    });
    return List.unmodifiable(result);
  }
}
