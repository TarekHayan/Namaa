import 'package:flutter/material.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_select_field.dart';

import '../application/map_task_link_port.dart';
import '../domain/mind_map.dart';
import '../domain/mind_map_node.dart';
import 'map_appearance_fields.dart';
import 'map_task_picker.dart';
import 'mind_maps_strings.dart';

const Key kMindMapNodeTitleFieldKey = Key('mind_map_node_title_field');
const Key kMindMapNodeSaveKey = Key('mind_map_node_save');
const Key kMindMapNodeTaskFieldKey = Key('mind_map_node_task_field');

final class MapNodeDraft {
  const MapNodeDraft({
    required this.title,
    required this.description,
    required this.kind,
    required this.priority,
    required this.status,
    required this.appearance,
    required this.taskId,
  });

  final String title;
  final String? description;
  final MindMapNodeKind kind;
  final MindMapNodePriority priority;
  final MindMapNodeStatus status;
  final MapNodeAppearance appearance;
  final String? taskId;
}

class MapNodeEditor extends StatefulWidget {
  const MapNodeEditor({
    super.key,
    required this.strings,
    required this.onSave,
    this.node,
    this.defaultAppearance,
    this.initialKind,
    this.taskPort,
    this.ownerId,
    this.linkedTask,
    this.onDelete,
  });

  final MindMapsStrings strings;
  final MindMapNode? node;
  final MapNodeAppearance? defaultAppearance;
  final MindMapNodeKind? initialKind;
  final MapTaskLinkPort? taskPort;
  final String? ownerId;
  final MapLinkedTask? linkedTask;
  final Future<bool> Function()? onDelete;
  final Future<bool> Function(MapNodeDraft) onSave;

  @override
  State<MapNodeEditor> createState() => _MapNodeEditorState();
}

class _MapNodeEditorState extends State<MapNodeEditor> {
  late final TextEditingController _title = TextEditingController(
    text: widget.node?.title,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.node?.description,
  );
  late MindMapNodeKind _kind =
      widget.node?.kind ?? widget.initialKind ?? MindMapNodeKind.mainIdea;
  late MindMapNodePriority _priority =
      widget.node?.priority ?? MindMapNodePriority.medium;
  late MindMapNodeStatus _status =
      widget.node?.status ?? MindMapNodeStatus.notStarted;
  late MapNodeAppearance _appearance =
      widget.node?.appearance ??
      widget.defaultAppearance ??
      const MapNodeAppearance();
  late String? _taskId = widget.node?.taskId;
  late String? _taskTitle = widget.linkedTask?.title;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _isRtl => Directionality.of(context) == TextDirection.rtl;

  AppColors get _colors => Theme.of(context).brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;

  String _kindLabel(MindMapNodeKind kind) => switch (kind) {
    MindMapNodeKind.central => widget.strings.kindCentral,
    MindMapNodeKind.mainIdea => widget.strings.kindMainIdea,
    MindMapNodeKind.branch => widget.strings.kindBranch,
    MindMapNodeKind.task => widget.strings.kindTask,
    MindMapNodeKind.note => widget.strings.kindNote,
  };

  String _priorityLabel(MindMapNodePriority priority) => switch (priority) {
    MindMapNodePriority.low => widget.strings.priorityLow,
    MindMapNodePriority.medium => widget.strings.priorityMedium,
    MindMapNodePriority.high => widget.strings.priorityHigh,
  };

  String _statusLabel(MindMapNodeStatus status) => switch (status) {
    MindMapNodeStatus.notStarted => widget.strings.statusNotStarted,
    MindMapNodeStatus.inProgress => widget.strings.statusInProgress,
    MindMapNodeStatus.completed => widget.strings.statusCompleted,
  };

  void _changeAppearance({
    int? argb,
    String? icon,
    MapNodeShape? shape,
    MapSize? size,
  }) {
    setState(() {
      _appearance = MapNodeAppearance(
        argb: argb ?? _appearance.argb,
        icon: icon ?? _appearance.icon,
        shape: shape ?? _appearance.shape,
        nodeSize: size ?? _appearance.nodeSize,
        textSize: size ?? _appearance.textSize,
      );
    });
  }

  Future<void> _chooseTask() async {
    final port = widget.taskPort;
    final ownerId = widget.ownerId;
    if (port == null || ownerId == null) return;
    try {
      final chosen = await showMapTaskPicker(
        context: context,
        tasks: port,
        ownerId: ownerId,
        strings: widget.strings,
      );
      if (chosen == null || !mounted) return;
      final result = await port.readLinkedTask(ownerId, chosen);
      if (!mounted) return;
      if (result.valueOrNull case final task?) {
        if (task.available) {
          setState(() {
            _taskId = chosen;
            _taskTitle = task.title;
            _error = null;
          });
          return;
        }
      }
    } catch (_) {
      if (!mounted) return;
    }
    setState(() => _error = widget.strings.taskLinkFailure);
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _error = widget.strings.nodeTitleRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    bool saved;
    try {
      saved = await widget.onSave(
        MapNodeDraft(
          title: _title.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          kind: _kind,
          priority: _priority,
          status: _status,
          appearance: _appearance,
          taskId: _taskId,
        ),
      );
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = widget.strings.graphError;
      });
    }
  }

  Future<void> _delete() async {
    if (_busy || widget.onDelete == null) return;
    setState(() => _busy = true);
    bool deleted;
    try {
      deleted = await widget.onDelete!();
    } catch (_) {
      deleted = false;
    }
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = widget.strings.graphError;
      });
    }
  }

  Widget _label(String text, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: _colors.primary),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _colors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _choice({
    required Key key,
    required String text,
    required bool selected,
    required VoidCallback? onTap,
    IconData? icon,
    Color? accent,
  }) {
    final colors = _colors;
    final selectedColor = accent ?? colors.primary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? selectedColor.withValues(alpha: 0.13)
            : colors.surfaceSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(
            color: selected
                ? selectedColor.withValues(alpha: 0.6)
                : colors.border,
          ),
        ),
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? selectedColor : colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? selectedColor : colors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choices<T>(
    List<T> values,
    String Function(T) label,
    bool Function(T) selected,
    void Function(T) choose, {
    IconData? Function(T)? icon,
    Color? Function(T)? accent,
    String keyPrefix = 'choice',
    bool enabled = true,
  }) => Row(
    children: [
      for (var index = 0; index < values.length; index++) ...[
        if (index > 0) const SizedBox(width: 8),
        Expanded(
          child: _choice(
            key: ValueKey('$keyPrefix-${values[index]}'),
            text: label(values[index]),
            selected: selected(values[index]),
            onTap: _busy || !enabled ? null : () => choose(values[index]),
            icon: icon?.call(values[index]),
            accent: accent?.call(values[index]),
          ),
        ),
      ],
    ],
  );

  Widget _colorPalette() {
    final colors = _colors;
    final palette = <int>{...mapColors, _appearance.argb};
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final argb in palette)
          Tooltip(
            message: mapColorName(argb, _isRtl),
            child: Semantics(
              label: mapColorName(argb, _isRtl),
              selected: _appearance.argb == argb,
              button: true,
              child: InkWell(
                key: ValueKey('node-color-$argb'),
                onTap: _busy ? null : () => _changeAppearance(argb: argb),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _appearance.argb == argb
                          ? colors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Color(argb),
                    child: _appearance.argb == argb
                        ? Icon(
                            Icons.check_rounded,
                            size: 19,
                            color: Color(argb).computeLuminance() > 0.45
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _iconPalette() {
    final colors = _colors;
    final icons = <String>{...mapNodeIcons};
    if (_appearance.icon != 'none') icons.add(_appearance.icon);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final icon in icons)
            IconButton(
              key: ValueKey('node-icon-$icon'),
              onPressed: _busy
                  ? null
                  : () => _changeAppearance(
                      icon: _appearance.icon == icon ? 'none' : icon,
                    ),
              tooltip: mapIconName(icon, _isRtl, widget.strings),
              style: IconButton.styleFrom(
                backgroundColor: _appearance.icon == icon
                    ? colors.primary
                    : Colors.transparent,
                foregroundColor: _appearance.icon == icon
                    ? Colors.white
                    : colors.textSecondary,
                minimumSize: const Size(38, 38),
                padding: const EdgeInsets.all(8),
              ),
              icon: Icon(mapIcon(icon), size: 19),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final isEditing = widget.node != null;
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 24).clamp(0.0, 540.0);
    final height = (size.height * 0.88).clamp(0.0, 900.0);
    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: colors.border),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.accentSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? widget.strings.editNode
                              : widget.strings.addNode,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          _isRtl
                              ? 'تخصيص المحتوى، الحالة والمظهر'
                              : 'Customize content, status & appearance',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: widget.strings.cancel,
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('${widget.strings.nodeTitle} *'),
                    TextField(
                      key: kMindMapNodeTitleFieldKey,
                      controller: _title,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: _isRtl
                            ? 'مثال: دراسة الأساسيات'
                            : 'e.g. Core fundamentals',
                        errorText: _error == widget.strings.nodeTitleRequired
                            ? _error
                            : null,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _label(widget.strings.nodeDescription),
                    TextField(
                      controller: _description,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: _isRtl
                            ? 'تفاصيل إضافية أو مراجع...'
                            : 'Additional details, notes or references...',
                      ),
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: 18),
                      _label(widget.strings.nodeKind),
                      AppSelectField<MindMapNodeKind>(
                        initialValue: _kind,
                        items: [
                          for (final kind in MindMapNodeKind.values)
                            if (kind != MindMapNodeKind.central)
                              DropdownMenuItem(
                                value: kind,
                                child: Text(_kindLabel(kind)),
                              ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _kind = value);
                                }
                              },
                      ),
                    ],
                    const SizedBox(height: 18),
                    _label(widget.strings.nodeStatus),
                    _choices<MindMapNodeStatus>(
                      MindMapNodeStatus.values,
                      _statusLabel,
                      (value) => _status == value,
                      (value) => setState(() => _status = value),
                      keyPrefix: 'node-status',
                      enabled: _taskId == null,
                      icon: (value) => switch (value) {
                        MindMapNodeStatus.notStarted =>
                          Icons.radio_button_unchecked_rounded,
                        MindMapNodeStatus.inProgress =>
                          Icons.access_time_rounded,
                        MindMapNodeStatus.completed =>
                          Icons.check_circle_outline_rounded,
                      },
                      accent: (value) => switch (value) {
                        MindMapNodeStatus.notStarted => colors.textSecondary,
                        MindMapNodeStatus.inProgress => colors.warning,
                        MindMapNodeStatus.completed => colors.success,
                      },
                    ),
                    if (_taskId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          widget.strings.linkedTask,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ),
                    const SizedBox(height: 18),
                    _label(widget.strings.nodePriority),
                    _choices<MindMapNodePriority>(
                      MindMapNodePriority.values,
                      _priorityLabel,
                      (value) => _priority == value,
                      (value) => setState(() => _priority = value),
                      keyPrefix: 'node-priority',
                    ),
                    const SizedBox(height: 18),
                    _label(
                      widget.strings.nodeColor,
                      icon: Icons.palette_outlined,
                    ),
                    _colorPalette(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label(
                                widget.strings.nodeShape,
                                icon: Icons.category_outlined,
                              ),
                              AppSelectField<MapNodeShape>(
                                key: const Key('node-shape-field'),
                                initialValue: _appearance.shape,
                                items: [
                                  for (final shape in {
                                    ...mapNodeShapes,
                                    _appearance.shape,
                                  })
                                    DropdownMenuItem(
                                      value: shape,
                                      child: Text(
                                        mapShapeLabel(shape, widget.strings),
                                      ),
                                    ),
                                ],
                                onChanged: _busy
                                    ? null
                                    : (value) {
                                        if (value != null) {
                                          _changeAppearance(shape: value);
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label(
                                widget.strings.nodeSize,
                                icon: Icons.text_fields_rounded,
                              ),
                              AppSelectField<MapSize>(
                                key: const Key('node-size-field'),
                                initialValue: _appearance.nodeSize,
                                items: [
                                  for (final nodeSize in MapSize.values)
                                    DropdownMenuItem(
                                      value: nodeSize,
                                      child: Text(
                                        mapSizeLabel(nodeSize, widget.strings),
                                      ),
                                    ),
                                ],
                                onChanged: _busy
                                    ? null
                                    : (value) {
                                        if (value != null) {
                                          _changeAppearance(size: value);
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _label(
                            widget.strings.nodeIcon,
                            icon: Icons.auto_awesome_outlined,
                          ),
                        ),
                        if (_appearance.icon != 'none')
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _changeAppearance(icon: 'none'),
                            child: Text(
                              _isRtl ? 'إلغاء الأيقونة' : 'Remove icon',
                            ),
                          ),
                      ],
                    ),
                    _iconPalette(),
                    if (isEditing) ...[
                      const SizedBox(height: 20),
                      Divider(height: 1, color: colors.border),
                      const SizedBox(height: 16),
                      _label(widget.strings.linkTask, icon: Icons.link_rounded),
                      Text(
                        _isRtl
                            ? 'إنجاز العقدة المرتبطة يحدّث المهمة ونقاط الخبرة.'
                            : 'Completing a linked node updates the task and XP.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: kMindMapNodeTaskFieldKey,
                        onPressed: _busy || widget.taskPort == null
                            ? null
                            : _chooseTask,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        label: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            _taskId == null
                                ? (_isRtl
                                      ? '— بدون ربط بمهمة —'
                                      : '— No linked task —')
                                : (_taskTitle ??
                                      widget.strings.taskUnavailable),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_taskId != null)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _taskId = null;
                                    _taskTitle = null;
                                  }),
                            child: Text(widget.strings.unlinkTask),
                          ),
                        ),
                    ],
                    if (_error != null &&
                        _error != widget.strings.nodeTitleRequired) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: colors.error)),
                    ],
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  if (isEditing &&
                      widget.node!.kind != MindMapNodeKind.central &&
                      widget.onDelete != null) ...[
                    IconButton.filledTonal(
                      tooltip: widget.strings.deleteNode,
                      onPressed: _busy ? null : _delete,
                      style: IconButton.styleFrom(
                        backgroundColor: colors.error.withValues(alpha: 0.12),
                        foregroundColor: colors.error,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: Text(widget.strings.cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: kMindMapNodeSaveKey,
                      onPressed: _busy ? null : _save,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        isEditing
                            ? (_isRtl ? 'حفظ التعديلات' : 'Save changes')
                            : widget.strings.save,
                      ),
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
