import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namma_project/app/theme/app_colors.dart';

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
const Key kMindMapEdgesKey = Key('mind_map_edges');

class MapCanvas extends StatefulWidget {
  const MapCanvas({
    super.key,
    required this.graph,
    required this.selectedId,
    required this.onSelect,
    required this.onMove,
    this.onStatusTap,
    required this.strings,
    this.linkedTasks = const {},
    this.height = 360,
    this.controlsBottom = 12,
  });

  final MapGraph graph;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final Future<bool> Function(String id, double x, double y) onMove;
  final ValueChanged<MindMapNode>? onStatusTap;
  final MindMapsStrings strings;
  final Map<String, MapLinkedTask> linkedTasks;
  final double height;
  final double controlsBottom;

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
  Offset? _dropTarget;
  MapGraph? _sizedGraph;
  TextDirection? _sizedDirection;
  TextScaler? _sizedScaler;
  TextStyle? _sizedStyle;
  Map<String, Size> _nodeSizes = const {};

  Map<String, Size> _sizesForContext() {
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final style =
        Theme.of(context).textTheme.bodyMedium ??
        DefaultTextStyle.of(context).style;
    if (!identical(_sizedGraph, widget.graph) ||
        _sizedDirection != direction ||
        _sizedScaler != scaler ||
        _sizedStyle != style) {
      _sizedGraph = widget.graph;
      _sizedDirection = direction;
      _sizedScaler = scaler;
      _sizedStyle = style;
      _nodeSizes = {
        for (final node in widget.graph.nodes)
          if (!node.isDeleted)
            node.id: _nodeSize(node, direction, scaler, style),
      };
    }
    return _nodeSizes;
  }

  @override
  void didUpdateWidget(covariant MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final draggingId = _draggingId;
    final dropTarget = _dropTarget;
    if (draggingId != null && dropTarget != null) {
      for (final node in widget.graph.nodes) {
        if (node.id == draggingId &&
            (Offset(node.x, node.y) - dropTarget).distanceSquared < 0.01) {
          // The saved position replaces the temporary drag offset in one frame.
          _draggingId = null;
          _dragDelta = Offset.zero;
          _dropTarget = null;
          break;
        }
      }
    }
    final oldOrigin = _scene.origin;
    final nextScene = _Scene(widget.graph, _sizesForContext());
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
    final content = _scene.content.inflate(100);
    final scale = math
        .min(_viewport.width / content.width, _viewport.height / content.height)
        .clamp(0.2, 1.0)
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

  Future<void> _endDrag(MindMapNode node) async {
    final delta = _dragDelta;
    if (delta.distanceSquared <= 1) {
      setState(() {
        _draggingId = null;
        _dragDelta = Offset.zero;
      });
      return;
    }
    _dropTarget = Offset(node.x + delta.dx, node.y + delta.dy);
    try {
      await widget.onMove(node.id, _dropTarget!.dx, _dropTarget!.dy);
    } finally {
      if (mounted && _draggingId == node.id && _dropTarget != null) {
        setState(() {
          _draggingId = null;
          _dragDelta = Offset.zero;
          _dropTarget = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _viewport = Size(constraints.maxWidth, widget.height);
      _scene = _Scene(widget.graph, _sizesForContext());
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
            height: widget.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color:
                        widget.graph.map.settings.backgroundPattern ==
                            MapCanvasPattern.dark
                        ? AppColors.dark.surface
                        : widget.graph.map.settings.backgroundArgb == 0xffffffff
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.dark.background
                              : AppColors.light.surface)
                        : Color(widget.graph.map.settings.backgroundArgb),
                    child: CustomPaint(
                      painter: _CanvasPatternPainter(
                        widget.graph.map.settings.backgroundPattern,
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.dark.primary.withValues(alpha: 0.15)
                            : AppColors.light.primary.withValues(alpha: 0.10),
                      ),
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
                                    key: kMindMapEdgesKey,
                                    painter: _EdgePainter(
                                      widget.graph,
                                      _scene,
                                      _draggingId,
                                      _dragDelta,
                                    ),
                                  ),
                                ),
                              ),
                              for (final node in _scene.nodes)
                                Positioned(
                                  left:
                                      _scene.point(node).dx -
                                      _scene.sizeOf(node).width / 2,
                                  top:
                                      _scene.point(node).dy -
                                      _scene.sizeOf(node).height / 2,
                                  width: _scene.sizeOf(node).width,
                                  height: _scene.sizeOf(node).height,
                                  child: GestureDetector(
                                    onPanStart: (_) {
                                      widget.onSelect(node.id);
                                      setState(() {
                                        _draggingId = node.id;
                                        _dragDelta = Offset.zero;
                                        _dropTarget = null;
                                      });
                                    },
                                    onPanUpdate: (details) => setState(() {
                                      _dragDelta +=
                                          details.delta /
                                          _transform.value.getMaxScaleOnAxis();
                                    }),
                                    onPanEnd: (_) => unawaited(_endDrag(node)),
                                    onPanCancel: () => setState(() {
                                      _draggingId = null;
                                      _dragDelta = Offset.zero;
                                      _dropTarget = null;
                                    }),
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
                                        status: MapQueries.visibleStatus(
                                          node,
                                          widget.linkedTasks,
                                        ),
                                        onStatusTap: widget.onStatusTap == null
                                            ? null
                                            : () => widget.onStatusTap!(node),
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
                ),
                PositionedDirectional(
                  bottom: widget.controlsBottom,
                  end: 16,
                  child: Material(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.9),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
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
                        if (constraints.maxWidth >= 380)
                          IconButton(
                            key: kMindMapCenterKey,
                            tooltip: widget.strings.center,
                            onPressed: _center,
                            icon: const Icon(Icons.center_focus_strong),
                          ),
                        IconButton(
                          key: kMindMapFitKey,
                          tooltip: widget.strings.fit,
                          onPressed: _fit,
                          icon: const Icon(Icons.fit_screen),
                        ),
                        PopupMenuButton<Offset>(
                          tooltip: widget.strings.moveNode,
                          icon: const Icon(Icons.open_with_rounded),
                          onSelected: _pan,
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: const Offset(60, 0),
                              child: Text(widget.strings.panLeft),
                            ),
                            PopupMenuItem(
                              value: const Offset(-60, 0),
                              child: Text(widget.strings.panRight),
                            ),
                            PopupMenuItem(
                              value: const Offset(0, 60),
                              child: Text(widget.strings.panUp),
                            ),
                            PopupMenuItem(
                              value: const Offset(0, -60),
                              child: Text(widget.strings.panDown),
                            ),
                          ],
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

double _nodeFontSize(MapSize size) => switch (size) {
  MapSize.small => 11,
  MapSize.medium => 13,
  MapSize.large => 16,
};

double _nodeBadgeSize(MapSize size) => size == MapSize.small ? 20 : 24;

Size _measureNodeText(
  String text,
  TextStyle style,
  double width,
  TextDirection direction,
  TextScaler textScaler,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
    textScaler: textScaler,
  )..layout(maxWidth: width);
  final result = painter.size;
  painter.dispose();
  return result;
}

Size _nodeSize(
  MindMapNode node,
  TextDirection direction,
  TextScaler textScaler,
  TextStyle baseStyle,
) {
  final appearance = node.appearance;
  final titleStyle = baseStyle.copyWith(
    fontSize: _nodeFontSize(appearance.textSize),
    height: 1.15,
    fontWeight: FontWeight.w800,
  );
  final descriptionStyle = baseStyle.copyWith(fontSize: 10);
  final description = node.description ?? '';
  final naturalWidth = math.max(
    _measureNodeText(
      node.title,
      titleStyle,
      double.infinity,
      direction,
      textScaler,
    ).width,
    description.isEmpty
        ? 0
        : _measureNodeText(
            description,
            descriptionStyle,
            double.infinity,
            direction,
            textScaler,
          ).width,
  );
  double contentHeight(double width) {
    final titleHeight = _measureNodeText(
      node.title,
      titleStyle,
      width,
      direction,
      textScaler,
    ).height;
    if (description.isEmpty) {
      return titleHeight;
    }
    final descriptionHeight = _measureNodeText(
      description,
      descriptionStyle,
      width,
      direction,
      textScaler,
    ).height;
    return titleHeight + 3 + descriptionHeight;
  }

  final badge = _nodeBadgeSize(appearance.nodeSize);
  if (appearance.shape == MapNodeShape.circle ||
      appearance.shape == MapNodeShape.ellipse) {
    final circle = appearance.shape == MapNodeShape.circle;
    final baseDiameter = switch (appearance.nodeSize) {
      MapSize.small => 112.0,
      MapSize.medium => 144.0,
      MapSize.large => 176.0,
    };
    var width = math.max(
      circle ? baseDiameter : baseDiameter * 1.25,
      math.min(naturalWidth, 200.0) / (circle ? 0.64 : 0.66),
    );
    for (var attempt = 0; attempt < 8; attempt++) {
      final height = circle ? width : width * 0.78;
      final textWidth = math.min(width * (circle ? 0.64 : 0.66), 320.0);
      final textHeight = contentHeight(textWidth);
      // The centered text must clear the two controls near the upper rim.
      final neededHeight = math.max(
        textHeight + 2 * (badge + 8) + 0.22 * height,
        math.sqrt(textWidth * textWidth + textHeight * textHeight) + 24,
      );
      final nextWidth = math.max(
        width,
        circle ? neededHeight : neededHeight / 0.78,
      );
      if (nextWidth - width < 0.5) break;
      width = nextWidth;
    }
    return circle ? Size.square(width) : Size(width, width * 0.78);
  }

  final pill = appearance.shape == MapNodeShape.pill;
  final baseWidth = switch (appearance.nodeSize) {
    MapSize.small => 130.0,
    MapSize.medium => 170.0,
    MapSize.large => 210.0,
  };
  final horizontalSpace = pill ? 2 * (badge + 9) : 28.0;
  final width = math.max(
    baseWidth,
    math.min(naturalWidth + horizontalSpace, 380.0),
  );
  final textHeight = contentHeight(width - horizontalSpace);
  final baseHeight = switch (appearance.nodeSize) {
    MapSize.small => pill ? 44.0 : 64.0,
    MapSize.medium => pill ? 50.0 : 80.0,
    MapSize.large => pill ? 56.0 : 96.0,
  };
  final height = math.max(
    baseHeight,
    pill ? math.max(textHeight + 16, badge + 8) : textHeight + 2 * (badge + 11),
  );
  return Size(width, height);
}

final class _Scene {
  _Scene.empty()
    : nodes = const [],
      sizes = const {},
      origin = const Offset(600, 400),
      width = 1200,
      height = 800,
      content = const Rect.fromLTWH(500, 300, 200, 200);

  factory _Scene(MapGraph graph, Map<String, Size> sizes) {
    final nodes = graph.nodes.where((n) => !n.isDeleted).toList();
    if (nodes.isEmpty) return _Scene.empty();
    final minX = nodes
        .map((n) => n.x - sizes[n.id]!.width / 2)
        .reduce(math.min);
    final maxX = nodes
        .map((n) => n.x + sizes[n.id]!.width / 2)
        .reduce(math.max);
    final minY = nodes
        .map((n) => n.y - sizes[n.id]!.height / 2)
        .reduce(math.min);
    final maxY = nodes
        .map((n) => n.y + sizes[n.id]!.height / 2)
        .reduce(math.max);
    final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    final width = math.max(1200, bounds.width + 400).toDouble();
    final height = math.max(800, bounds.height + 400).toDouble();
    final origin = Offset(
      (width - bounds.width) / 2 - bounds.left,
      (height - bounds.height) / 2 - bounds.top,
    );
    return _Scene._(nodes, sizes, origin, width, height, bounds.shift(origin));
  }

  const _Scene._(
    this.nodes,
    this.sizes,
    this.origin,
    this.width,
    this.height,
    this.content,
  );

  final List<MindMapNode> nodes;
  final Map<String, Size> sizes;
  final Offset origin;
  final double width;
  final double height;
  final Rect content;

  Offset point(MindMapNode node) => origin + Offset(node.x, node.y);
  Size sizeOf(MindMapNode node) => sizes[node.id]!;
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.node,
    required this.strings,
    required this.selected,
    required this.completed,
    required this.status,
    this.onStatusTap,
    required this.onTap,
  });
  final MindMapNode node;
  final MindMapsStrings strings;
  final bool selected;
  final bool completed;
  final MindMapNodeStatus? status;
  final VoidCallback? onStatusTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appearance = node.appearance;
    final accent = Color(appearance.argb);
    final theme = Theme.of(context);
    final colors = theme.brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final foreground = colors.textPrimary;
    final readableAccent =
        theme.brightness == Brightness.light && accent.computeLuminance() > 0.65
        ? HSLColor.fromColor(accent).withLightness(0.38).toColor()
        : accent;
    final border = BorderSide(
      color: selected ? colors.primary : readableAccent.withValues(alpha: 0.65),
      width: selected ? 2.4 : 1.5,
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
    final isGlass = appearance.shape == MapNodeShape.glass;
    final isRound =
        appearance.shape == MapNodeShape.circle ||
        appearance.shape == MapNodeShape.ellipse;
    final isPill = appearance.shape == MapNodeShape.pill;
    final badgeSize = _nodeBadgeSize(appearance.nodeSize);
    final textStyle =
        theme.textTheme.bodyMedium ?? DefaultTextStyle.of(context).style;
    final tile = InkWell(
      key: ValueKey('mind-map-canvas-node-${node.id}'),
      customBorder: shape,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final inset = isRound ? width * 0.22 : 7.0;
          final badgeTop = isPill
              ? (height - badgeSize) / 2
              : isRound
              ? height * 0.11
              : 3.0;
          return Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: isRound
                        ? math.min(
                            width *
                                (appearance.shape == MapNodeShape.circle
                                    ? 0.64
                                    : 0.66),
                            320,
                          )
                        : width - (isPill ? 2 * (badgeSize + 9) : 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          node.title,
                          textAlign: TextAlign.center,
                          style: textStyle.copyWith(
                            fontSize: _nodeFontSize(appearance.textSize),
                            height: 1.15,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                            fontWeight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                        if (node.description?.isNotEmpty ?? false)
                          Text(
                            node.description!,
                            textAlign: TextAlign.center,
                            style: textStyle.copyWith(
                              fontSize: 10,
                              color: foreground.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: badgeTop,
                start: inset,
                end: inset,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (onStatusTap != null)
                      GestureDetector(
                        key: ValueKey('mind-map-node-status-badge-${node.id}'),
                        onTap: onStatusTap,
                        child: SizedBox(
                          width: badgeSize,
                          height: badgeSize,
                          child: Icon(
                            status == MindMapNodeStatus.completed
                                ? Icons.check_circle_rounded
                                : status == MindMapNodeStatus.inProgress
                                ? Icons.access_time_filled_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: badgeSize - 5,
                            color: status == MindMapNodeStatus.completed
                                ? theme.colorScheme.primary
                                : foreground.withValues(alpha: 0.55),
                          ),
                        ),
                      )
                    else
                      SizedBox(width: badgeSize),
                    if (appearance.icon == 'none')
                      SizedBox(width: badgeSize)
                    else
                      Container(
                        key: ValueKey('mind-map-node-icon-badge-${node.id}'),
                        width: badgeSize,
                        height: badgeSize,
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.09)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          mapIcon(appearance.icon),
                          size: badgeSize - 8,
                          color: foreground,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return Semantics(
      label: '${node.title}. ${strings.dragNode}',
      button: true,
      child: Material(
        color: isGlass
            ? Colors.transparent
            : Color.alphaBlend(
                accent.withValues(alpha: 0.13),
                theme.colorScheme.surface,
              ),
        shape: shape,
        elevation: selected ? 8 : 2,
        shadowColor: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.45)
            : Colors.black26,
        child: isGlass
            ? ClipPath(
                clipper: ShapeBorderClipper(shape: shape),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
                  child: ColoredBox(
                    color: accent.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.08 : 0.06,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.06
                                  : 0.18,
                            ),
                            Colors.white.withValues(alpha: 0.01),
                          ],
                        ),
                      ),
                      child: tile,
                    ),
                  ),
                ),
              )
            : tile,
      ),
    );
  }
}

final class _CanvasPatternPainter extends CustomPainter {
  const _CanvasPatternPainter(this.pattern, this.color);
  final MapCanvasPattern pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == MapCanvasPattern.plain || pattern == MapCanvasPattern.dark) {
      return;
    }
    final paint = Paint()..color = color;
    if (pattern == MapCanvasPattern.grid) {
      for (var x = 14.0; x < size.width; x += 28) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (var y = 14.0; y < size.height; y += 28) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      return;
    }
    final spacing = pattern == MapCanvasPattern.dots ? 24.0 : 28.0;
    final radius = pattern == MapCanvasPattern.dots ? 1.5 : 1.0;
    for (var x = spacing / 2; x < size.width; x += spacing) {
      for (var y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pattern != pattern;
}

final class _EdgePainter extends CustomPainter {
  _EdgePainter(this.graph, this.scene, this.draggingId, this.dragDelta);
  final MapGraph graph;
  final _Scene scene;
  final String? draggingId;
  final Offset dragDelta;

  Offset _nodeCenter(MindMapNode node) =>
      scene.point(node) + (node.id == draggingId ? dragDelta : Offset.zero);

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = {for (final node in scene.nodes) node.id: node};
    for (final slot in graph.parentSlots) {
      final from = nodes[slot.parentNodeId];
      final to = nodes[slot.childNodeId];
      if (from == null || to == null) continue;
      _drawConnection(canvas, from, to, slot.appearance);
    }
    for (final link in graph.sideLinks) {
      final from = nodes[link.firstNodeId];
      final to = nodes[link.secondNodeId];
      if (from == null || to == null) continue;
      _drawConnection(canvas, from, to, link.appearance, side: true);
    }
  }

  void _drawConnection(
    Canvas canvas,
    MindMapNode from,
    MindMapNode to,
    MapConnectionAppearance appearance, {
    bool side = false,
  }) {
    final fromCenter = _nodeCenter(from);
    final toCenter = _nodeCenter(to);
    final start = _boundary(fromCenter, toCenter, from);
    final end = _boundary(toCenter, fromCenter, to);
    final delta = end - start;
    final curve = Path()..moveTo(start.dx, start.dy);
    final layout = graph.map.settings.layout;
    if (layout == MapLayout.horizontal) {
      curve.cubicTo(
        start.dx + delta.dx * 0.5,
        start.dy,
        start.dx + delta.dx * 0.5,
        end.dy,
        end.dx,
        end.dy,
      );
    } else if (layout == MapLayout.tree || layout == MapLayout.vertical) {
      curve.cubicTo(
        start.dx,
        start.dy + delta.dy * 0.5,
        end.dx,
        start.dy + delta.dy * 0.5,
        end.dx,
        end.dy,
      );
    } else {
      final factor = math.min(
        0.35,
        math.max(0.12, 35 / math.max(1, delta.distance)),
      );
      curve.cubicTo(
        start.dx + delta.dx * factor,
        start.dy + delta.dy * factor,
        end.dx - delta.dx * factor,
        end.dy - delta.dy * factor,
        end.dx,
        end.dy,
      );
    }
    // Maps created before the prototype palette stored slate as their default.
    // Keep explicitly configured edge colors, but show that legacy default in
    // the current emerald theme.
    final legacyDefault =
        appearance.argb == 0xff64748b &&
        graph.map.settings.defaultConnection.argb == 0xff64748b;
    final color = Color(legacyDefault ? 0xff10b981 : appearance.argb);
    canvas.drawPath(
      curve,
      Paint()
        ..color = color.withValues(alpha: side ? 0.22 : 0.38)
        ..strokeWidth = appearance.width + 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5)
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      curve,
      Paint()
        ..color = color.withValues(alpha: side ? 0.12 : 0.22)
        ..strokeWidth = appearance.width + 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    final paint = Paint()
      ..color = color.withValues(alpha: side ? 0.75 : 1)
      ..strokeWidth = appearance.width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final pattern = side && appearance.pattern == MapLinePattern.solid
        ? MapLinePattern.dashed
        : appearance.pattern;
    if (pattern == MapLinePattern.solid) {
      canvas.drawPath(curve, paint);
    } else {
      final draw = pattern == MapLinePattern.dashed ? 7.0 : 2.0;
      final gap = pattern == MapLinePattern.dashed ? 5.0 : 4.0;
      for (final metric in curve.computeMetrics()) {
        for (
          var distance = 0.0;
          distance < metric.length;
          distance += draw + gap
        ) {
          canvas.drawPath(
            metric.extractPath(
              distance,
              math.min(distance + draw, metric.length),
            ),
            paint,
          );
        }
      }
    }
  }

  Offset _boundary(Offset center, Offset target, MindMapNode node) {
    final delta = target - center;
    if (delta.distanceSquared < 0.01) return center;
    final size = scene.sizeOf(node);
    final hw = size.width / 2;
    final hh = size.height / 2;
    if (node.appearance.shape == MapNodeShape.circle ||
        node.appearance.shape == MapNodeShape.ellipse) {
      final ratio = math.sqrt(
        delta.dx * delta.dx / (hw * hw) + delta.dy * delta.dy / (hh * hh),
      );
      return center + delta / ratio;
    }
    final factor = math.min(
      delta.dx.abs() < 0.001 ? double.infinity : hw / delta.dx.abs(),
      delta.dy.abs() < 0.001 ? double.infinity : hh / delta.dy.abs(),
    );
    return center + delta * factor;
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) =>
      !identical(oldDelegate.graph, graph) ||
      oldDelegate.scene.content != scene.content ||
      oldDelegate.draggingId != draggingId ||
      oldDelegate.dragDelta != dragDelta;
}
