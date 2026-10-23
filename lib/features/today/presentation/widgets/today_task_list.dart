library;

import 'package:flutter/material.dart';
import 'package:namma_project/features/today/domain/today_models.dart';

import '../today_state.dart';
import '../today_strings.dart';

class TodayTaskList extends StatefulWidget {
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
  State<TodayTaskList> createState() => _TodayTaskListState();
}

class _TodayTaskListState extends State<TodayTaskList> {
  static const _pageSize = 20;
  int _visibleCount = _pageSize;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final task in widget.tasks.take(_visibleCount))
        _taskTile(context, task),
      for (final task in widget.tasks.take(_visibleCount))
        if (widget.allowActions && _hasError(widget.actions[task.taskId]))
          Text(
            widget.actions[task.taskId]!.phase == TodayActionPhase.uncertain
                ? widget.strings.uncertain
                : widget.actions[task.taskId]!.failure?.messageKey ==
                      'tasks.validation.stale_day'
                ? widget.strings.staleDay
                : widget.strings.saveFailed,
          ),
      if (widget.tasks.length > _visibleCount)
        TextButton(
          key: const Key('today_tasks_show_more'),
          onPressed: () => setState(() => _visibleCount += _pageSize),
          child: Text(widget.strings.showMore),
        ),
    ],
  );

  Widget _taskTile(BuildContext context, TodayTaskReference task) {
    final compact =
        MediaQuery.sizeOf(context).width < 400 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final action = widget.allowActions && widget.onSetCompleted != null
        ? TextButton(
            key: ValueKey('today_task_action_${task.taskId}'),
            onPressed: widget.actions[task.taskId]?.blocksAction == true
                ? null
                : () => widget.onSetCompleted!(task.taskId, !task.isCompleted),
            child: Text(
              widget.actions[task.taskId]?.phase == TodayActionPhase.pending
                  ? widget.strings.saving
                  : task.isCompleted
                  ? widget.strings.reopenTask
                  : widget.strings.completeTask,
            ),
          )
        : Text(
            task.isCompleted ? widget.strings.completed : widget.strings.open,
          );
    final tile = ListTile(
      key: ValueKey('today_task_${task.taskId}'),
      onTap: widget.onOpenTasks,
      leading: Icon(
        task.isCompleted
            ? Icons.check_circle_outline
            : Icons.radio_button_unchecked,
      ),
      title: Text(task.title),
      subtitle: Text(
        [
          widget.strings.formatDate(task.scheduledLocalDate),
          if (task.scheduledMinuteOfDay != null)
            widget.strings.formatTime(task.scheduledMinuteOfDay!),
          if (task.estimatedDurationMinutes != null)
            widget.strings.formatDurationMinutes(
              task.estimatedDurationMinutes!,
            ),
          if (task.isOverdue) widget.strings.overdue,
        ].join(' · '),
      ),
      trailing: compact ? null : action,
    );
    return compact
        ? Column(
            children: [
              tile,
              Align(alignment: AlignmentDirectional.centerEnd, child: action),
            ],
          )
        : tile;
  }

  bool _hasError(TodayActionFeedback? feedback) =>
      feedback?.phase == TodayActionPhase.failed ||
      feedback?.phase == TodayActionPhase.uncertain;
}
