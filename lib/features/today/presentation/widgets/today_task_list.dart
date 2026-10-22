library;

import 'package:flutter/material.dart';
import 'package:namma_project/features/today/domain/today_models.dart';

import '../today_strings.dart';

class TodayTaskList extends StatelessWidget {
  const TodayTaskList({super.key, required this.tasks, required this.strings});
  final List<TodayTaskReference> tasks;
  final TodayStrings strings;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final task in tasks)
        ListTile(
          key: ValueKey('today_task_${task.taskId}'),
          leading: Icon(
            task.isCompleted
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
          ),
          title: Text(task.title),
          subtitle: Text(
            [
              strings.formatDate(task.scheduledLocalDate),
              if (task.scheduledMinuteOfDay != null)
                strings.formatTime(task.scheduledMinuteOfDay!),
              if (task.isOverdue) strings.overdue,
            ].join(' · '),
          ),
          trailing: Text(task.isCompleted ? strings.completed : strings.open),
        ),
    ],
  );
}
