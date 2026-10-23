library;

import 'package:flutter/material.dart';
import 'package:namma_project/features/today/domain/today_models.dart';

import '../today_state.dart';
import '../today_strings.dart';

class TodayTaskList extends StatelessWidget {
  const TodayTaskList({
    super.key,
    required this.tasks,
    required this.strings,
    this.actions = const {},
    this.onSetCompleted,
    this.allowActions = false,
    this.onOpenTasks,
  });
  final List<TodayTaskReference> tasks;
  final TodayStrings strings;
  final Map<String, TodayActionFeedback> actions;
  final void Function(String, bool)? onSetCompleted;
  final bool allowActions;
  final VoidCallback? onOpenTasks;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final task in tasks)
        ListTile(
          key: ValueKey('today_task_${task.taskId}'),
          onTap: onOpenTasks,
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
              if (task.estimatedDurationMinutes != null)
                strings.formatDurationMinutes(task.estimatedDurationMinutes!),
              if (task.isOverdue) strings.overdue,
            ].join(' · '),
          ),
          trailing: allowActions && onSetCompleted != null
              ? TextButton(
                  key: ValueKey('today_task_action_${task.taskId}'),
                  onPressed: actions[task.taskId]?.blocksAction == true
                      ? null
                      : () => onSetCompleted!(task.taskId, !task.isCompleted),
                  child: Text(
                    actions[task.taskId]?.phase == TodayActionPhase.pending
                        ? strings.saving
                        : task.isCompleted
                        ? strings.reopenTask
                        : strings.completeTask,
                  ),
                )
              : Text(task.isCompleted ? strings.completed : strings.open),
        ),
      for (final task in tasks)
        if (allowActions && _hasError(actions[task.taskId]))
          Text(
            actions[task.taskId]!.phase == TodayActionPhase.uncertain
                ? strings.uncertain
                : actions[task.taskId]!.failure?.messageKey ==
                      'tasks.validation.stale_day'
                ? strings.staleDay
                : strings.saveFailed,
          ),
    ],
  );

  bool _hasError(TodayActionFeedback? feedback) =>
      feedback?.phase == TodayActionPhase.failed ||
      feedback?.phase == TodayActionPhase.uncertain;
}
