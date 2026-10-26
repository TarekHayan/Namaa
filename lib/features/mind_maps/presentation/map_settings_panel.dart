import 'package:flutter/material.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_select_field.dart';

import '../domain/mind_map.dart';
import 'mind_maps_strings.dart';

const Key kMindMapSettingsPanelKey = Key('mind_map_settings_panel');
const Key kMindMapSettingsSaveKey = Key('mind_map_settings_save');
const Key kMindMapLayoutFieldKey = Key('mind_map_layout_field');

class MapSettingsPanel extends StatefulWidget {
  const MapSettingsPanel({
    super.key,
    required this.initial,
    required this.strings,
    required this.onSave,
  });

  final MindMapSettings initial;
  final MindMapsStrings strings;
  final Future<bool> Function(MindMapSettings) onSave;

  @override
  State<MapSettingsPanel> createState() => _MapSettingsPanelState();
}

class _MapSettingsPanelState extends State<MapSettingsPanel> {
  late MapLayout _layout = widget.initial.layout;
  late MapCanvasPattern _background = widget.initial.backgroundPattern;
  late int _nodeColor = widget.initial.defaultNode.argb;
  late MapLinePattern _line = widget.initial.defaultConnection.pattern;
  late double _width = widget.initial.defaultConnection.width;
  late double _spacing = widget.initial.spacing;
  bool _saving = false;
  bool _failed = false;

  bool get _ar => Directionality.of(context) == TextDirection.rtl;

  String _layoutLabel(MapLayout value) => switch (value) {
    MapLayout.radial => widget.strings.layoutRadial,
    MapLayout.tree => widget.strings.layoutTree,
    MapLayout.horizontal => widget.strings.layoutHorizontal,
    MapLayout.vertical => widget.strings.layoutVertical,
    MapLayout.freeform => widget.strings.layoutFreeform,
  };

  String _backgroundLabel(MapCanvasPattern value) => switch (value) {
    MapCanvasPattern.theme => _ar ? 'السمة الأساسية' : 'Default',
    MapCanvasPattern.grid => _ar ? 'شبكة مربعات' : 'Grid',
    MapCanvasPattern.dots => _ar ? 'نقاط ناعمة' : 'Soft dots',
    MapCanvasPattern.dark => _ar ? 'داكن فاخر' : 'Deep dark',
    MapCanvasPattern.plain => _ar ? 'بسيط مصمت' : 'Plain',
  };

  String _lineLabel(MapLinePattern value) => switch (value) {
    MapLinePattern.solid => _ar ? 'خط متصل' : 'Solid',
    MapLinePattern.dashed => _ar ? 'خط متقطع' : 'Dashed',
    MapLinePattern.dotted => _ar ? 'خط منقط' : 'Dotted',
  };

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final oldNode = widget.initial.defaultNode;
    final saved = await widget.onSave(
      MindMapSettings(
        layout: _layout,
        backgroundArgb: widget.initial.backgroundArgb,
        backgroundPattern: _background,
        defaultNode: MapNodeAppearance(
          argb: _nodeColor,
          icon: oldNode.icon,
          shape: oldNode.shape,
          nodeSize: oldNode.nodeSize,
          textSize: oldNode.textSize,
        ),
        defaultConnection: MapConnectionAppearance(
          argb: widget.initial.defaultConnection.argb,
          width: _width,
          pattern: _line,
        ),
        spacing: _spacing,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _failed = true;
      });
    }
  }

  Widget _label(IconData icon, String text, AppColors colors) => Row(
    children: [
      Icon(icon, size: 17, color: colors.primary),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    ],
  );

  Widget _option<T>(
    T item,
    T selected,
    String text,
    ValueChanged<T> choose,
    AppColors colors,
  ) {
    final active = item == selected;
    return InkWell(
      onTap: () => choose(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: active ? colors.accentSoft : colors.surfaceSecondary,
          border: Border.all(
            color: active
                ? colors.primary.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 620;
    final swatches = <int>{
      0xff10b981,
      0xff059669,
      0xff84cc16,
      0xff14b8a6,
      0xff06b6d4,
      0xff3b82f6,
      0xffa855f7,
      0xfff59e0b,
      0xfff43f5e,
      0xff94a3b8,
      _nodeColor,
    };
    return Dialog(
      key: kMindMapSettingsPanelKey,
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 24,
                18,
                compact ? 16 : 24,
                14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.accentSoft,
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.tune_rounded, color: colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.strings.settings,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          _ar
                              ? 'الخلفية، الروابط، ونمط التخطيط التلقائي'
                              : 'Background, connections and layout',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(
                      Icons.grid_view_rounded,
                      _ar ? 'نمط خلفية اللوحة' : 'Canvas background',
                      colors,
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (_, box) => GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: box.maxWidth < 480 ? 3 : 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: box.maxWidth < 480 ? 2.1 : 1.8,
                        children: [
                          for (final pattern in MapCanvasPattern.values)
                            _option(
                              pattern,
                              _background,
                              _backgroundLabel(pattern),
                              (value) => setState(() => _background = value),
                              colors,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _label(
                      Icons.palette_outlined,
                      _ar
                          ? 'اللون الافتراضي للعقد الجديدة'
                          : 'Default color for new nodes',
                      colors,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final color in swatches)
                          InkWell(
                            key: ValueKey('map_node_swatch_$color'),
                            onTap: () => setState(() => _nodeColor = color),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(color),
                                shape: BoxShape.circle,
                                border: color == _nodeColor
                                    ? Border.all(
                                        color: colors.surface,
                                        width: 3,
                                      )
                                    : null,
                                boxShadow: color == _nodeColor
                                    ? [
                                        BoxShadow(
                                          color: colors.primary,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: color == _nodeColor
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (_, box) {
                        final line = AppSelectField<MapLinePattern>(
                          initialValue: _line,
                          decoration: InputDecoration(
                            labelText: _ar
                                ? 'نمط خطوط الربط'
                                : 'Connection line style',
                          ),
                          items: [
                            for (final pattern in MapLinePattern.values)
                              DropdownMenuItem(
                                value: pattern,
                                child: Text(_lineLabel(pattern)),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _line = value);
                          },
                        );
                        final thickness = AppSelectField<double>(
                          initialValue: _width,
                          decoration: InputDecoration(
                            labelText: widget.strings.connectionWidth,
                          ),
                          items: [
                            for (final width in <double>{1.5, 2.5, 4.0, _width})
                              DropdownMenuItem(
                                value: width,
                                child: Text('${width.toStringAsFixed(1)} px'),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _width = value);
                          },
                        );
                        return box.maxWidth < 470
                            ? Column(
                                children: [
                                  line,
                                  const SizedBox(height: 12),
                                  thickness,
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: line),
                                  const SizedBox(width: 12),
                                  Expanded(child: thickness),
                                ],
                              );
                      },
                    ),

                    const SizedBox(height: 22),
                    _label(
                      Icons.auto_awesome_rounded,
                      _ar ? 'نمط التخطيط التلقائي' : 'Auto layout pattern',
                      colors,
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (_, box) => GridView.count(
                        key: kMindMapLayoutFieldKey,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: box.maxWidth < 470 ? 2 : 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: box.maxWidth < 470 ? 3.3 : 2.6,
                        children: [
                          for (final layout in [
                            MapLayout.radial,
                            MapLayout.tree,
                            MapLayout.horizontal,
                            MapLayout.freeform,
                          ])
                            _option(
                              layout,
                              _layout,
                              _layoutLabel(layout),
                              (value) => setState(() => _layout = value),
                              colors,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.strings.spacing,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${_spacing.round()} px',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _spacing.clamp(120, 300),
                      min: 120,
                      max: 300,
                      divisions: 18,
                      onChanged: (value) => setState(() => _spacing = value),
                    ),
                    if (_failed)
                      Text(
                        widget.strings.saveFailure,
                        style: TextStyle(color: colors.error),
                      ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: colors.border),
            Padding(
              padding: EdgeInsets.all(compact ? 16 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(widget.strings.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: kMindMapSettingsSaveKey,
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(widget.strings.save),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
