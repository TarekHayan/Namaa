import 'package:flutter/material.dart';

import '../application/map_task_link_port.dart';
import 'mind_maps_strings.dart';

const Key kMindMapTaskPickerKey = Key('mind_map_task_picker');

Future<String?> showMapTaskPicker({
  required BuildContext context,
  required MapTaskLinkPort tasks,
  required String ownerId,
  required MindMapsStrings strings,
}) => showDialog<String>(
  context: context,
  builder: (context) => Dialog(
    key: kMindMapTaskPickerKey,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460, maxHeight: 520),
      child: _TaskChooser(tasks: tasks, ownerId: ownerId, strings: strings),
    ),
  ),
);

class _TaskChooser extends StatefulWidget {
  const _TaskChooser({
    required this.tasks,
    required this.ownerId,
    required this.strings,
  });
  final MapTaskLinkPort tasks;
  final String ownerId;
  final MindMapsStrings strings;

  @override
  State<_TaskChooser> createState() => _TaskChooserState();
}

class _TaskChooserState extends State<_TaskChooser> {
  late Future<bool> _ready = _load();
  late final Stream<List<MapLinkedTask>> _availableTasks = widget.tasks
      .watchAccessibleTasks(widget.ownerId);
  String _search = '';

  Future<bool> _load() async =>
      (await widget.tasks.ensurePickerReady(widget.ownerId)).failureOrNull ==
      null;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.strings.chooseTask,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextField(
          decoration: InputDecoration(labelText: widget.strings.search),
          onChanged: (value) =>
              setState(() => _search = value.trim().toLowerCase()),
        ),
        Expanded(
          child: FutureBuilder<bool>(
            future: _ready,
            builder: (context, ready) {
              if (!ready.hasData) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      Text(widget.strings.loadingTasks),
                    ],
                  ),
                );
              }
              if (ready.data != true) {
                return Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _ready = _load()),
                    icon: const Icon(Icons.refresh),
                    label: Text(widget.strings.retryTasks),
                  ),
                );
              }
              return StreamBuilder<List<MapLinkedTask>>(
                stream: _availableTasks,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(widget.strings.taskLinkFailure));
                  }
                  final matches = (snapshot.data ?? const <MapLinkedTask>[])
                      .where(
                        (task) =>
                            task.available &&
                            (task.title ?? '').toLowerCase().contains(_search),
                      )
                      .toList();
                  if (matches.isEmpty) {
                    return Center(child: Text(widget.strings.noTasks));
                  }
                  return ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final task = matches[index];
                      return ListTile(
                        key: ValueKey('mind-map-task-${task.id}'),
                        title: Text(task.title!),
                        subtitle: Text(
                          task.completed
                              ? widget.strings.statusCompleted
                              : widget.strings.statusNotStarted,
                        ),
                        onTap: () => Navigator.pop(context, task.id),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.strings.cancel),
          ),
        ),
      ],
    ),
  );
}
