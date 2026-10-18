import 'package:flutter/material.dart';

import '../domain/mind_map_node.dart';
import 'mind_maps_strings.dart';

const Key kMindMapNodeTitleFieldKey = Key('mind_map_node_title_field');
const Key kMindMapNodeSaveKey = Key('mind_map_node_save');

final class MapNodeDraft {
  const MapNodeDraft({
    required this.title,
    required this.description,
    required this.kind,
    required this.priority,
    required this.status,
  });
  final String title;
  final String? description;
  final MindMapNodeKind kind;
  final MindMapNodePriority priority;
  final MindMapNodeStatus status;
}

class MapNodeEditor extends StatefulWidget {
  const MapNodeEditor({
    super.key,
    required this.strings,
    required this.onSave,
    this.node,
  });

  final MindMapsStrings strings;
  final MindMapNode? node;
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
  late MindMapNodeKind _kind = widget.node?.kind ?? MindMapNodeKind.mainIdea;
  late MindMapNodePriority _priority =
      widget.node?.priority ?? MindMapNodePriority.medium;
  late MindMapNodeStatus _status =
      widget.node?.status ?? MindMapNodeStatus.notStarted;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

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

  Future<void> _save() async {
    if (_saving) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _error = widget.strings.nodeTitleRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.onSave(
      MapNodeDraft(
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        kind: _kind,
        priority: _priority,
        status: _status,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = widget.strings.graphError;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.node == null ? widget.strings.addNode : widget.strings.editNode,
    ),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: kMindMapNodeTitleFieldKey,
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(
                labelText: widget.strings.nodeTitle,
                errorText: _error == widget.strings.nodeTitleRequired
                    ? _error
                    : null,
              ),
            ),
            TextField(
              controller: _description,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: widget.strings.nodeDescription,
              ),
            ),
            if (widget.node == null)
              DropdownButtonFormField<MindMapNodeKind>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: widget.strings.nodeKind),
                items: [
                  for (final kind in MindMapNodeKind.values)
                    if (kind != MindMapNodeKind.central)
                      DropdownMenuItem(
                        value: kind,
                        child: Text(_kindLabel(kind)),
                      ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _kind = value);
                },
              )
            else
              ListTile(
                title: Text(widget.strings.nodeKind),
                subtitle: Text(_kindLabel(_kind)),
              ),
            DropdownButtonFormField<MindMapNodePriority>(
              initialValue: _priority,
              decoration: InputDecoration(
                labelText: widget.strings.nodePriority,
              ),
              items: [
                for (final priority in MindMapNodePriority.values)
                  DropdownMenuItem(
                    value: priority,
                    child: Text(_priorityLabel(priority)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            if (widget.node?.taskId == null)
              DropdownButtonFormField<MindMapNodeStatus>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: widget.strings.nodeStatus,
                ),
                items: [
                  for (final status in MindMapNodeStatus.values)
                    DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(status)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
            if (_error != null && _error != widget.strings.nodeTitleRequired)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
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
        key: kMindMapNodeSaveKey,
        onPressed: _saving ? null : _save,
        child: Text(widget.strings.save),
      ),
    ],
  );
}
