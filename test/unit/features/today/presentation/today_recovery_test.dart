import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/today/application/today_calendar_port.dart';
import 'package:namma_project/features/today/application/today_habits_port.dart';
import 'package:namma_project/features/today/application/today_tasks_port.dart';
import 'package:namma_project/features/today/application/today_xp_port.dart';
import 'package:namma_project/features/today/data/habits_today_adapter.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/domain/today_section.dart';
import 'package:namma_project/features/today/presentation/today_cubit.dart';

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

class _TaskSnapshot implements TodayTaskReadSnapshot {
  _TaskSnapshot(this.ownerId, this.title);
  @override
  final String ownerId;
  final String title;
  @override
  List<TodayTaskReference> project(TodayCalendar day) => [
    TodayTaskReference(
      taskId: 'task',
      ownerId: ownerId,
      title: title,
      scheduledLocalDate: day.localDate,
      scheduledMinuteOfDay: null,
      estimatedDurationMinutes: null,
      isCompleted: false,
      isUrgentImportant: false,
      isOverdue: false,
      ownerOrder: 0,
    ),
  ];
}

class _HabitSnapshot implements TodayHabitReadSnapshot {
  _HabitSnapshot(this.ownerId);
  @override
  final String ownerId;
  @override
  List<TodayHabitReference> project(TodayCalendar day) => [];
}

class _Tasks implements TodayTasksPort {
  final attempts = <StreamController<TodayTaskReadSnapshot>>[];
  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) {
    final stream = StreamController<TodayTaskReadSnapshot>.broadcast(
      sync: true,
    );
    attempts.add(stream);
    return stream.stream;
  }

  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String taskId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async => const AppResult.success(null);
}

class _Habits implements TodayHabitsPort {
  final attempts = <StreamController<TodayHabitReadSnapshot>>[];
  @override
  Stream<TodayHabitReadSnapshot> watchHabits(String ownerId) {
    final stream = StreamController<TodayHabitReadSnapshot>.broadcast(
      sync: true,
    );
    attempts.add(stream);
    return stream.stream;
  }

  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String habitId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async => const AppResult.success(null);
}

class _Xp implements TodayXpPort {
  final attempts = <StreamController<List<TodayAwardReference>>>[];
  @override
  Stream<List<TodayAwardReference>> watchAwards(String ownerId) {
    final stream = StreamController<List<TodayAwardReference>>.broadcast(
      sync: true,
    );
    attempts.add(stream);
    return stream.stream;
  }
}

class _PairedRepository implements HabitRepository {
  final habits = StreamController<List<Habit>>.broadcast(sync: true);
  final days = StreamController<List<HabitDay>>.broadcast(sync: true);
  @override
  Stream<List<Habit>> watchHabits(String accountId) => habits.stream;
  @override
  Stream<List<HabitDay>> watchDays(String accountId) => days.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final hung in ['habit records', 'day records']) {
    test(
      'hanging $hung expires independently and a fresh pair recovers',
      () async {
        final tasks = _Tasks();
        final xp = _Xp();
        final pair = _PairedRepository();
        final cubit = TodayCubit(
          scope: TodayScope.account(accountId: 'owner', generation: 1),
          calendar: _Clock(),
          tasks: tasks,
          habits: HabitsTodayAdapter(pair),
          xp: xp,
          initialDeadline: const Duration(milliseconds: 20),
        );
        tasks.attempts.single.add(_TaskSnapshot('owner', 'Healthy'));
        xp.attempts.single.add([]);
        if (hung == 'habit records') {
          pair.days.add([]);
        } else {
          pair.habits.add([]);
        }
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(cubit.state.tasks.status, TodaySectionStatus.available);
        expect(cubit.state.habits.status, TodaySectionStatus.unavailable);
        expect(cubit.state.xp.status, TodaySectionStatus.empty);
        cubit.retryHabits();
        pair.habits.add([]);
        pair.days.add([]);
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.habits.status, TodaySectionStatus.empty);
        await cubit.close();
        await pair.habits.close();
        await pair.days.close();
        for (final source in tasks.attempts) {
          await source.close();
        }
        for (final source in xp.attempts) {
          await source.close();
        }
      },
    );
  }
  test(
    'each hung source expires within ten seconds without blocking a healthy one',
    () async {
      final tasks = _Tasks();
      final habits = _Habits();
      final xp = _Xp();
      final cubit = TodayCubit(
        scope: TodayScope.account(accountId: 'owner', generation: 1),
        calendar: _Clock(),
        tasks: tasks,
        habits: habits,
        xp: xp,
        initialDeadline: const Duration(milliseconds: 20),
      );
      tasks.attempts.single.add(_TaskSnapshot('owner', 'Healthy'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(cubit.state.tasks.status, TodaySectionStatus.available);
      expect(cubit.state.habits.status, TodaySectionStatus.unavailable);
      expect(cubit.state.xp.status, TodaySectionStatus.unavailable);
      habits.attempts.single.add(_HabitSnapshot('owner'));
      xp.attempts.single.add([]);
      expect(cubit.state.habits.status, TodaySectionStatus.unavailable);
      expect(cubit.state.xp.status, TodaySectionStatus.unavailable);
      cubit.retryHabits();
      cubit.retryXp();
      habits.attempts.last.add(_HabitSnapshot('owner'));
      xp.attempts.last.add([]);
      expect(cubit.state.habits.status, TodaySectionStatus.empty);
      expect(cubit.state.xp.status, TodaySectionStatus.empty);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(cubit.state.tasks.status, TodaySectionStatus.available);
      expect(cubit.state.habits.status, TodaySectionStatus.empty);
      await cubit.close();
      for (final source in tasks.attempts) {
        await source.close();
      }
      for (final source in habits.attempts) {
        await source.close();
      }
      for (final source in xp.attempts) {
        await source.close();
      }
    },
  );

  test(
    'error, retry and late old-attempt events preserve only fresh owner data',
    () async {
      final tasks = _Tasks();
      final habits = _Habits();
      final xp = _Xp();
      final cubit = TodayCubit(
        scope: TodayScope.account(accountId: 'owner', generation: 1),
        calendar: _Clock(),
        tasks: tasks,
        habits: habits,
        xp: xp,
        initialDeadline: const Duration(milliseconds: 20),
      );
      tasks.attempts.single.add(_TaskSnapshot('owner', 'Old'));
      tasks.attempts.single.addError(StateError('read failed'));
      expect(cubit.state.tasks.status, TodaySectionStatus.stale);
      expect(cubit.state.tasks.value?.items.single.title, 'Old');
      cubit.retryTasks();
      expect(tasks.attempts, hasLength(2));
      tasks.attempts.first.add(_TaskSnapshot('owner', 'Late old'));
      expect(cubit.state.tasks.value?.items.single.title, isNot('Late old'));
      tasks.attempts.last.add(_TaskSnapshot('owner', 'Fresh'));
      expect(cubit.state.tasks.status, TodaySectionStatus.available);
      expect(cubit.state.tasks.value?.items.single.title, 'Fresh');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(cubit.state.tasks.status, TodaySectionStatus.available);
      await cubit.close();
      for (final source in tasks.attempts) {
        await source.close();
      }
      for (final source in habits.attempts) {
        await source.close();
      }
      for (final source in xp.attempts) {
        await source.close();
      }
    },
  );

  test(
    'unexpected close and repeated retry affect only that section',
    () async {
      final tasks = _Tasks();
      final habits = _Habits();
      final xp = _Xp();
      final cubit = TodayCubit(
        scope: TodayScope.account(accountId: 'owner', generation: 1),
        calendar: _Clock(),
        tasks: tasks,
        habits: habits,
        xp: xp,
        initialDeadline: const Duration(milliseconds: 20),
      );
      habits.attempts.single.add(_HabitSnapshot('owner'));
      xp.attempts.single.add([]);
      await tasks.attempts.single.close();
      expect(cubit.state.tasks.status, TodaySectionStatus.unavailable);
      expect(cubit.state.habits.status, TodaySectionStatus.empty);
      cubit.retryTasks();
      cubit.retryTasks();
      expect(tasks.attempts, hasLength(3));
      tasks.attempts.last.add(_TaskSnapshot('owner', 'Recovered'));
      expect(cubit.state.tasks.value?.items.single.title, 'Recovered');
      await cubit.close();
      for (final source in tasks.attempts) {
        await source.close();
      }
      for (final source in habits.attempts) {
        await source.close();
      }
      for (final source in xp.attempts) {
        await source.close();
      }
    },
  );
}
