import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/theme/app_select_field.dart';

import '../application/map_queries.dart';
import '../domain/mind_map_node.dart';
import 'map_editor_cubit.dart';
import 'map_editor_state.dart';
import 'mind_maps_strings.dart';

/// Less frequent graph and task actions live here so the canvas stays clear.
class MapNodeDetailsPanel extends StatefulWidget {
  const MapNodeDetailsPanel({
    super.key,
    required this.cubit,
    required this.strings,
    required this.onEdit,
    required this.onDelete,
    required this.onChooseTask,
  });

  final MapEditorCubit cubit;
  final MindMapsStrings strings;
  final ValueChanged<MindMapNode> onEdit;
  final ValueChanged<MindMapNode> onDelete;
  final ValueChanged<MindMapNode> onChooseTask;

  @override
  State<MapNodeDetailsPanel> createState() => _MapNodeDetailsPanelState();
}

class _MapNodeDetailsPanelState extends State<MapNodeDetailsPanel> {
  String? _sideTargetId;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<MapEditorCubit, MapEditorState>(
    bloc: widget.cubit,
    builder: (context, state) {
      if (state is! MapEditorReady) return const SizedBox.shrink();
      final view = MapQueries.graph(state.graph);
      final selected = view.nodes.firstWhere(
        (node) => node.id == state.selectedId,
        orElse: () => view.nodes.first,
      );
      final parent = view.parentOf(selected.id);
      final candidates = view.nodes.where((n) => n.id != selected.id).toList();
      final targetId = candidates.any((n) => n.id == _sideTargetId)
          ? _sideTargetId
          : null;
      final side = targetId == null
          ? null
          : view.sideBetween(selected.id, targetId);
      final linked = selected.taskId == null
          ? null
          : state.linkedTasks[selected.taskId];
      final status = MapQueries.visibleStatus(selected, state.linkedTasks);
      final strings = widget.strings;
      return SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                Icon(
                  Icons.hub_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selected.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (selected.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(selected.description!),
            ],
            const SizedBox(height: 14),
            Text(
              '${strings.nodeStatus}: ${status == null ? strings.taskUnavailable : switch (status) {
                      MindMapNodeStatus.notStarted => strings.statusNotStarted,
                      MindMapNodeStatus.inProgress => strings.statusInProgress,
                      MindMapNodeStatus.completed => strings.statusCompleted,
                    }}',
            ),
            if (selected.taskId != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: state.busy ? null : () => widget.onEdit(selected),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(strings.editNode),
                ),
                if (selected.kind != MindMapNodeKind.central)
                  OutlinedButton.icon(
                    key: const Key('mind_map_delete_node'),
                    onPressed: state.busy
                        ? null
                        : () => widget.onDelete(selected),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(strings.deleteNode),
                  ),
              ],
            ),
            if (widget.cubit.taskPort != null) ...[
              const Divider(height: 30),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('mind_map_link_task'),
                    onPressed: state.busy
                        ? null
                        : () => widget.onChooseTask(selected),
                    icon: const Icon(Icons.add_link),
                    label: Text(
                      selected.taskId == null
                          ? strings.linkTask
                          : strings.changeTask,
                    ),
                  ),
                  if (selected.taskId != null)
                    OutlinedButton.icon(
                      onPressed: state.busy
                          ? null
                          : () => widget.cubit.setTaskLink(selected.id, null),
                      icon: const Icon(Icons.link_off),
                      label: Text(strings.unlinkTask),
                    ),
                  if (linked?.available == true)
                    OutlinedButton.icon(
                      key: const Key('mind_map_complete_task'),
                      onPressed: state.busy
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
                  if (linked?.available == true && !linked!.completed)
                    OutlinedButton.icon(
                      onPressed: state.busy
                          ? null
                          : () => widget.cubit.setLinkedInProgress(selected.id),
                      icon: const Icon(Icons.pending_actions),
                      label: Text(strings.statusInProgress),
                    ),
                ],
              ),
            ],
            if (selected.kind != MindMapNodeKind.central) ...[
              const Divider(height: 30),
              AppSelectField<String>(
                key: const Key('mind_map_parent_picker'),
                initialValue: parent?.parentNodeId ?? '',
                decoration: InputDecoration(labelText: strings.parent),
                items: [
                  DropdownMenuItem(value: '', child: Text(strings.noParent)),
                  for (final node in candidates)
                    DropdownMenuItem(value: node.id, child: Text(node.title)),
                ],
                onChanged: state.busy
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
              if (parent != null)
                TextButton.icon(
                  onPressed: state.busy
                      ? null
                      : () => widget.cubit.setParent(selected.id, null),
                  icon: const Icon(Icons.link_off),
                  label: Text(strings.detach),
                ),
            ],
            if (candidates.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppSelectField<String>(
                key: const Key('mind_map_side_picker'),
                initialValue: targetId ?? '',
                decoration: InputDecoration(labelText: strings.sideLink),
                items: [
                  DropdownMenuItem(value: '', child: Text(strings.sideLink)),
                  for (final node in candidates)
                    DropdownMenuItem(value: node.id, child: Text(node.title)),
                ],
                onChanged: (value) => setState(
                  () => _sideTargetId = value?.isEmpty ?? true ? null : value,
                ),
              ),
              OutlinedButton.icon(
                key: const Key('mind_map_side_action'),
                onPressed: targetId == null || state.busy
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
            const Divider(height: 30),
            Text(strings.moveNode),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final direction in [
                  (Icons.arrow_back, -40.0, 0.0),
                  (Icons.arrow_forward, 40.0, 0.0),
                  (Icons.arrow_upward, 0.0, -40.0),
                  (Icons.arrow_downward, 0.0, 40.0),
                ])
                  IconButton.outlined(
                    tooltip: strings.moveNode,
                    onPressed: state.busy
                        ? null
                        : () => widget.cubit.editNode(
                            nodeId: selected.id,
                            x: selected.x + direction.$2,
                            y: selected.y + direction.$3,
                          ),
                    icon: Icon(direction.$1),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
