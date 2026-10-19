import 'map_connection.dart';
import 'mind_map.dart';
import 'mind_map_node.dart';

/// A single owner-scoped snapshot. Tombstoned descendants remain on disk but
/// are hidden whenever their map or node is not live.
final class MapGraph {
  MapGraph({
    required this.map,
    required Iterable<MindMapNode> nodes,
    required Iterable<ParentSlot> parentSlots,
    required Iterable<SideLink> sideLinks,
  }) : nodes = List.unmodifiable(nodes),
       parentSlots = List.unmodifiable(parentSlots),
       sideLinks = List.unmodifiable(sideLinks);

  final MindMap map;
  final List<MindMapNode> nodes;
  final List<ParentSlot> parentSlots;
  final List<SideLink> sideLinks;
}
