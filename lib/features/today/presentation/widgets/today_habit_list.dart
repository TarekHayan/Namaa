library;

import 'package:flutter/material.dart';
import 'package:namma_project/features/today/domain/today_models.dart';

import '../today_state.dart';
import '../today_strings.dart';

class TodayHabitList extends StatefulWidget {
  const TodayHabitList({
    super.key,
    required this.habits,
    required this.strings,
    this.actions = const {},
    this.onSetCompleted,
  });
  final List<TodayHabitReference> habits;
  final TodayStrings strings;
  final Map<String, TodayActionFeedback> actions;
  final void Function(String, bool)? onSetCompleted;

  @override
  State<TodayHabitList> createState() => _TodayHabitListState();
}

class _TodayHabitListState extends State<TodayHabitList> {
  static const _pageSize = 20;
  int _visibleCount = _pageSize;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final habit in widget.habits.take(_visibleCount))
        _habitTile(context, habit),
      for (final habit in widget.habits.take(_visibleCount))
        if (widget.actions[habit.habitId] case final feedback?
            when feedback.phase == TodayActionPhase.failed ||
                feedback.phase == TodayActionPhase.uncertain)
          Text(
            feedback.phase == TodayActionPhase.uncertain
                ? widget.strings.uncertain
                : feedback.failure?.messageKey == 'habits.validation.stale_day'
                ? widget.strings.staleDay
                : widget.strings.saveFailed,
          ),
      if (widget.habits.length > _visibleCount)
        TextButton(
          key: const Key('today_habits_show_more'),
          onPressed: () => setState(() => _visibleCount += _pageSize),
          child: Text(widget.strings.showMore),
        ),
    ],
  );

  Widget _habitTile(BuildContext context, TodayHabitReference habit) {
    final compact =
        MediaQuery.sizeOf(context).width < 400 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final action =
        widget.onSetCompleted == null || (!habit.isCompleted && !habit.isDue)
        ? Text(
            habit.isCompleted ? widget.strings.completed : widget.strings.open,
          )
        : TextButton(
            key: ValueKey('today_habit_action_${habit.habitId}'),
            onPressed: widget.actions[habit.habitId]?.blocksAction == true
                ? null
                : () =>
                      widget.onSetCompleted!(habit.habitId, !habit.isCompleted),
            child: Text(
              widget.actions[habit.habitId]?.phase == TodayActionPhase.pending
                  ? widget.strings.saving
                  : habit.isCompleted
                  ? widget.strings.undoHabit
                  : widget.strings.completeHabit,
            ),
          );
    final tile = ListTile(
      key: ValueKey('today_habit_${habit.habitId}'),
      leading: Icon(
        habit.isCompleted
            ? Icons.check_circle_outline
            : Icons.radio_button_unchecked,
      ),
      title: Text(habit.name),
      subtitle: Text(
        '${widget.strings.streak}: ${widget.strings.formatCount(habit.currentStreak)}',
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
}
