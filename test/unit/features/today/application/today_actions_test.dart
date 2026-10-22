import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/today/application/today_actions.dart';
import 'package:namma_project/features/today/application/today_habits_port.dart';
import 'package:namma_project/features/today/application/today_tasks_port.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';

class _Tasks implements TodayTasksPort {
  String? owner;
  String? entity;
  bool? desired;
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String taskId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async {
    owner = ownerId;
    entity = taskId;
    desired = completed;
    expect(expectedLocalDate.key, '2026-10-12');
    return const AppResult.success(null);
  }

  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) =>
      const Stream.empty();
}

class _Habits implements TodayHabitsPort {
  String? owner;
  String? entity;
  bool? desired;
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String habitId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async {
    owner = ownerId;
    entity = habitId;
    desired = completed;
    expect(expectedLocalDate.key, '2026-10-12');
    return const AppResult.success(null);
  }

  @override
  Stream<TodayHabitReadSnapshot> watchHabits(String ownerId) =>
      const Stream.empty();
}

void main() {
  test(
    'desired state reaches only the bound owner without reward commands',
    () async {
      final tasks = _Tasks();
      final habits = _Habits();
      final actions = TodayActions(tasks: tasks, habits: habits);
      final scope = TodayScope.preview(
        taskOwnerId: 'tasks-owner',
        habitOwnerId: 'habit-owner',
        generation: 1,
      );
      final day = TodayLocalDate(2026, 10, 12);

      expect(
        (await actions.setTaskCompleted(
          scope: scope,
          expectedLocalDate: day,
          taskId: 'task-a',
          completed: true,
        )).failureOrNull,
        isNull,
      );
      expect(
        (await actions.setHabitCompleted(
          scope: scope,
          expectedLocalDate: day,
          habitId: 'habit-a',
          completed: false,
        )).failureOrNull,
        isNull,
      );
      expect(
        (tasks.owner, tasks.entity, tasks.desired),
        ('tasks-owner', 'task-a', true),
      );
      expect(
        (habits.owner, habits.entity, habits.desired),
        ('habit-owner', 'habit-a', false),
      );
    },
  );
}
