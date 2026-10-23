import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/today/application/today_calendar_port.dart';
import 'package:namma_project/features/today/application/today_habits_port.dart';
import 'package:namma_project/features/today/application/today_tasks_port.dart';
import 'package:namma_project/features/today/application/today_xp_port.dart';
import 'package:namma_project/features/today/data/system_today_calendar.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/presentation/today_cubit.dart';

class _Clock implements TodayCalendarPort {
  DateTime nowUtc = DateTime.utc(2026, 10, 12, 23, 59);
  int offsetMinutes = 0;

  @override
  TodayCalendar sample({required int projectionRevision}) {
    final civil = nowUtc.add(Duration(minutes: offsetMinutes));
    final localDate = TodayLocalDate.fromCivil(civil);
    final midnight = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
    ).subtract(Duration(minutes: offsetMinutes));
    final nextMidnight = DateTime.utc(
      localDate.next.year,
      localDate.next.month,
      localDate.next.day,
    ).subtract(Duration(minutes: offsetMinutes));
    return TodayCalendar(
      localDate: localDate,
      nowUtc: nowUtc,
      utcOffsetMinutes: offsetMinutes,
      dayStartUtc: midnight,
      nextDayStartUtc: nextMidnight,
      projectionRevision: projectionRevision,
    );
  }
}

class _ManualTimer implements Timer {
  _ManualTimer(this.callback);
  final void Function() callback;
  bool active = true;
  int count = 0;
  void fire() {
    if (!active) return;
    count++;
    callback();
  }

  @override
  void cancel() => active = false;
  @override
  bool get isActive => active;
  @override
  int get tick => count;
}

class _Scheduler {
  _ManualTimer? timer;
  Duration? interval;
  Timer schedule(Duration duration, void Function() callback) {
    interval = duration;
    return timer = _ManualTimer(callback);
  }
}

class _Snapshot implements TodayTaskReadSnapshot {
  @override
  String get ownerId => 'tasks';
  final recordedDate = TodayLocalDate(2026, 10, 12);
  @override
  List<TodayTaskReference> project(TodayCalendar calendar) => [
    TodayTaskReference(
      taskId: 'task',
      ownerId: ownerId,
      title: 'Recorded task',
      scheduledLocalDate: recordedDate,
      scheduledMinuteOfDay: null,
      estimatedDurationMinutes: null,
      isCompleted: false,
      isUrgentImportant: false,
      isOverdue: calendar.nowUtc.isAfter(
        DateTime.utc(2026, 10, 12, 23, 59, 30),
      ),
      ownerOrder: 0,
    ),
  ];
}

class _Tasks implements TodayTasksPort {
  final events = StreamController<TodayTaskReadSnapshot>.broadcast(sync: true);
  final pending = Completer<AppResult<void>>();
  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) => events.stream;
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String taskId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) => pending.future;
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
  test('replacing a foreground scope replaces its calendar timer', () async {
    final scheduler = _Scheduler();
    final tasks = _Tasks();
    final cubit = TodayCubit(
      scope: TodayScope.preview(
        taskOwnerId: 'tasks',
        habitOwnerId: 'habits',
        generation: 1,
      ),
      calendar: _Clock(),
      tasks: tasks,
      habits: _Habits(),
      xp: _Xp(),
      foregroundScheduler: scheduler.schedule,
    );
    cubit.resumeForeground();
    final previous = scheduler.timer!;
    cubit.changeScope(
      TodayScope.preview(
        taskOwnerId: 'tasks',
        habitOwnerId: 'habits',
        generation: 2,
      ),
    );
    expect(previous.isActive, isFalse);
    expect(scheduler.timer, isNot(same(previous)));
    expect(scheduler.timer!.isActive, isTrue);
    await cubit.close();
    expect(scheduler.timer!.isActive, isFalse);
    await tasks.events.close();
  });
  test(
    'foreground tick and resume reproject without changing recorded dates',
    () async {
      final clock = _Clock();
      final scheduler = _Scheduler();
      final tasks = _Tasks();
      final snapshot = _Snapshot();
      final cubit = TodayCubit(
        scope: TodayScope.preview(
          taskOwnerId: 'tasks',
          habitOwnerId: 'habits',
          generation: 1,
        ),
        calendar: clock,
        tasks: tasks,
        habits: _Habits(),
        xp: _Xp(),
        foregroundScheduler: scheduler.schedule,
      );
      tasks.events.add(snapshot);
      cubit.resumeForeground();
      expect(
        scheduler.interval,
        lessThanOrEqualTo(const Duration(seconds: 30)),
      );
      expect(cubit.state.tasks.value?.totalCount, 1);
      clock.nowUtc = DateTime.utc(2026, 10, 12, 23, 59, 40);
      scheduler.timer!.fire();
      expect(cubit.state.tasks.value?.overdueCount, 1);
      expect(cubit.state.calendar.projectionRevision, 0);
      clock.nowUtc = DateTime.utc(2026, 10, 13, 0, 1);
      scheduler.timer!.fire();
      expect(cubit.state.calendar.localDate.key, '2026-10-13');
      expect(cubit.state.calendar.projectionRevision, 1);
      expect(cubit.state.tasks.value?.totalCount, 0);
      expect(snapshot.recordedDate.key, '2026-10-12');

      cubit.pauseForeground();
      expect(scheduler.timer!.isActive, isFalse);
      clock.offsetMinutes = -120;
      cubit.resumeForeground();
      expect(cubit.state.calendar.utcOffsetMinutes, -120);
      expect(cubit.state.calendar.localDate.key, '2026-10-12');
      expect(cubit.state.tasks.value?.totalCount, 1);
      await cubit.close();
      await tasks.events.close();
    },
  );

  test(
    'a pending action result from yesterday cannot reappear today',
    () async {
      final clock = _Clock();
      final scheduler = _Scheduler();
      final tasks = _Tasks();
      final cubit = TodayCubit(
        scope: TodayScope.preview(
          taskOwnerId: 'tasks',
          habitOwnerId: 'habits',
          generation: 1,
        ),
        calendar: clock,
        tasks: tasks,
        habits: _Habits(),
        xp: _Xp(),
        foregroundScheduler: scheduler.schedule,
      );
      tasks.events.add(_Snapshot());
      cubit.resumeForeground();
      final write = cubit.setTaskCompleted('task', true);
      clock.nowUtc = DateTime.utc(2026, 10, 13, 0, 1);
      scheduler.timer!.fire();
      tasks.pending.complete(const AppResult.success(null));
      await write;
      expect(cubit.state.taskActions, isEmpty);
      expect(cubit.state.tasks.value?.totalCount, 0);
      await cubit.close();
      await tasks.events.close();
    },
  );

  test('calendar samples successive local midnights across a 23-hour day', () {
    final clock = SystemTodayCalendar(
      utcNow: () => DateTime.utc(2026, 3, 29, 12),
      localCivilAtUtc: (_) => DateTime(2026, 3, 29, 13),
      offsetMinutesAtUtc: (_) => 60,
      localMidnightToUtc: (date) => date.key == '2026-03-29'
          ? DateTime.utc(2026, 3, 28, 23)
          : DateTime.utc(2026, 3, 29, 22),
    );
    final sample = clock.sample(projectionRevision: 0);
    expect(
      sample.nextDayStartUtc.difference(sample.dayStartUtc),
      const Duration(hours: 23),
    );
  });
}
