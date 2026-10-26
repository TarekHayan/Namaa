import 'package:flutter/material.dart';
import 'package:namma_project/app/theme/app_select_field.dart';

import '../domain/mind_map.dart';
import 'mind_maps_strings.dart';

const mapNodeShapes = [
  MapNodeShape.roundedRectangle,
  MapNodeShape.rectangle,
  MapNodeShape.circle,
  MapNodeShape.pill,
  MapNodeShape.glass,
];
const mapNodeIcons = [
  'target',
  'book',
  'code',
  'sparkles',
  'star',
  'lightbulb',
  'flag',
  'compass',
  'layers',
  'briefcase',
  'heart',
  'zap',
  'folder',
  'award',
  'rocket',
  'coffee',
];
const mapColors = [
  0xff10b981, // emerald
  0xff059669, // forest
  0xff84cc16, // sage
  0xff14b8a6, // mint
  0xff06b6d4, // teal
  0xff3b82f6, // blue
  0xffa855f7, // purple
  0xfff59e0b, // amber
  0xfff43f5e, // rose
  0xff94a3b8, // neutral
];

IconData mapIcon(String id) => switch (id) {
  'target' => Icons.track_changes_outlined,
  'book' => Icons.menu_book_outlined,
  'code' => Icons.code_rounded,
  'sparkles' => Icons.auto_awesome_outlined,
  'task' => Icons.check_box_outlined,
  'note' => Icons.sticky_note_2_outlined,
  'star' => Icons.star_outline,
  'lightbulb' => Icons.lightbulb_outline,
  'flag' => Icons.flag_outlined,
  'compass' => Icons.explore_outlined,
  'layers' => Icons.layers_outlined,
  'briefcase' => Icons.work_outline_rounded,
  'heart' => Icons.favorite_border_rounded,
  'zap' => Icons.bolt_outlined,
  'folder' => Icons.folder_outlined,
  'award' => Icons.workspace_premium_outlined,
  'rocket' => Icons.rocket_launch_outlined,
  'coffee' => Icons.local_cafe_outlined,
  'none' => Icons.block_outlined,
  _ => Icons.lightbulb_outline,
};

String mapIconName(String id, bool isRtl, MindMapsStrings strings) =>
    switch (id) {
      'target' => isRtl ? 'هدف' : 'Target',
      'book' => isRtl ? 'دراسة' : 'Book',
      'code' => isRtl ? 'برمجة' : 'Code',
      'sparkles' => isRtl ? 'إبداع' : 'Sparkles',
      'star' => strings.iconStar,
      'lightbulb' || 'idea' => strings.iconIdea,
      'flag' => strings.iconFlag,
      'compass' => isRtl ? 'توجيه' : 'Compass',
      'layers' => isRtl ? 'طبقات' : 'Layers',
      'briefcase' => isRtl ? 'عمل' : 'Work',
      'heart' => isRtl ? 'صحة' : 'Health',
      'zap' => isRtl ? 'طاقة' : 'Energy',
      'folder' => isRtl ? 'ملف' : 'Folder',
      'award' => isRtl ? 'إنجاز' : 'Award',
      'rocket' => isRtl ? 'إطلاق' : 'Rocket',
      'coffee' => isRtl ? 'استراحة' : 'Coffee',
      'task' => strings.iconTask,
      'note' => strings.iconNote,
      'none' => isRtl ? 'بدون أيقونة' : 'No icon',
      _ => id,
    };

String mapColorName(int argb, bool isRtl) => switch (argb) {
  0xff10b981 => isRtl ? 'زمردي' : 'Emerald',
  0xff059669 => isRtl ? 'غابي' : 'Forest',
  0xff84cc16 => isRtl ? 'مريمية' : 'Sage',
  0xff14b8a6 => isRtl ? 'نعناعي' : 'Mint',
  0xff06b6d4 => isRtl ? 'تركواز' : 'Teal',
  0xff3b82f6 => isRtl ? 'أزرق هادئ' : 'Blue',
  0xffa855f7 => isRtl ? 'بنفسجي' : 'Purple',
  0xfff59e0b => isRtl ? 'كهرماني' : 'Amber',
  0xfff43f5e => isRtl ? 'وردي' : 'Rose',
  0xff94a3b8 => isRtl ? 'حيادي شفاف' : 'Neutral Glass',
  _ => isRtl ? 'لون مخصص' : 'Custom color',
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return AppSelectField<int>(
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
                Text(
                  mapColors.contains(color)
                      ? mapColorName(color, isRtl)
                      : mapColorLabel(color, strings),
                ),
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
      AppSelectField<String>(
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
                  Text(
                    mapIconName(
                      icon,
                      Directionality.of(context) == TextDirection.rtl,
                      strings,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) _change(icon: value);
        },
      ),
      AppSelectField<MapNodeShape>(
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
        AppSelectField<MapSize>(
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
