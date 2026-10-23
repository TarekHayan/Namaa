/// Desired-state dispatch to the existing Task and Habit owners.
library;

import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/today_calendar.dart';
import '../domain/today_scope.dart';
import 'today_habits_port.dart';
import 'today_tasks_port.dart';

final class TodayActions {
  const TodayActions({
    required TodayTasksPort tasks,
    required TodayHabitsPort habits,
  }) : _tasks = tasks,
       _habits = habits;

  final TodayTasksPort _tasks;
  final TodayHabitsPort _habits;

  Future<AppResult<void>> setTaskCompleted({
    required TodayScope scope,
    required TodayLocalDate expectedLocalDate,
    required String taskId,
    required bool completed,
  }) => _tasks.setCompleted(
    ownerId: scope.taskOwnerId,
    taskId: taskId,
    expectedLocalDate: expectedLocalDate,
    completed: completed,
  );

  Future<AppResult<void>> setHabitCompleted({
    required TodayScope scope,
    required TodayLocalDate expectedLocalDate,
    required String habitId,
    required bool completed,
  }) => _habits.setCompleted(
    ownerId: scope.habitOwnerId,
    habitId: habitId,
    expectedLocalDate: expectedLocalDate,
    completed: completed,
  );
}
