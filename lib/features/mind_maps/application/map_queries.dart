import '../domain/map_connection.dart';
import '../domain/mind_map.dart';
import '../domain/mind_map_node.dart';
import 'map_repository.dart';
import 'map_task_link_port.dart';

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

final class MapGraphView {
  factory MapGraphView(MapGraph source) {
    final nodes = List<MindMapNode>.unmodifiable(
      source.nodes.where((node) => !node.isDeleted),
    );
    final ids = nodes.map((node) => node.id).toSet();
    return MapGraphView._(
      nodes,
      List<ParentSlot>.unmodifiable(
        source.parentSlots.where(
          (slot) =>
              !slot.isDeleted &&
              ids.contains(slot.childNodeId) &&
              ids.contains(slot.parentNodeId),
        ),
      ),
      List<SideLink>.unmodifiable(
        source.sideLinks.where(
          (link) =>
              !link.isDeleted &&
              ids.contains(link.firstNodeId) &&
              ids.contains(link.secondNodeId),
        ),
      ),
    );
  }

  const MapGraphView._(this.nodes, this.parentSlots, this.sideLinks);

  final List<MindMapNode> nodes;
  final List<ParentSlot> parentSlots;
  final List<SideLink> sideLinks;

  ParentSlot? parentOf(String childId) {
    for (final slot in parentSlots) {
      if (slot.childNodeId == childId) {
        return slot;
      }
    }
    return null;
  }

  SideLink? sideBetween(String a, String b) {
    for (final link in sideLinks) {
      if ((link.firstNodeId == a && link.secondNodeId == b) ||
          (link.firstNodeId == b && link.secondNodeId == a)) {
        return link;
      }
    }
    return null;
  }
}

abstract final class MapQueries {
  static MapGraphView graph(MapGraph source) => MapGraphView(source);

  static MindMapNodeStatus? visibleStatus(
    MindMapNode node,
    Map<String, MapLinkedTask> tasks,
  ) {
    final taskId = node.taskId;
    if (taskId == null) return node.status;
    final task = tasks[taskId];
    if (task == null || !task.available) return null;
    if (task.completed) return MindMapNodeStatus.completed;
    final changed = node.statusChangedAt;
    final transition = task.completionChangedAt;
    return node.status == MindMapNodeStatus.inProgress &&
            changed != null &&
            transition != null &&
            changed.isAfter(transition)
        ? MindMapNodeStatus.inProgress
        : MindMapNodeStatus.notStarted;
  }

  static MapSummary summary(
    MapGraph graph, {
    Map<String, MapLinkedTask> tasks = const {},
  }) {
    final liveNodes = MapGraphView(graph).nodes;
    final completed = liveNodes
        .where(
          (node) => visibleStatus(node, tasks) == MindMapNodeStatus.completed,
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
    Map<String, MapLinkedTask> tasks = const {},
  }) {
    final query = text.trim().toLowerCase();
    final result = [
      for (final graph in graphs)
        if (graph.map.ownerId == ownerId &&
            !graph.map.isDeleted &&
            (query.isEmpty ||
                graph.map.title.toLowerCase().contains(query) ||
                (graph.map.description ?? '').toLowerCase().contains(query)))
          summary(graph, tasks: tasks),
    ];
    result.sort((a, b) {
      final time = b.map.updatedAt.compareTo(a.map.updatedAt);
      return time != 0 ? time : a.map.id.compareTo(b.map.id);
    });
    return List.unmodifiable(result);
  }
}
