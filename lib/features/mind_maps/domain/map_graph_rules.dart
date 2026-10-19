import '../application/map_repository.dart';
import 'map_connection.dart';
import 'mind_map_node.dart';

/// Checks the visible graph. Side links never participate in ancestry.
final class MapGraphRules {
  MapGraphRules(this.graph);

  final MapGraph graph;

  MindMapNode? node(String id) {
    for (final candidate in graph.nodes) {
      if (candidate.id == id &&
          !candidate.isDeleted &&
          candidate.ownerId == graph.map.ownerId &&
          candidate.mapId == graph.map.id) {
        return candidate;
      }
    }
    return null;
  }

  ParentSlot? parentSlot(String childId) {
    for (final slot in graph.parentSlots) {
      if (slot.childNodeId == childId && !slot.isDeleted) {
        return slot;
      }
    }
    return null;
  }

  SideLink? sideLink(String a, String b) {
    for (final link in graph.sideLinks) {
      if (!link.isDeleted &&
          _pair(link.firstNodeId, link.secondNodeId) == _pair(a, b)) {
        return link;
      }
    }
    return null;
  }

  bool canParent(String childId, String parentId) {
    final child = node(childId);
    if (child == null ||
        child.kind == MindMapNodeKind.central ||
        node(parentId) == null ||
        childId == parentId) {
      return false;
    }
    if (sideLink(childId, parentId) != null) {
      return false;
    }
    final visited = <String>{};
    var current = parentId;
    while (visited.add(current)) {
      if (current == childId) {
        return false;
      }
      final parent = parentSlot(current);
      if (parent == null) {
        return true;
      }
      current = parent.parentNodeId;
    }
    return false;
  }

  bool canSideLink(String a, String b) {
    if (a == b ||
        node(a) == null ||
        node(b) == null ||
        sideLink(a, b) != null) {
      return false;
    }
    return !graph.parentSlots.any(
      (slot) =>
          !slot.isDeleted &&
          _pair(slot.childNodeId, slot.parentNodeId) == _pair(a, b),
    );
  }

  List<ParentSlot> incidentParentSlots(String id) => [
    for (final slot in graph.parentSlots)
      if (!slot.isDeleted &&
          (slot.childNodeId == id || slot.parentNodeId == id))
        slot,
  ];

  List<SideLink> incidentSideLinks(String id) => [
    for (final link in graph.sideLinks)
      if (!link.isDeleted &&
          (link.firstNodeId == id || link.secondNodeId == id))
        link,
  ];

  String _pair(String a, String b) =>
      a.compareTo(b) < 0 ? '$a\u0000$b' : '$b\u0000$a';
}
