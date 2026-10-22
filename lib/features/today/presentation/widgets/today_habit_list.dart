library;

import 'package:flutter/material.dart';
import 'package:namma_project/features/today/domain/today_models.dart';

import '../today_state.dart';
import '../today_strings.dart';

class TodayHabitList extends StatelessWidget {
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
  Widget build(BuildContext context) => Column(
    children: [
      for (final habit in habits)
        ListTile(
          key: ValueKey('today_habit_${habit.habitId}'),
          leading: Icon(
            habit.isCompleted
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
          ),
          title: Text(habit.name),
          subtitle: Text(
            '${strings.streak}: ${strings.formatCount(habit.currentStreak)}',
          ),
          trailing:
              onSetCompleted == null || (!habit.isCompleted && !habit.isDue)
              ? Text(habit.isCompleted ? strings.completed : strings.open)
              : TextButton(
                  key: ValueKey('today_habit_action_${habit.habitId}'),
                  onPressed: actions[habit.habitId]?.blocksAction == true
                      ? null
                      : () =>
                            onSetCompleted!(habit.habitId, !habit.isCompleted),
                  child: Text(
                    actions[habit.habitId]?.phase == TodayActionPhase.pending
                        ? strings.saving
                        : habit.isCompleted
                        ? strings.undoHabit
                        : strings.completeHabit,
                  ),
                ),
        ),
      for (final habit in habits)
        if (actions[habit.habitId] case final feedback?
            when feedback.phase == TodayActionPhase.failed ||
                feedback.phase == TodayActionPhase.uncertain)
          Text(
            feedback.phase == TodayActionPhase.uncertain
                ? strings.uncertain
                : feedback.failure?.messageKey == 'habits.validation.stale_day'
                ? strings.staleDay
                : strings.saveFailed,
          ),
    ],
  );
}
