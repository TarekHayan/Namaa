import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

/// A complete owner snapshot. Readers return it only after the final page.
final class HabitRemoteSnapshot {
  HabitRemoteSnapshot({
    required Iterable<Habit> habits,
    required Iterable<HabitDay> days,
  }) : habits = List.unmodifiable(habits),
       days = List.unmodifiable(days);
  final List<Habit> habits;
  final List<HabitDay> days;
}

abstract interface class HabitRemoteReaderPort {
  Future<AppResult<HabitRemoteSnapshot>> readAll(String accountId);
}
