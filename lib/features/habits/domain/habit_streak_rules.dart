import 'habit.dart';
import 'habit_day.dart';

/// Pure, per-Habit projection. The date on a day record is never recalculated
/// from its UTC timestamp or from the viewing device's time zone.
abstract final class HabitStreakRules {
  static int currentStreak({
    required Habit habit,
    required Iterable<HabitDay> days,
    required String todayLocalDate,
  }) {
    final today = parseHabitLocalDate(todayLocalDate);
    if (habit.isDeleted) return 0;
    final byDate = _latestDays(habit, days);
    final firstDate = habit.scheduleRevisions
        .map((revision) => revision.effectiveLocalDate)
        .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
    var streak = 0;
    for (
      var date = today;
      habitLocalDate(date).compareTo(firstDate) >= 0;
      date = date.subtract(const Duration(days: 1))
    ) {
      final key = habitLocalDate(date);
      final completed = byDate[key];
      if (completed != null &&
          completed.isCompleted &&
          completed.earnedWhileDue) {
        // Earned completion survives a weekday removal later on the same date.
        streak++;
      } else if (key != todayLocalDate && habit.isDueOn(key)) {
        // Today is still in progress; only a closed due date breaks a streak.
        break;
      }
    }
    return streak;
  }

  static List<String> completedDates({
    required Habit habit,
    required Iterable<HabitDay> days,
  }) {
    if (habit.isDeleted) return const [];
    final dates = [
      for (final entry in _latestDays(habit, days).entries)
        if (entry.value.isCompleted && entry.value.earnedWhileDue) entry.key,
    ]..sort((a, b) => b.compareTo(a));
    return List.unmodifiable(dates);
  }

  static Map<String, HabitDay> _latestDays(
    Habit habit,
    Iterable<HabitDay> days,
  ) {
    final byDate = <String, HabitDay>{};
    for (final day in days) {
      if (day.accountId != habit.accountId || day.habitId != habit.id) continue;
      final previous = byDate[day.localDate];
      if (previous == null || day.updatedAt.isAfter(previous.updatedAt)) {
        byDate[day.localDate] = day;
      }
    }
    return byDate;
  }
}
