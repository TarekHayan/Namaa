import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/map_queries.dart';
import '../application/map_repository.dart';
import '../application/map_task_link_port.dart';
import '../domain/mind_map.dart';
import '../domain/mind_map_node.dart';
import 'map_appearance_fields.dart';
import 'mind_maps_strings.dart';

const Key kMindMapCanvasKey = Key('mind_map_canvas');
const Key kMindMapFitKey = Key('mind_map_fit');
const Key kMindMapCenterKey = Key('mind_map_center');
const Key kMindMapZoomInKey = Key('mind_map_zoom_in');
const Key kMindMapZoomOutKey = Key('mind_map_zoom_out');

class MapCanvas extends StatefulWidget {
  const MapCanvas({
    super.key,
    required this.graph,
    required this.selectedId,
    required this.onSelect,
    required this.onMove,
    required this.strings,
    this.linkedTasks = const {},
  });

  final MapGraph graph;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final Future<bool> Function(String id, double x, double y) onMove;
  final MindMapsStrings strings;
  final Map<String, MapLinkedTask> linkedTasks;

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  final TransformationController _transform = TransformationController();
  final FocusNode _focus = FocusNode(debugLabel: 'Mind map canvas');
  Size _viewport = Size.zero;
  _Scene _scene = _Scene.empty();
  bool _positioned = false;
  String? _draggingId;
  Offset _dragDelta = Offset.zero;

  @override
  void didUpdateWidget(covariant MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldOrigin = _scene.origin;
    final nextScene = _Scene(widget.graph);
    final shift = oldOrigin - nextScene.origin;
    if (_positioned && shift != Offset.zero) {
      final scale = _transform.value.getMaxScaleOnAxis();
      _pan(shift * scale);
    }
    _scene = nextScene;
    if (oldWidget.graph.map.settings.layout !=
            widget.graph.map.settings.layout ||
        oldWidget.graph.map.settings.spacing !=
            widget.graph.map.settings.spacing) {
      _positioned = false;
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    _focus.dispose();
    super.dispose();
  }

  Matrix4 _matrix(double scale, double tx, double ty) =>
      Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(tx, ty, 0);

  void _fit() {
    if (_viewport.isEmpty) return;
    final content = _scene.content.inflate(80);
    final scale = math
        .min(_viewport.width / content.width, _viewport.height / content.height)
        .clamp(0.2, 3.0)
        .toDouble();
    _transform.value = _matrix(
      scale,
      _viewport.width / 2 - content.center.dx * scale,
      _viewport.height / 2 - content.center.dy * scale,
    );
  }

  void _center() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final center = _scene.content.center;
    _transform.value = _matrix(
      scale,
      _viewport.width / 2 - center.dx * scale,
      _viewport.height / 2 - center.dy * scale,
    );
  }

  void _zoom(double factor) {
    final next = (_transform.value.getMaxScaleOnAxis() * factor)
        .clamp(0.2, 3.0)
        .toDouble();
    final focal = Offset(_viewport.width / 2, _viewport.height / 2);
    final world = _transform.toScene(focal);
    _transform.value = _matrix(
      next,
      focal.dx - world.dx * next,
      focal.dy - world.dy * next,
    );
  }

  void _pan(Offset delta) {
    final matrix = _transform.value.clone();
    matrix.setTranslationRaw(
      matrix.entry(0, 3) + delta.dx,
      matrix.entry(1, 3) + delta.dy,
      0,
    );
    _transform.value = matrix;
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) _pan(const Offset(60, 0));
    if (key == LogicalKeyboardKey.arrowRight) _pan(const Offset(-60, 0));
    if (key == LogicalKeyboardKey.arrowUp) _pan(const Offset(0, 60));
    if (key == LogicalKeyboardKey.arrowDown) _pan(const Offset(0, -60));
    if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add) {
      _zoom(1.25);
    }
    if (key == LogicalKeyboardKey.minus) {
      _zoom(0.8);
    }
    if (key == LogicalKeyboardKey.keyF) _fit();
    if (key == LogicalKeyboardKey.keyC) _center();
    return {
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.equal,
          LogicalKeyboardKey.add,
          LogicalKeyboardKey.minus,
          LogicalKeyboardKey.keyF,
          LogicalKeyboardKey.keyC,
        }.contains(key)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  void _endDrag(MindMapNode node) {
    final delta = _dragDelta;
    setState(() {
      _draggingId = null;
      _dragDelta = Offset.zero;
    });
    if (delta.distanceSquared > 1) {
      widget.onMove(node.id, node.x + delta.dx, node.y + delta.dy);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _viewport = Size(constraints.maxWidth, 360);
      _scene = _Scene(widget.graph);
      if (!_positioned && constraints.maxWidth.isFinite) {
        _positioned = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fit();
        });
      }
      return Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        child: Semantics(
          container: true,
          label: widget.strings.keyboardHelp,
          child: SizedBox(
            key: kMindMapCanvasKey,
            height: 360,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Color(widget.graph.map.settings.backgroundArgb),
                    child: InteractiveViewer(
                      transformationController: _transform,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(100000),
                      minScale: 0.2,
                      maxScale: 3,
                      child: SizedBox(
                        width: _scene.width,
                        height: _scene.height,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: _EdgePainter(widget.graph, _scene),
                                ),
                              ),
                            ),
                            for (final node in _scene.nodes)
                              Positioned(
                                left:
                                    _scene.point(node).dx -
                                    _nodeHalfWidth(node.appearance),
                                top:
                                    _scene.point(node).dy -
                                    _nodeHalfHeight(node.appearance),
                                width: _nodeHalfWidth(node.appearance) * 2,
                                height: _nodeHalfHeight(node.appearance) * 2,
                                child: GestureDetector(
                                  onPanStart: (_) {
                                    widget.onSelect(node.id);
                                    setState(() {
                                      _draggingId = node.id;
                                      _dragDelta = Offset.zero;
                                    });
                                  },
                                  onPanUpdate: (details) => setState(() {
                                    _dragDelta +=
                                        details.delta /
                                        _transform.value.getMaxScaleOnAxis();
                                  }),
                                  onPanEnd: (_) => _endDrag(node),
                                  child: Transform.translate(
                                    offset: _draggingId == node.id
                                        ? _dragDelta
                                        : Offset.zero,
                                    child: _NodeTile(
                                      node: node,
                                      strings: widget.strings,
                                      selected: node.id == widget.selectedId,
                                      completed:
                                          MapQueries.visibleStatus(
                                            node,
                                            widget.linkedTasks,
                                          ) ==
                                          MindMapNodeStatus.completed,
                                      onTap: () => widget.onSelect(node.id),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 4,
                  end: 4,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: kMindMapZoomInKey,
                          tooltip: widget.strings.zoomIn,
                          onPressed: () => _zoom(1.25),
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          key: kMindMapZoomOutKey,
                          tooltip: widget.strings.zoomOut,
                          onPressed: () => _zoom(0.8),
                          icon: const Icon(Icons.remove),
                        ),
                        IconButton(
                          key: kMindMapFitKey,
                          tooltip: widget.strings.fit,
                          onPressed: _fit,
                          icon: const Icon(Icons.fit_screen),
                        ),
                        IconButton(
                          key: kMindMapCenterKey,
                          tooltip: widget.strings.center,
                          onPressed: _center,
                          icon: const Icon(Icons.center_focus_strong),
                        ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 4,
                  bottom: 4,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: widget.strings.panLeft,
                          onPressed: () => _pan(const Offset(60, 0)),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        IconButton(
                          tooltip: widget.strings.panRight,
                          onPressed: () => _pan(const Offset(-60, 0)),
                          icon: const Icon(Icons.arrow_forward),
                        ),
                        IconButton(
                          tooltip: widget.strings.panUp,
                          onPressed: () => _pan(const Offset(0, 60)),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          tooltip: widget.strings.panDown,
                          onPressed: () => _pan(const Offset(0, -60)),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                      ],
                    ),
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

double _nodeHalfWidth(MapNodeAppearance appearance) =>
    switch (appearance.nodeSize) {
      MapSize.small => 60,
      MapSize.medium => 78,
      MapSize.large => 100,
    };

double _nodeHalfHeight(MapNodeAppearance appearance) =>
    appearance.shape == MapNodeShape.circle ||
        appearance.shape == MapNodeShape.ellipse
    ? _nodeHalfWidth(appearance)
    : switch (appearance.nodeSize) {
        MapSize.small => 30,
        MapSize.medium => 38,
        MapSize.large => 50,
      };

final class _Scene {
  _Scene.empty()
    : nodes = const [],
      origin = const Offset(600, 400),
      width = 1200,
      height = 800,
      content = const Rect.fromLTWH(500, 300, 200, 200);

  factory _Scene(MapGraph graph) {
    final nodes = graph.nodes.where((n) => !n.isDeleted).toList();
    if (nodes.isEmpty) return _Scene.empty();
    final minX = nodes
        .map((n) => n.x - _nodeHalfWidth(n.appearance))
        .reduce(math.min);
    final maxX = nodes
        .map((n) => n.x + _nodeHalfWidth(n.appearance))
        .reduce(math.max);
    final minY = nodes
        .map((n) => n.y - _nodeHalfHeight(n.appearance))
        .reduce(math.min);
    final maxY = nodes
        .map((n) => n.y + _nodeHalfHeight(n.appearance))
        .reduce(math.max);
    final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    final width = math.max(1200, bounds.width + 400).toDouble();
    final height = math.max(800, bounds.height + 400).toDouble();
    final origin = Offset(
      (width - bounds.width) / 2 - bounds.left,
      (height - bounds.height) / 2 - bounds.top,
    );
    return _Scene._(nodes, origin, width, height, bounds.shift(origin));
  }

  const _Scene._(
    this.nodes,
    this.origin,
    this.width,
    this.height,
    this.content,
  );

  final List<MindMapNode> nodes;
  final Offset origin;
  final double width;
  final double height;
  final Rect content;

  Offset point(MindMapNode node) => origin + Offset(node.x, node.y);
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.node,
    required this.strings,
    required this.selected,
    required this.completed,
    required this.onTap,
  });
  final MindMapNode node;
  final MindMapsStrings strings;
  final bool selected;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appearance = node.appearance;
    final foreground = Color(appearance.argb).computeLuminance() < 0.38
        ? Colors.white
        : Colors.black87;
    final border = BorderSide(
      color: selected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outline,
      width: selected ? 3 : 1,
    );
    final ShapeBorder shape = switch (appearance.shape) {
      MapNodeShape.rectangle => RoundedRectangleBorder(side: border),
      MapNodeShape.circle || MapNodeShape.ellipse => CircleBorder(side: border),
      MapNodeShape.pill => StadiumBorder(side: border),
      _ => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: border,
      ),
    };
    return Semantics(
      label: '${node.title}. ${strings.dragNode}',
      button: true,
      child: Material(
        color: Color(
          appearance.argb,
        ).withValues(alpha: appearance.shape == MapNodeShape.glass ? 0.55 : 1),
        shape: shape,
        elevation: selected ? 5 : 1,
        child: InkWell(
          key: ValueKey('mind-map-canvas-node-${node.id}'),
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mapIcon(appearance.icon), size: 16, color: foreground),
                Flexible(
                  child: Text(
                    node.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: Directionality.of(context),
                    style: TextStyle(
                      fontSize: switch (appearance.textSize) {
                        MapSize.small => 12,
                        MapSize.medium => 14,
                        MapSize.large => 18,
                      },
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
                if (completed)
                  Icon(Icons.check_circle, size: 16, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _EdgePainter extends CustomPainter {
  _EdgePainter(this.graph, this.scene);
  final MapGraph graph;
  final _Scene scene;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = {
      for (final node in scene.nodes) node.id: scene.point(node),
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
      !identical(oldDelegate.graph, graph) ||
      oldDelegate.scene.content != scene.content;
}
