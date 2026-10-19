import 'package:flutter/material.dart';

import '../domain/mind_map.dart';
import 'map_appearance_fields.dart';
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
  late int _background = widget.initial.backgroundArgb;
  late MapNodeAppearance _node = widget.initial.defaultNode;
  late int _connectionColor = widget.initial.defaultConnection.argb;
  late double _connectionWidth = widget.initial.defaultConnection.width;
  late double _spacing = widget.initial.spacing;
  bool _saving = false;
  bool _failed = false;

  String _layoutLabel(MapLayout value) => switch (value) {
    MapLayout.radial => widget.strings.layoutRadial,
    MapLayout.tree => widget.strings.layoutTree,
    MapLayout.horizontal => widget.strings.layoutHorizontal,
    MapLayout.vertical => widget.strings.layoutVertical,
    MapLayout.freeform => widget.strings.layoutFreeform,
  };

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final saved = await widget.onSave(
      MindMapSettings(
        layout: _layout,
        backgroundArgb: _background,
        defaultNode: _node,
        defaultConnection: MapConnectionAppearance(
          argb: _connectionColor,
          width: _connectionWidth,
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

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: kMindMapSettingsPanelKey,
    title: Text(widget.strings.settings),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<MapLayout>(
              key: kMindMapLayoutFieldKey,
              initialValue: _layout,
              decoration: InputDecoration(labelText: widget.strings.layout),
              items: [
                for (final layout in MapLayout.values)
                  DropdownMenuItem(
                    value: layout,
                    child: Text(_layoutLabel(layout)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _layout = value);
              },
            ),
            MapColorField(
              label: widget.strings.background,
              value: _background,
              strings: widget.strings,
              onChanged: (value) => setState(() => _background = value),
            ),
            const SizedBox(height: 12),
            Text(widget.strings.defaultNode),
            MapAppearanceFields(
              appearance: _node,
              strings: widget.strings,
              onChanged: (value) => setState(() => _node = value),
            ),
            const SizedBox(height: 12),
            Text(widget.strings.connectionStyle),
            MapColorField(
              label: widget.strings.connectionColor,
              value: _connectionColor,
              strings: widget.strings,
              onChanged: (value) => setState(() => _connectionColor = value),
            ),
            Text(
              '${widget.strings.connectionWidth}: ${_connectionWidth.round()}',
            ),
            Slider(
              value: _connectionWidth.clamp(1, 12),
              min: 1,
              max: 12,
              divisions: 11,
              label: _connectionWidth.round().toString(),
              onChanged: (value) => setState(() => _connectionWidth = value),
            ),
            Text('${widget.strings.spacing}: ${_spacing.round()}'),
            Slider(
              value: _spacing.clamp(40, 400),
              min: 40,
              max: 400,
              divisions: 36,
              label: _spacing.round().toString(),
              onChanged: (value) => setState(() => _spacing = value),
            ),
            if (_failed) Text(widget.strings.saveFailure),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: Text(widget.strings.cancel),
      ),
      FilledButton(
        key: kMindMapSettingsSaveKey,
        onPressed: _saving ? null : _save,
        child: Text(widget.strings.save),
      ),
    ],
  );
}
