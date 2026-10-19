import 'package:flutter/material.dart';

import '../domain/mind_map.dart';
import 'mind_maps_strings.dart';

const mapNodeShapes = [
  MapNodeShape.roundedRectangle,
  MapNodeShape.rectangle,
  MapNodeShape.circle,
  MapNodeShape.pill,
  MapNodeShape.glass,
];
const mapNodeIcons = ['idea', 'task', 'note', 'star', 'flag'];
const mapColors = [
  0xffffffff,
  0xffd9e8ff,
  0xffd9f5e5,
  0xffffedbd,
  0xffeedcff,
  0xff273449,
  0xff64748b,
];

IconData mapIcon(String id) => switch (id) {
  'task' => Icons.check_box_outlined,
  'note' => Icons.sticky_note_2_outlined,
  'star' => Icons.star_outline,
  'flag' => Icons.flag_outlined,
  _ => Icons.lightbulb_outline,
};

String mapShapeLabel(MapNodeShape shape, MindMapsStrings strings) =>
    switch (shape) {
      MapNodeShape.rectangle => strings.shapeRectangle,
      MapNodeShape.roundedRectangle => strings.shapeRounded,
      MapNodeShape.circle || MapNodeShape.ellipse => strings.shapeCircle,
      MapNodeShape.pill => strings.shapePill,
      MapNodeShape.glass => strings.shapeGlass,
      MapNodeShape.diamond || MapNodeShape.hexagon => strings.shapeRounded,
    };

String mapSizeLabel(MapSize size, MindMapsStrings strings) => switch (size) {
  MapSize.small => strings.sizeSmall,
  MapSize.medium => strings.sizeMedium,
  MapSize.large => strings.sizeLarge,
};

String mapColorLabel(int argb, MindMapsStrings strings) => switch (argb) {
  0xffffffff => strings.colorWhite,
  0xffd9e8ff => strings.colorBlue,
  0xffd9f5e5 => strings.colorGreen,
  0xffffedbd => strings.colorAmber,
  0xffeedcff => strings.colorPurple,
  0xff273449 => strings.colorDark,
  _ => strings.colorCurrent,
};

class MapColorField extends StatelessWidget {
  const MapColorField({
    super.key,
    required this.label,
    required this.value,
    required this.strings,
    required this.onChanged,
  });

  final String label;
  final int value;
  final MindMapsStrings strings;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = <int>{...mapColors, value};
    return DropdownButtonFormField<int>(
      key: ValueKey('color-$label-$value'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final color in colors)
          DropdownMenuItem(
            value: color,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(color)),
                const SizedBox(width: 8),
                Text(mapColorLabel(color, strings)),
              ],
            ),
          ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class MapAppearanceFields extends StatelessWidget {
  const MapAppearanceFields({
    super.key,
    required this.appearance,
    required this.strings,
    required this.onChanged,
  });

  final MapNodeAppearance appearance;
  final MindMapsStrings strings;
  final ValueChanged<MapNodeAppearance> onChanged;

  void _change({
    int? argb,
    String? icon,
    MapNodeShape? shape,
    MapSize? nodeSize,
    MapSize? textSize,
  }) => onChanged(
    MapNodeAppearance(
      argb: argb ?? appearance.argb,
      icon: icon ?? appearance.icon,
      shape: shape ?? appearance.shape,
      nodeSize: nodeSize ?? appearance.nodeSize,
      textSize: textSize ?? appearance.textSize,
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      MapColorField(
        label: strings.nodeColor,
        value: appearance.argb,
        strings: strings,
        onChanged: (value) => _change(argb: value),
      ),
      DropdownButtonFormField<String>(
        key: ValueKey('icon-${appearance.icon}'),
        initialValue: appearance.icon,
        decoration: InputDecoration(labelText: strings.nodeIcon),
        items: [
          for (final icon in {...mapNodeIcons, appearance.icon})
            DropdownMenuItem(
              value: icon,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(mapIcon(icon)),
                  const SizedBox(width: 8),
                  Text(switch (icon) {
                    'task' => strings.iconTask,
                    'note' => strings.iconNote,
                    'star' => strings.iconStar,
                    'flag' => strings.iconFlag,
                    _ => strings.iconIdea,
                  }),
                ],
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) _change(icon: value);
        },
      ),
      DropdownButtonFormField<MapNodeShape>(
        key: ValueKey('shape-${appearance.shape.name}'),
        initialValue: appearance.shape,
        decoration: InputDecoration(labelText: strings.nodeShape),
        items: [
          for (final shape in {...mapNodeShapes, appearance.shape})
            DropdownMenuItem(
              value: shape,
              child: Text(mapShapeLabel(shape, strings)),
            ),
        ],
        onChanged: (value) {
          if (value != null) _change(shape: value);
        },
      ),
      for (final (label, selected, update) in [
        (strings.nodeSize, appearance.nodeSize, true),
        (strings.textSize, appearance.textSize, false),
      ])
        DropdownButtonFormField<MapSize>(
          key: ValueKey('size-$label-${selected.name}'),
          initialValue: selected,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final size in MapSize.values)
              DropdownMenuItem(
                value: size,
                child: Text(mapSizeLabel(size, strings)),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              update ? _change(nodeSize: value) : _change(textSize: value);
            }
          },
        ),
    ],
  );
}
