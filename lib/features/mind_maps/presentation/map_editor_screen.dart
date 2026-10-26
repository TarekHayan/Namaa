import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../application/map_queries.dart';
import '../application/map_repository.dart';
import '../application/map_sync_service.dart';
import '../domain/mind_map.dart';
import '../domain/mind_map_node.dart';
import 'map_canvas.dart';
import 'map_conflict_view.dart';
import 'map_editor_cubit.dart';
import 'map_editor_state.dart';
import 'map_node_details_panel.dart';
import 'map_node_editor.dart';
import 'map_settings_panel.dart';
import 'map_task_picker.dart';
import 'mind_maps_strings.dart';

const Key kMindMapEditorKey = Key('mind_map_editor');
const Key kMindMapAddNodeKey = Key('mind_map_add_node');
const Key kMindMapUndoKey = Key('mind_map_undo');
const Key kMindMapRedoKey = Key('mind_map_redo');
const Key kMindMapDeleteNodeKey = Key('mind_map_delete_node');
const Key kMindMapLinkTaskKey = Key('mind_map_link_task');
const Key kMindMapCompleteTaskKey = Key('mind_map_complete_task');
const Key kMindMapSettingsKey = Key('mind_map_settings');
const Key kMindMapApplyLayoutKey = Key('mind_map_apply_layout');

class MapEditorScreen extends StatefulWidget {
  const MapEditorScreen({
    super.key,
    required this.cubit,
    required this.stringsResolver,
    this.onBack,
    this.ownsCubit = true,
  });

  final MapEditorCubit cubit;
  final MindMapsStringsResolver stringsResolver;
  final VoidCallback? onBack;
  final bool ownsCubit;

  @override
  State<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends State<MapEditorScreen> {
  String? _connectingSourceId;
  bool _selectionVisible = false;
  bool _showQuickAdd = false;

  String _layoutLabel(MapLayout layout, MindMapsStrings strings) =>
      switch (layout) {
        MapLayout.radial => strings.layoutRadial,
        MapLayout.tree => strings.layoutTree,
        MapLayout.horizontal => strings.layoutHorizontal,
        MapLayout.vertical => strings.layoutVertical,
        MapLayout.freeform => strings.layoutFreeform,
      };

  @override
  void dispose() {
    if (widget.ownsCubit) widget.cubit.close();
    super.dispose();
  }

  Future<void> _add(
    MapEditorReady state,
    MindMapsStrings strings, {
    MindMapNodeKind? kind,
  }) async {
    var created = false;
    await showDialog<void>(
      context: context,
      builder: (_) => MapNodeEditor(
        strings: strings,
        initialKind: kind,
        defaultAppearance: state.graph.map.settings.defaultNode,
        onSave: (draft) async {
          final index = state.graph.nodes.length - 1;
          created = await widget.cubit.addNode(
            kind: draft.kind,
            title: draft.title,
            description: draft.description,
            priority: draft.priority,
            status: draft.status,
            appearance: draft.appearance,
            parentId: kind == MindMapNodeKind.mainIdea || !_selectionVisible
                ? null
                : state.selectedId,
            x: ((index + 1) % 3 - 1) * 190.0,
            y: (index ~/ 3) * 120.0 + 140,
          );
          return created;
        },
      ),
    );
    if (mounted && created) {
      setState(() {
        _showQuickAdd = false;
        _selectionVisible = true;
      });
    }
  }

  Future<void> _edit(MindMapNode node, MindMapsStrings strings) async {
    final ready = widget.cubit.state;
    final linkedTask = ready is MapEditorReady && node.taskId != null
        ? ready.linkedTasks[node.taskId]
        : null;
    await showDialog<void>(
      context: context,
      builder: (_) => MapNodeEditor(
        strings: strings,
        node: node,
        taskPort: widget.cubit.taskPort,
        ownerId: widget.cubit.ownerId,
        linkedTask: linkedTask,
        onDelete: () => _delete(node, strings),
        onSave: (draft) async {
          final edited = await widget.cubit.editNode(
            nodeId: node.id,
            title: draft.title,
            description: draft.description,
            editDescription: true,
            priority: draft.priority,
            appearance: draft.appearance,
            status: node.taskId == null && draft.taskId == null
                ? draft.status
                : null,
          );
          if (!edited || draft.taskId == node.taskId) return edited;
          final linked = await widget.cubit.setTaskLink(node.id, draft.taskId);
          if (!linked) return false;
          if (node.taskId != null &&
              draft.taskId == null &&
              draft.status != node.status) {
            return widget.cubit.editNode(nodeId: node.id, status: draft.status);
          }
          return true;
        },
      ),
    );
  }

  Future<void> _settings(MapEditorReady state, MindMapsStrings strings) =>
      showDialog<void>(
        context: context,
        builder: (_) => MapSettingsPanel(
          initial: state.graph.map.settings,
          strings: strings,
          onSave: (settings) => widget.cubit.saveSettings(
            settings,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      );

  Future<bool> _delete(MindMapNode node, MindMapsStrings strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteNode),
        content: Text(strings.deleteNodeConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.deleteNode),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    return widget.cubit.deleteNode(node.id);
  }

  Future<void> _chooseTask(MindMapNode node, MindMapsStrings strings) async {
    final port = widget.cubit.taskPort;
    if (port == null) return;
    final taskId = await showMapTaskPicker(
      context: context,
      tasks: port,
      ownerId: widget.cubit.ownerId,
      strings: strings,
    );
    if (taskId != null && mounted) {
      await widget.cubit.setTaskLink(node.id, taskId);
    }
  }

  void _selectNode(String id) {
    final source = _connectingSourceId;
    if (source != null && source != id) {
      widget.cubit.setSideLink(source, id, true);
      setState(() => _connectingSourceId = null);
    } else {
      widget.cubit.select(id);
      setState(() => _selectionVisible = true);
    }
  }

  void _cycleStatus(MindMapNode node, MapEditorReady ready) {
    if (ready.busy) return;
    if (node.taskId != null) {
      final linked = ready.linkedTasks[node.taskId];
      if (linked?.available != true) return;
      if (linked!.completed) {
        widget.cubit.reopenLinkedTask(linked.id);
      } else {
        widget.cubit.completeLinkedTask(linked.id);
      }
      return;
    }
    final next = switch (node.status) {
      MindMapNodeStatus.notStarted => MindMapNodeStatus.inProgress,
      MindMapNodeStatus.inProgress => MindMapNodeStatus.completed,
      MindMapNodeStatus.completed => MindMapNodeStatus.notStarted,
    };
    widget.cubit.editNode(nodeId: node.id, status: next);
  }

  void _openDetails(MindMapsStrings strings) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.76,
        child: MapNodeDetailsPanel(
          cubit: widget.cubit,
          strings: strings,
          onEdit: (node) => _edit(node, strings),
          onDelete: (node) => _delete(node, strings),
          onChooseTask: (node) => _chooseTask(node, strings),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.stringsResolver(context);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return BlocBuilder<MapEditorCubit, MapEditorState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state is MapEditorLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is MapEditorUnavailable) {
          return Scaffold(
            appBar: AppBar(title: Text(strings.title)),
            body: Center(
              child: Text(
                state.failure == null ? strings.notFound : strings.loadFailure,
              ),
            ),
          );
        }

        final ready = state as MapEditorReady;
        final graph = ready.graph;
        final view = MapQueries.graph(graph);
        final selected = view.nodes.firstWhere(
          (node) => node.id == ready.selectedId,
          orElse: () => view.nodes.first,
        );

        return Scaffold(
          key: kMindMapEditorKey,
          backgroundColor: colors.background,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final canvasHeight = math.max(constraints.maxHeight, 440.0);
              final isCompact = constraints.maxWidth < 560;

              return Stack(
                children: [
                  // A dedicated canvas viewport; details open separately.
                  Positioned.fill(
                    child: MapCanvas(
                      graph: graph,
                      selectedId: _selectionVisible ? selected.id : '',
                      height: canvasHeight,
                      onSelect: _selectNode,
                      onStatusTap: (node) => _cycleStatus(node, ready),
                      strings: strings,
                      linkedTasks: ready.linkedTasks,
                      controlsBottom: isCompact ? 146 : 16,
                      onMove: (nodeId, x, y) =>
                          widget.cubit.editNode(nodeId: nodeId, x: x, y: y),
                    ),
                  ),

                  // 2. PINNED Top Floating Header Bar (Prototype styling)
                  PositionedDirectional(
                    top: MediaQuery.paddingOf(context).top + 10,
                    start: 12,
                    end: 12,
                    child: _buildTopFloatingHeader(
                      context: context,
                      ready: ready,
                      graph: graph,
                      strings: strings,
                      colors: colors,
                      isRtl: isRtl,
                      isCompact: isCompact,
                    ),
                  ),

                  // 3. Status banners (if any)
                  if (ready.failure != null ||
                      ready.conflicts.isNotEmpty ||
                      ready.syncStatus == MapSyncStatus.synchronizing ||
                      ready.syncStatus == MapSyncStatus.failed ||
                      _connectingSourceId != null)
                    PositionedDirectional(
                      top:
                          MediaQuery.paddingOf(context).top +
                          (isCompact ? 96 : 76),
                      start: 16,
                      end: 16,
                      child: _buildStatusBanner(
                        context: context,
                        ready: ready,
                        strings: strings,
                        colors: colors,
                      ),
                    ),

                  // 4. Floating Quick Action Button (+ FAB at bottom start)
                  PositionedDirectional(
                    bottom: 16,
                    start: 16,
                    child: Material(
                      color: colors.primary,
                      elevation: 8,
                      shadowColor: colors.primary.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        key: kMindMapAddNodeKey,
                        borderRadius: BorderRadius.circular(18),
                        onTap: ready.busy
                            ? null
                            : () => setState(
                                () => _showQuickAdd = !_showQuickAdd,
                              ),
                        child: const SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(
                            Icons.add_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_showQuickAdd)
                    PositionedDirectional(
                      bottom: 76,
                      start: 16,
                      child: _buildQuickAddMenu(ready, strings, colors),
                    ),

                  // 5. Floating Center Capsule (Helper text or Selected node actions)
                  if (isCompact && !_showQuickAdd)
                    Positioned(
                      bottom: 76,
                      left: 8,
                      right: 8,
                      child: Center(
                        child: _buildCenterFloatingCapsule(
                          ready: ready,
                          selected: selected,
                          strings: strings,
                          colors: colors,
                          isRtl: isRtl,
                          isCompact: isCompact,
                        ),
                      ),
                    )
                  else if (!_showQuickAdd)
                    Positioned(
                      bottom: constraints.maxWidth < 1100 ? 76 : 16,
                      left: 80,
                      right: 180,
                      child: Center(
                        child: _buildCenterFloatingCapsule(
                          ready: ready,
                          selected: selected,
                          strings: strings,
                          colors: colors,
                          isRtl: isRtl,
                          isCompact: isCompact,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTopFloatingHeader({
    required BuildContext context,
    required MapEditorReady ready,
    required MapGraph graph,
    required MindMapsStrings strings,
    required AppColors colors,
    required bool isRtl,
    required bool isCompact,
  }) {
    final progressText =
        '${strings.completedCount}: '
        '${ready.summary.completedCount}/${ready.summary.nodeCount} '
        '(${ready.summary.progressPercent}%)';
    final chromeBorder = colors.textMuted.withValues(alpha: 0.28);

    return Material(
      key: const Key('mind_map_top_bar'),
      color: colors.navigationBackground,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: chromeBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Back Button
                InkWell(
                  onTap:
                      widget.onBack ?? () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRtl
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_back_rounded,
                          size: 15,
                          color: colors.textPrimary,
                        ),
                        if (!isCompact) ...[
                          const SizedBox(width: 4),
                          Text(
                            isRtl ? 'الخرائط' : 'Maps',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Map Icon
                if (!isCompact) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.hub_rounded,
                      color: colors.primary,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Title (Expanded to prevent overflow)
                Expanded(
                  child: Text(
                    graph.map.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ).copyWith(color: colors.textPrimary),
                  ),
                ),

                if (!isCompact) ...[
                  const SizedBox(width: 8),
                  // Progress Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          progressText,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(width: 4),

                // Undo
                IconButton(
                  key: kMindMapUndoKey,
                  tooltip: strings.undo,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: ready.canUndo && !ready.busy
                      ? widget.cubit.undo
                      : null,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                ),

                // Redo
                IconButton(
                  key: kMindMapRedoKey,
                  tooltip: strings.redo,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: ready.canRedo && !ready.busy
                      ? widget.cubit.redo
                      : null,
                  icon: const Icon(Icons.redo_rounded, size: 18),
                ),

                Container(
                  width: 1,
                  height: 18,
                  color: chromeBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                ),

                // Layout
                PopupMenuButton<MapLayout>(
                  key: kMindMapApplyLayoutKey,
                  tooltip: strings.applyLayout,
                  enabled: !ready.busy,
                  onSelected: (layout) =>
                      widget.cubit.applyLayout(layout, rtl: isRtl),
                  itemBuilder: (_) => [
                    for (final layout in MapLayout.values)
                      PopupMenuItem(
                        value: layout,
                        child: Text(_layoutLabel(layout, strings)),
                      ),
                  ],
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 6 : 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: colors.primary,
                          size: 14,
                        ),
                        if (!isCompact) ...[
                          const SizedBox(width: 4),
                          Text(
                            isRtl ? 'تخطيط' : 'Layout',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Settings
                IconButton(
                  key: kMindMapSettingsKey,
                  tooltip: strings.settings,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: ready.busy
                      ? null
                      : () => _settings(ready, strings),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                ),
              ],
            ),
            if (isCompact) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      progressText,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFloatingCapsule({
    required MapEditorReady ready,
    required MindMapNode selected,
    required MindMapsStrings strings,
    required AppColors colors,
    required bool isRtl,
    required bool isCompact,
  }) {
    final isSelected =
        _selectionVisible &&
        ready.graph.nodes.any((n) => n.id == ready.selectedId);
    final chromeBorder = colors.textMuted.withValues(alpha: 0.28);

    if (!isSelected) {
      return Material(
        color: colors.navigationBackground,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: chromeBorder),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 16,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                isRtl
                    ? (isCompact
                          ? 'حدد عقدة للبدء أو اضغط +'
                          : 'حدد عقدة للبدء أو اضغط على + لإضافة عقدة')
                    : (isCompact
                          ? 'Select node or tap +'
                          : 'Select a node to edit or tap + to add'),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final actions = <Widget>[
      FilledButton.icon(
        onPressed: ready.busy
            ? null
            : () => _add(ready, strings, kind: MindMapNodeKind.branch),
        icon: const Icon(Icons.add_rounded, size: 19),
        label: Text(isRtl ? 'فرع جديد' : 'New branch'),
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: const Color(0xFF062016),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      OutlinedButton.icon(
        onPressed: () => _edit(selected, strings),
        icon: Icon(Icons.edit_outlined, size: 18, color: colors.primary),
        label: Text(strings.editNode),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: chromeBorder),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      OutlinedButton.icon(
        onPressed: ready.busy
            ? null
            : () => setState(
                () => _connectingSourceId = _connectingSourceId == selected.id
                    ? null
                    : selected.id,
              ),
        icon: Icon(
          Icons.account_tree_outlined,
          size: 18,
          color: colors.primary,
        ),
        label: Text(strings.connect),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: chromeBorder),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      PopupMenuButton<String>(
        tooltip: strings.nodeStatus,
        icon: Icon(
          Icons.more_horiz_rounded,
          size: 24,
          color: colors.textPrimary,
        ),
        onSelected: (value) {
          if (value == 'delete') {
            _delete(selected, strings);
          } else {
            _openDetails(strings);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'details', child: Text(strings.nodeStatus)),
          if (selected.kind != MindMapNodeKind.central)
            PopupMenuItem(value: 'delete', child: Text(strings.deleteNode)),
        ],
      ),
      IconButton(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        icon: Icon(Icons.close_rounded, size: 22, color: colors.textMuted),
        tooltip: isRtl ? 'إلغاء التحديد' : 'Deselect',
        onPressed: () => setState(() {
          _selectionVisible = false;
          _connectingSourceId = null;
        }),
      ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Material(
        key: const Key('mind_map_selection_bar'),
        color: colors.navigationBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner({
    required BuildContext context,
    required MapEditorReady ready,
    required MindMapsStrings strings,
    required AppColors colors,
  }) {
    final theme = Theme.of(context);
    if (_connectingSourceId != null) {
      return Material(
        color: colors.info,
        borderRadius: BorderRadius.circular(14),
        elevation: 6,
        child: ListTile(
          dense: true,
          title: Text(
            strings.connect,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            strings.sideLink,
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: IconButton(
            onPressed: () => setState(() => _connectingSourceId = null),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
      );
    }
    if (ready.failure != null) {
      return Material(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ready.failure!.messageKey == 'mind_maps.error.task_link' ||
                          ready.failure!.messageKey.startsWith('tasks.')
                      ? strings.taskLinkFailure
                      : ready.failure!.category.name == 'validation'
                      ? strings.graphError
                      : strings.saveFailure,
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.cubit.clearFailure,
                icon: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.onErrorContainer,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (ready.conflicts.isNotEmpty) {
      return Material(
        color: colors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        elevation: 6,
        child: ListTile(
          dense: true,
          leading: Icon(Icons.rule, color: colors.warning),
          title: Text(
            '${strings.conflicts} (${ready.conflicts.length})',
            style: TextStyle(color: colors.warning, fontSize: 12),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MapConflictViewPanel(
                conflicts: ready.conflicts,
                strings: strings,
                ownerId: widget.cubit.ownerId,
                session: widget.cubit.session,
              ),
            ),
          ),
        ),
      );
    }
    if (ready.syncStatus == MapSyncStatus.synchronizing) {
      return Material(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(strings.syncing, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildQuickAddMenu(
    MapEditorReady ready,
    MindMapsStrings strings,
    AppColors colors,
  ) => Material(
    color: colors.navigationBackground,
    elevation: 12,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      width: 230,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in [
            (
              MindMapNodeKind.mainIdea,
              Icons.hub_outlined,
              strings.kindMainIdea,
            ),
            (
              MindMapNodeKind.branch,
              Icons.account_tree_outlined,
              strings.kindBranch,
            ),
            (
              MindMapNodeKind.task,
              Icons.track_changes_outlined,
              strings.kindTask,
            ),
            (MindMapNodeKind.note, Icons.book_outlined, strings.kindNote),
          ])
            ListTile(
              key: ValueKey('mind_map_quick_${option.$1.name}'),
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(option.$2, color: colors.primary, size: 20),
              title: Text(
                option.$3,
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              enabled: option.$1 != MindMapNodeKind.branch || _selectionVisible,
              onTap: () => _add(ready, strings, kind: option.$1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
        ],
      ),
    ),
  );
}
