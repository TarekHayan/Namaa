library;

import 'package:flutter/material.dart';
import 'package:namma_project/features/today/domain/today_models.dart';

import '../today_strings.dart';

class TodayHabitList extends StatelessWidget {
  const TodayHabitList({
    super.key,
    required this.habits,
    required this.strings,
  });
  final List<TodayHabitReference> habits;
  final TodayStrings strings;

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
          trailing: Text(habit.isCompleted ? strings.completed : strings.open),
        ),
    ],
  );
}
