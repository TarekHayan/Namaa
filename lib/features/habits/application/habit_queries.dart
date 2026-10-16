import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

/// The feature-owned, account-scoped projection consumed by the screen and
/// future Today / Dashboard features. No second stored completion authority.
final class HabitToday {
  const HabitToday({
    required this.habit,
    required this.isDue,
    required this.day,
  });
  final Habit habit;
  final bool isDue;
  final HabitDay? day;
  bool get isCompleted => day?.isCompleted ?? false;
}

abstract final class HabitQueries {
  static List<HabitToday> today({
    required String accountId,
    required String localDate,
    required Iterable<Habit> habits,
    required Iterable<HabitDay> days,
  }) {
    final byHabit = <String, HabitDay>{};
    for (final day in days) {
      if (day.accountId == accountId && day.localDate == localDate) {
        byHabit[day.habitId] = day;
      }
    }
    return List.unmodifiable([
      for (final habit in habits)
        if (habit.accountId == accountId && !habit.isDeleted)
          HabitToday(
            habit: habit,
            isDue: habit.isDueOn(localDate),
            day: byHabit[habit.id],
          ),
    ]);
  }
}
