import 'dart:math' as math;

import 'map_graph.dart';
import 'mind_map.dart';

/// Saved canvas coordinates; viewport transformations never alter these values.
final class MapPoint {
  const MapPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is MapPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Deterministic parent-only placement. Side links are deliberately ignored.
abstract final class MapLayoutEngine {
  static Map<String, MapPoint> place(
    MapGraph graph, {
    required MapLayout layout,
    required double spacing,
    bool rtl = false,
  }) {
    if (!spacing.isFinite || spacing < 20 || spacing > 1000) {
      throw ArgumentError.value(spacing, 'spacing');
    }
    final nodes = {
      for (final node in graph.nodes.where((n) => !n.isDeleted)) node.id: node,
    };
    if (layout == MapLayout.freeform) {
      return Map.unmodifiable({
        for (final node in nodes.values) node.id: MapPoint(node.x, node.y),
      });
    }
    final children = <String, List<String>>{
      for (final id in nodes.keys) id: <String>[],
    };
    final parent = <String, String>{};
    for (final slot in graph.parentSlots.where((slot) => !slot.isDeleted)) {
      if (!nodes.containsKey(slot.childNodeId) ||
          !nodes.containsKey(slot.parentNodeId) ||
          parent.containsKey(slot.childNodeId)) {
        continue;
      }
      parent[slot.childNodeId] = slot.parentNodeId;
      children[slot.parentNodeId]!.add(slot.childNodeId);
    }
    for (final list in children.values) {
      list.sort();
    }
    final roots = nodes.keys.where((id) => !parent.containsKey(id)).toList()
      ..sort((a, b) {
        if (a == graph.map.centralNodeId) return -1;
        if (b == graph.map.centralNodeId) return 1;
        return a.compareTo(b);
      });
    // A corrupt cycle should still render every element rather than hide it.
    if (roots.isEmpty && nodes.isNotEmpty) {
      final ordered = nodes.keys.toList()..sort();
      roots.add(ordered.first);
    }
    final result = <String, MapPoint>{};
    final visited = <String>{};
    int leafCount(String id, Set<String> path) {
      if (!path.add(id)) return 1;
      final descendants = children[id]!.where((child) => !path.contains(child));
      final count = descendants.fold<int>(
        0,
        (sum, child) => sum + leafCount(child, {...path}),
      );
      return math.max(1, count);
    }

    var cursor = 0.0;
    double placeLinear(String id, int depth) {
      if (!visited.add(id)) return cursor;
      final descendants = children[id]!.where(
        (child) => !visited.contains(child),
      );
      final rows = <double>[];
      for (final child in descendants) {
        rows.add(placeLinear(child, depth + 1));
      }
      final row = rows.isEmpty ? cursor++ : (rows.first + rows.last) / 2;
      result[id] = layout == MapLayout.horizontal
          ? MapPoint((rtl ? -1 : 1) * depth * spacing, row * spacing)
          : MapPoint(row * spacing, depth * spacing);
      return row;
    }

    if (layout == MapLayout.horizontal || layout == MapLayout.vertical) {
      for (final root in roots) {
        placeLinear(root, 0);
        cursor += 1;
      }
      for (final id in nodes.keys.toList()..sort()) {
        if (!visited.contains(id)) placeLinear(id, 0);
      }
      final extent = math.max(0, cursor - 2) * spacing / 2;
      return Map.unmodifiable({
        for (final entry in result.entries)
          entry.key: layout == MapLayout.horizontal
              ? MapPoint(entry.value.x, entry.value.y - extent)
              : MapPoint(entry.value.x - extent, entry.value.y),
      });
    }

    if (layout == MapLayout.tree) {
      var rootOffset = 0.0;
      void branch(String id, int depth, int side, double row) {
        if (!visited.add(id)) return;
        result[id] = MapPoint(side * depth * spacing, row * spacing);
        final descendants = children[id]!
            .where((child) => !visited.contains(child))
            .toList();
        if (descendants.isEmpty) return;
        var leafCursor =
            row -
            descendants.fold<int>(
                  0,
                  (sum, child) => sum + leafCount(child, {}),
                ) /
                2;
        for (final child in descendants) {
          final weight = leafCount(child, {}).toDouble();
          final center = leafCursor + weight / 2;
          branch(child, depth + 1, side, center);
          leafCursor += weight;
        }
      }

      for (final root in roots) {
        if (!visited.add(root)) continue;
        result[root] = MapPoint(0, rootOffset * spacing);
        final descendants = children[root]!.toList();
        final left = <String>[];
        final right = <String>[];
        for (var i = 0; i < descendants.length; i++) {
          (i.isEven ? right : left).add(descendants[i]);
        }
        for (final (side, list) in [
          (rtl ? -1 : 1, right),
          (rtl ? 1 : -1, left),
        ]) {
          var row =
              rootOffset -
              list.fold<int>(0, (sum, child) => sum + leafCount(child, {})) / 2;
          for (final child in list) {
            final weight = leafCount(child, {}).toDouble();
            branch(child, 1, side, row + weight / 2);
            row += weight;
          }
        }
        rootOffset += math.max(3, leafCount(root, {})) + 2;
      }
      for (final id in nodes.keys.toList()..sort()) {
        if (!visited.contains(id)) branch(id, 0, 1, rootOffset++);
      }
      return Map.unmodifiable(result);
    }

    var centerX = 0.0;
    void radial(
      String id,
      int depth,
      double start,
      double sweep,
      double originX,
    ) {
      if (!visited.add(id)) return;
      final angle = start + sweep / 2;
      result[id] = depth == 0
          ? MapPoint(originX, 0)
          : MapPoint(
              originX + math.cos(angle) * depth * spacing,
              math.sin(angle) * depth * spacing,
            );
      final descendants = children[id]!
          .where((child) => !visited.contains(child))
          .toList();
      final total = descendants.fold<int>(
        0,
        (sum, child) => sum + leafCount(child, {}),
      );
      var sector = start;
      for (final child in descendants) {
        final arc = sweep * leafCount(child, {}) / total;
        radial(child, depth + 1, sector, arc, originX);
        sector += arc;
      }
    }

    for (final root in roots) {
      radial(root, 0, -math.pi, 2 * math.pi, centerX);
      centerX += spacing * (2 * _maxDepth(root, children, {}) + 3);
    }
    for (final id in nodes.keys.toList()..sort()) {
      if (!visited.contains(id)) {
        radial(id, 0, -math.pi, 2 * math.pi, centerX);
        centerX += 3 * spacing;
      }
    }
    return Map.unmodifiable(result);
  }

  static int _maxDepth(
    String id,
    Map<String, List<String>> children,
    Set<String> path,
  ) {
    if (!path.add(id)) return 0;
    var depth = 0;
    for (final child in children[id] ?? const <String>[]) {
      depth = math.max(depth, 1 + _maxDepth(child, children, {...path}));
    }
    return depth;
  }
}
