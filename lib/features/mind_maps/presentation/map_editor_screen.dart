import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/map_queries.dart';
import '../domain/mind_map_node.dart';
import 'map_canvas.dart';
import 'map_editor_cubit.dart';
import 'map_editor_state.dart';
import 'map_node_editor.dart';
import 'map_task_picker.dart';
import 'mind_maps_strings.dart';

const Key kMindMapEditorKey = Key('mind_map_editor');
const Key kMindMapAddNodeKey = Key('mind_map_add_node');
const Key kMindMapUndoKey = Key('mind_map_undo');
const Key kMindMapRedoKey = Key('mind_map_redo');
const Key kMindMapDeleteNodeKey = Key('mind_map_delete_node');
const Key kMindMapLinkTaskKey = Key('mind_map_link_task');
const Key kMindMapCompleteTaskKey = Key('mind_map_complete_task');

class MapEditorScreen extends StatefulWidget {
  const MapEditorScreen({
    super.key,
    required this.cubit,
    required this.stringsResolver,
  });

  final MapEditorCubit cubit;
  final MindMapsStringsResolver stringsResolver;

  @override
  State<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends State<MapEditorScreen> {
  String? _sideTargetId;

  @override
  void dispose() {
    widget.cubit.close();
    super.dispose();
  }

  Future<void> _add(MapEditorReady state, MindMapsStrings strings) async {
    await showDialog<void>(
      context: context,
      builder: (_) => MapNodeEditor(
        strings: strings,
        onSave: (draft) {
          final index = state.graph.nodes.length - 1;
          return widget.cubit.addNode(
            kind: draft.kind,
            title: draft.title,
            description: draft.description,
            priority: draft.priority,
            parentId: state.selectedId,
            x: ((index + 1) % 3 - 1) * 190.0,
            y: (index ~/ 3) * 120.0 + 140,
          );
        },
      ),
    );
  }

  Future<void> _edit(MindMapNode node, MindMapsStrings strings) async {
    await showDialog<void>(
      context: context,
      builder: (_) => MapNodeEditor(
        strings: strings,
        node: node,
        onSave: (draft) => widget.cubit.editNode(
          nodeId: node.id,
          title: draft.title,
          description: draft.description,
          editDescription: true,
          priority: draft.priority,
          status: node.taskId == null ? draft.status : null,
        ),
      ),
    );
  }

  Future<void> _delete(MindMapNode node, MindMapsStrings strings) async {
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
    if (confirmed == true) await widget.cubit.deleteNode(node.id);
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

  @override
  Widget build(BuildContext context) {
    final strings = widget.stringsResolver(context);
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
        final linked = selected.taskId == null
            ? null
            : ready.linkedTasks[selected.taskId];
        final visibleStatus = MapQueries.visibleStatus(
          selected,
          ready.linkedTasks,
        );
        final parent = view.parentOf(selected.id);
        final candidates = view.nodes
            .where((node) => node.id != selected.id)
            .toList();
        final targetId = candidates.any((node) => node.id == _sideTargetId)
            ? _sideTargetId
            : null;
        final side = targetId == null
            ? null
            : view.sideBetween(selected.id, targetId);
        return Scaffold(
          key: kMindMapEditorKey,
          appBar: AppBar(
            title: Text(graph.map.title),
            actions: [
              IconButton(
                key: kMindMapUndoKey,
                tooltip: strings.undo,
                onPressed: ready.canUndo && !ready.busy
                    ? widget.cubit.undo
                    : null,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                key: kMindMapRedoKey,
                tooltip: strings.redo,
                onPressed: ready.canRedo && !ready.busy
                    ? widget.cubit.redo
                    : null,
                icon: const Icon(Icons.redo),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                '${strings.completedCount}: ${ready.summary.completedCount}'
                '/${ready.summary.nodeCount} (${ready.summary.progressPercent}%)',
              ),
              Semantics(
                label: '${strings.progress}: ${ready.summary.progressPercent}%',
                child: LinearProgressIndicator(
                  value: ready.summary.progressPercent / 100,
                ),
              ),
              if (ready.failure != null)
                ListTile(
                  leading: Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    ready.failure!.messageKey == 'mind_maps.error.task_link' ||
                            ready.failure!.messageKey.startsWith('tasks.')
                        ? strings.taskLinkFailure
                        : ready.failure!.category.name == 'validation'
                        ? strings.graphError
                        : strings.saveFailure,
                  ),
                  trailing: IconButton(
                    onPressed: widget.cubit.clearFailure,
                    icon: const Icon(Icons.close),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: kMindMapAddNodeKey,
                onPressed: ready.busy ? null : () => _add(ready, strings),
                icon: const Icon(Icons.add),
                label: Text(strings.addNode),
              ),
              const SizedBox(height: 12),
              MapCanvas(
                graph: graph,
                selectedId: selected.id,
                onSelect: widget.cubit.select,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final node in graph.nodes)
                    ChoiceChip(
                      label: Text(node.title),
                      selected: node.id == selected.id,
                      onSelected: (_) => widget.cubit.select(node.id),
                    ),
                ],
              ),
              const Divider(),
              Text(
                selected.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (selected.description?.isNotEmpty ?? false)
                Text(selected.description!),
              Text(
                '${strings.nodeStatus}: ${visibleStatus == null ? strings.taskUnavailable : _statusLabel(visibleStatus, strings)}',
              ),
              if (selected.taskId != null)
                ListTile(
                  leading: Icon(
                    linked?.available == true ? Icons.task_alt : Icons.link_off,
                  ),
                  title: Text(
                    linked?.available == true
                        ? linked!.title!
                        : strings.taskUnavailable,
                  ),
                  subtitle: Text(strings.linkedTask),
                ),
              if (widget.cubit.taskPort != null) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: kMindMapLinkTaskKey,
                      onPressed: ready.busy
                          ? null
                          : () => _chooseTask(selected, strings),
                      icon: const Icon(Icons.add_link),
                      label: Text(
                        selected.taskId == null
                            ? strings.linkTask
                            : strings.changeTask,
                      ),
                    ),
                    if (selected.taskId != null)
                      OutlinedButton.icon(
                        onPressed: ready.busy
                            ? null
                            : () => widget.cubit.setTaskLink(selected.id, null),
                        icon: const Icon(Icons.link_off),
                        label: Text(strings.unlinkTask),
                      ),
                  ],
                ),
                if (linked?.available == true)
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: kMindMapCompleteTaskKey,
                        onPressed: ready.busy
                            ? null
                            : () => linked!.completed
                                  ? widget.cubit.reopenLinkedTask(linked.id)
                                  : widget.cubit.completeLinkedTask(linked.id),
                        icon: Icon(
                          linked!.completed ? Icons.restart_alt : Icons.check,
                        ),
                        label: Text(
                          linked.completed
                              ? strings.reopenTask
                              : strings.completeTask,
                        ),
                      ),
                      if (!linked.completed)
                        OutlinedButton.icon(
                          onPressed: ready.busy
                              ? null
                              : () => widget.cubit.setLinkedInProgress(
                                  selected.id,
                                ),
                          icon: const Icon(Icons.pending_actions),
                          label: Text(strings.statusInProgress),
                        ),
                    ],
                  ),
              ],
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: ready.busy
                        ? null
                        : () => _edit(selected, strings),
                    icon: const Icon(Icons.edit),
                    label: Text(strings.editNode),
                  ),
                  if (selected.kind != MindMapNodeKind.central)
                    OutlinedButton.icon(
                      key: kMindMapDeleteNodeKey,
                      onPressed: ready.busy
                          ? null
                          : () => _delete(selected, strings),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(strings.deleteNode),
                    ),
                ],
              ),
              if (selected.kind != MindMapNodeKind.central) ...[
                KeyedSubtree(
                  key: ValueKey(
                    'parent:${selected.id}:${parent?.parentNodeId}',
                  ),
                  child: DropdownButtonFormField<String>(
                    key: const Key('mind_map_parent_picker'),
                    initialValue: parent?.parentNodeId ?? '',
                    decoration: InputDecoration(labelText: strings.parent),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(strings.noParent),
                      ),
                      for (final node in candidates)
                        DropdownMenuItem(
                          value: node.id,
                          child: Text(node.title),
                        ),
                    ],
                    onChanged: ready.busy
                        ? null
                        : (value) {
                            if (value == null ||
                                value == (parent?.parentNodeId ?? '')) {
                              return;
                            }
                            widget.cubit.setParent(
                              selected.id,
                              value.isEmpty ? null : value,
                            );
                          },
                  ),
                ),
                if (parent != null)
                  TextButton.icon(
                    onPressed: ready.busy
                        ? null
                        : () => widget.cubit.setParent(selected.id, null),
                    icon: const Icon(Icons.link_off),
                    label: Text(strings.detach),
                  ),
              ],
              if (candidates.isNotEmpty) ...[
                KeyedSubtree(
                  key: ValueKey('side:${selected.id}:${targetId ?? ''}'),
                  child: DropdownButtonFormField<String>(
                    key: const Key('mind_map_side_picker'),
                    initialValue: targetId ?? '',
                    decoration: InputDecoration(labelText: strings.sideLink),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(strings.sideLink),
                      ),
                      for (final node in candidates)
                        DropdownMenuItem(
                          value: node.id,
                          child: Text(node.title),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _sideTargetId = value?.isEmpty ?? true ? null : value;
                    }),
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('mind_map_side_action'),
                  onPressed: targetId == null || ready.busy
                      ? null
                      : () => widget.cubit.setSideLink(
                          selected.id,
                          targetId,
                          side == null,
                        ),
                  icon: Icon(side == null ? Icons.link : Icons.link_off),
                  label: Text(
                    side == null ? strings.connect : strings.disconnect,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(strings.moveNode),
              Wrap(
                spacing: 8,
                children: [
                  for (final direction in [
                    (Icons.arrow_back, -40.0, 0.0, '←'),
                    (Icons.arrow_forward, 40.0, 0.0, '→'),
                    (Icons.arrow_upward, 0.0, -40.0, '↑'),
                    (Icons.arrow_downward, 0.0, 40.0, '↓'),
                  ])
                    OutlinedButton.icon(
                      onPressed: ready.busy
                          ? null
                          : () => widget.cubit.editNode(
                              nodeId: selected.id,
                              x: selected.x + direction.$2,
                              y: selected.y + direction.$3,
                            ),
                      icon: Icon(direction.$1),
                      label: Text('${strings.moveNode} ${direction.$4}'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(MindMapNodeStatus status, MindMapsStrings strings) =>
      switch (status) {
        MindMapNodeStatus.notStarted => strings.statusNotStarted,
        MindMapNodeStatus.inProgress => strings.statusInProgress,
        MindMapNodeStatus.completed => strings.statusCompleted,
      };
}
