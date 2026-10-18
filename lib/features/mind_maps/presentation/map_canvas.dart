import 'package:flutter/material.dart';

import '../application/map_repository.dart';
import '../domain/mind_map_node.dart';

const Key kMindMapCanvasKey = Key('mind_map_canvas');

class MapCanvas extends StatefulWidget {
  const MapCanvas({
    super.key,
    required this.graph,
    required this.selectedId,
    required this.onSelect,
  });

  final MapGraph graph;
  final String selectedId;
  final ValueChanged<String> onSelect;

  static const double width = 1200;
  static const double height = 800;
  static const double nodeWidth = 156;
  static const double nodeHeight = 72;

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  final TransformationController _transform = TransformationController();
  bool _positioned = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!_positioned && constraints.maxWidth.isFinite) {
        _positioned = true;
        _transform.value = Matrix4.translationValues(
          constraints.maxWidth / 2 - MapCanvas.width / 2,
          180 - MapCanvas.height / 2,
          0,
        );
      }
      return Container(
        key: kMindMapCanvasKey,
        height: 360,
        color: Color(widget.graph.map.settings.backgroundArgb),
        child: InteractiveViewer(
          transformationController: _transform,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(400),
          minScale: 0.25,
          maxScale: 3,
          child: SizedBox(
            width: MapCanvas.width,
            height: MapCanvas.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _EdgePainter(widget.graph)),
                ),
                for (final node in widget.graph.nodes)
                  Positioned(
                    left:
                        MapCanvas.width / 2 + node.x - MapCanvas.nodeWidth / 2,
                    top:
                        MapCanvas.height / 2 +
                        node.y -
                        MapCanvas.nodeHeight / 2,
                    width: MapCanvas.nodeWidth,
                    height: MapCanvas.nodeHeight,
                    child: _NodeTile(
                      node: node,
                      selected: node.id == widget.selectedId,
                      onTap: () => widget.onSelect(node.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.node,
    required this.selected,
    required this.onTap,
  });
  final MindMapNode node;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Color(node.appearance.argb),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
        width: selected ? 3 : 1,
      ),
    ),
    elevation: selected ? 5 : 1,
    child: InkWell(
      key: ValueKey('mind-map-canvas-node-${node.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              node.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (node.status == MindMapNodeStatus.completed)
              const Icon(Icons.check_circle, size: 16),
          ],
        ),
      ),
    ),
  );
}

final class _EdgePainter extends CustomPainter {
  _EdgePainter(this.graph);
  final MapGraph graph;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = {
      for (final node in graph.nodes)
        node.id: Offset(size.width / 2 + node.x, size.height / 2 + node.y),
    };
    for (final slot in graph.parentSlots) {
      final from = positions[slot.parentNodeId];
      final to = positions[slot.childNodeId];
      if (from == null || to == null) continue;
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = Color(slot.appearance.argb)
          ..strokeWidth = slot.appearance.width
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final link in graph.sideLinks) {
      final from = positions[link.firstNodeId];
      final to = positions[link.secondNodeId];
      if (from == null || to == null) continue;
      final paint = Paint()
        ..color = Color(link.appearance.argb).withValues(alpha: 0.7)
        ..strokeWidth = link.appearance.width
        ..strokeCap = StrokeCap.round;
      final delta = to - from;
      final length = delta.distance;
      if (length == 0) continue;
      final unit = delta / length;
      for (var distance = 0.0; distance < length; distance += 14) {
        canvas.drawLine(
          from + unit * distance,
          from + unit * (distance + 7).clamp(0, length),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) =>
      !identical(oldDelegate.graph, graph);
}
