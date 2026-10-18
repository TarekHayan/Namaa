import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/habits/domain/habit_streak_rules.dart';

/// Read-only view of one account-owned Habit. No streak is stored separately.
final class HabitHistory {
  HabitHistory({
    required this.habit,
    required this.currentStreak,
    required this.isTodayPending,
    required Iterable<String> completedDates,
  }) : completedDates = List.unmodifiable(completedDates);

  final Habit habit;
  final int currentStreak;
  final bool isTodayPending;
  final List<String> completedDates;
  List<HabitScheduleRevision> get scheduleRevisions => habit.scheduleRevisions;
}

/// The feature-owned, account-scoped projection consumed by the screen and
/// future Today / Dashboard features. No second stored completion authority.
final class HabitToday {
  const HabitToday({
    required this.habit,
    required this.isDue,
    required this.day,
    required this.history,
  });
  final Habit habit;
  final bool isDue;
  final HabitDay? day;
  final HabitHistory history;
  bool get isCompleted => day?.isCompleted ?? false;
  int get currentStreak => history.currentStreak;
}

abstract final class HabitQueries {
  static List<HabitToday> today({
    required String accountId,
    required String localDate,
    required Iterable<Habit> habits,
    required Iterable<HabitDay> days,
  }) {
    final allHabits = habits.toList();
    final allDays = days.toList();
    final byHabit = <String, HabitDay>{};
    for (final day in allDays) {
      if (day.accountId == accountId && day.localDate == localDate) {
        final previous = byHabit[day.habitId];
        if (previous == null || day.updatedAt.isAfter(previous.updatedAt)) {
          byHabit[day.habitId] = day;
        }
      }
    }
    return List.unmodifiable([
      for (final habit in allHabits)
        if (habit.accountId == accountId && !habit.isDeleted)
          HabitToday(
            habit: habit,
            isDue: habit.isDueOn(localDate),
            day: byHabit[habit.id],
            history: history(
              accountId: accountId,
              habitId: habit.id,
              localDate: localDate,
              habits: [habit],
              days: allDays,
            )!,
          ),
    ]);
  }

  static HabitHistory? history({
    required String accountId,
    required String habitId,
    required String localDate,
    required Iterable<Habit> habits,
    required Iterable<HabitDay> days,
  }) {
    parseHabitLocalDate(localDate);
    Habit? selected;
    for (final habit in habits) {
      if (habit.accountId == accountId &&
          habit.id == habitId &&
          !habit.isDeleted) {
        selected = habit;
        break;
      }
    }
    if (selected == null) return null;
    final ownedDays = days
        .where((day) => day.accountId == accountId && day.habitId == habitId)
        .toList();
    HabitDay? todayDay;
    for (final day in ownedDays) {
      if (day.localDate == localDate &&
          (todayDay == null || day.updatedAt.isAfter(todayDay.updatedAt))) {
        todayDay = day;
      }
    }
    return HabitHistory(
      habit: selected,
      currentStreak: HabitStreakRules.currentStreak(
        habit: selected,
        days: ownedDays,
        todayLocalDate: localDate,
      ),
      isTodayPending:
          selected.isDueOn(localDate) && !(todayDay?.isCompleted ?? false),
      completedDates: HabitStreakRules.completedDates(
        habit: selected,
        days: ownedDays,
      ),
    );
  }
}
