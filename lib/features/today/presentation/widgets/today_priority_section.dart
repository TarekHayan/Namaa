import 'package:flutter/material.dart';

import '../../domain/today_models.dart';
import '../today_strings.dart';

class TodayPrioritySection extends StatelessWidget {
  const TodayPrioritySection({
    super.key,
    required this.tasks,
    required this.strings,
    required this.onOpenTasks,
    required this.onOpenMatrix,
  });

  final List<TodayTaskReference> tasks;
  final TodayStrings strings;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenMatrix;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(strings.doFirst, style: Theme.of(context).textTheme.titleMedium),
      if (tasks.isEmpty) Text(strings.noPriorityTasks),
      for (final task in tasks)
        ListTile(
          key: ValueKey('today_priority_task_${task.taskId}'),
          onTap: onOpenTasks,
          title: Text(task.title),
          subtitle: Text(
            [
              strings.formatDate(task.scheduledLocalDate),
              if (task.isOverdue) strings.overdue,
            ].join(' · '),
          ),
          trailing: const Icon(Icons.open_in_new),
        ),
      TextButton.icon(
        key: const Key('today_open_matrix'),
        onPressed: onOpenMatrix,
        icon: const Icon(Icons.grid_view),
        label: Text(strings.openMatrix),
      ),
    ],
  );
}
