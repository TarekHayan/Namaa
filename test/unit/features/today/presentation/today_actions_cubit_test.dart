import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/today/application/today_calendar_port.dart';
import 'package:namma_project/features/today/application/today_habits_port.dart';
import 'package:namma_project/features/today/application/today_tasks_port.dart';
import 'package:namma_project/features/today/application/today_xp_port.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/domain/today_section.dart';
import 'package:namma_project/features/today/presentation/today_cubit.dart';
import 'package:namma_project/features/today/presentation/today_state.dart';

class _Clock implements TodayCalendarPort {
  @override
  TodayCalendar sample({required int projectionRevision}) => TodayCalendar(
    localDate: TodayLocalDate(2026, 10, 12),
    nowUtc: DateTime.utc(2026, 10, 12, 12),
    utcOffsetMinutes: 0,
    dayStartUtc: DateTime.utc(2026, 10, 12),
    nextDayStartUtc: DateTime.utc(2026, 10, 13),
    projectionRevision: projectionRevision,
  );
}

class _Snapshot implements TodayTaskReadSnapshot {
  _Snapshot(this.ownerId, {this.completed = false});
  @override
  final String ownerId;
  final bool completed;
  @override
  List<TodayTaskReference> project(TodayCalendar calendar) => [
    TodayTaskReference(
      taskId: 'task',
      ownerId: ownerId,
      title: 'Task',
      scheduledLocalDate: calendar.localDate,
      scheduledMinuteOfDay: null,
      estimatedDurationMinutes: null,
      isCompleted: completed,
      isUrgentImportant: false,
      isOverdue: false,
      ownerOrder: 0,
    ),
  ];
}

class _Tasks implements TodayTasksPort {
  final stream = StreamController<TodayTaskReadSnapshot>.broadcast(sync: true);
  final pending = Completer<AppResult<void>>();
  int calls = 0;
  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) => stream.stream;
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String taskId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) {
    calls++;
    expect(
      (ownerId, taskId, expectedLocalDate.key, completed),
      ('task-owner', 'task', '2026-10-12', true),
    );
    return pending.future;
  }
}

class _Habits implements TodayHabitsPort {
  @override
  Stream<TodayHabitReadSnapshot> watchHabits(String ownerId) =>
      const Stream.empty();
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String habitId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async => const AppResult.success(null);
}

class _Xp implements TodayXpPort {
  @override
  Stream<List<TodayAwardReference>> watchAwards(String ownerId) =>
      Stream.value([]);
}

void main() {
  test(
    'rapid taps coalesce; old owner result cannot surface after scope change',
    () async {
      final tasks = _Tasks();
      final cubit = TodayCubit(
        scope: TodayScope.preview(
          taskOwnerId: 'task-owner',
          habitOwnerId: 'habit-owner',
          generation: 1,
        ),
        calendar: _Clock(),
        tasks: tasks,
        habits: _Habits(),
        xp: _Xp(),
      );
      tasks.stream.add(_Snapshot('task-owner'));
      expect(cubit.state.tasks.value?.items.single.taskId, 'task');

      final first = cubit.setTaskCompleted('task', true);
      await cubit.setTaskCompleted('task', true);
      expect(tasks.calls, 1);
      expect(cubit.state.taskActions['task']?.phase, TodayActionPhase.pending);
      expect(cubit.state.xp.value?.amount, 0);
      cubit.changeScope(
        TodayScope.preview(
          taskOwnerId: 'new-owner',
          habitOwnerId: 'new-habit-owner',
          generation: 2,
        ),
      );
      tasks.pending.complete(const AppResult.success(null));
      await first;
      expect(cubit.state.taskActions, isEmpty);
      expect(cubit.state.scope.taskOwnerId, 'new-owner');
      await cubit.close();
      await tasks.stream.close();
    },
  );

  test(
    'failed result cannot roll back a newer confirmed owner emission',
    () async {
      final tasks = _Tasks();
      final cubit = TodayCubit(
        scope: TodayScope.preview(
          taskOwnerId: 'task-owner',
          habitOwnerId: 'habit-owner',
          generation: 1,
        ),
        calendar: _Clock(),
        tasks: tasks,
        habits: _Habits(),
        xp: _Xp(),
      );
      tasks.stream.add(_Snapshot('task-owner'));
      final write = cubit.setTaskCompleted('task', true);
      tasks.stream.add(_Snapshot('task-owner', completed: true));
      tasks.pending.complete(
        AppResult.failure(
          AppFailure.recoverable(
            category: AppFailureCategory.persistence,
            messageKey: 'test.uncertain',
            occurredAt: DateTime.utc(2026, 10, 12),
          ),
        ),
      );
      await write;
      expect(cubit.state.tasks.value?.completedCount, 1);
      expect(cubit.state.taskActions, isEmpty);
      await cubit.close();
      await tasks.stream.close();
    },
  );

  test(
    'refresh keeps a failed source stale and disables its actions',
    () async {
      final tasks = _Tasks();
      final cubit = TodayCubit(
        scope: TodayScope.preview(
          taskOwnerId: 'task-owner',
          habitOwnerId: 'habit-owner',
          generation: 1,
        ),
        calendar: _Clock(),
        tasks: tasks,
        habits: _Habits(),
        xp: _Xp(),
      );
      tasks.stream.add(_Snapshot('task-owner'));
      tasks.stream.addError(StateError('source failed'));
      expect(cubit.state.tasks.status, TodaySectionStatus.stale);

      cubit.refresh();
      expect(cubit.state.tasks.status, TodaySectionStatus.stale);
      await cubit.setTaskCompleted('task', true);
      expect(tasks.calls, 0);

      tasks.stream.add(_Snapshot('task-owner'));
      expect(cubit.state.tasks.status, TodaySectionStatus.available);
      final action = cubit.setTaskCompleted('task', true);
      expect(tasks.calls, 1);
      tasks.pending.complete(const AppResult.success(null));
      await action;
      await cubit.close();
      await tasks.stream.close();
    },
  );

  test(
    'rejected and uncertain saves keep owner values and XP unchanged',
    () async {
      for (final category in [
        AppFailureCategory.validation,
        AppFailureCategory.persistence,
      ]) {
        final tasks = _Tasks();
        final cubit = TodayCubit(
          scope: TodayScope.preview(
            taskOwnerId: 'task-owner',
            habitOwnerId: 'habit-owner',
            generation: 1,
          ),
          calendar: _Clock(),
          tasks: tasks,
          habits: _Habits(),
          xp: _Xp(),
        );
        tasks.stream.add(_Snapshot('task-owner'));
        final action = cubit.setTaskCompleted('task', true);
        tasks.pending.complete(
          AppResult.failure(
            AppFailure.recoverable(
              category: category,
              messageKey: 'test.save_failed',
              occurredAt: DateTime.utc(2026, 10, 12),
            ),
          ),
        );
        await action;
        expect(cubit.state.tasks.value?.completedCount, 0);
        expect(cubit.state.xp.value?.amount, 0);
        expect(
          cubit.state.taskActions['task']?.phase,
          category == AppFailureCategory.persistence
              ? TodayActionPhase.uncertain
              : TodayActionPhase.failed,
        );
        if (category == AppFailureCategory.persistence) {
          await cubit.setTaskCompleted('task', true);
          expect(tasks.calls, 1);
        }
        await cubit.close();
        await tasks.stream.close();
      }
    },
  );
}
