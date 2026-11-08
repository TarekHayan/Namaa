import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/today/application/today_calendar_port.dart';
import 'package:namma_project/features/today/application/today_habits_port.dart';
import 'package:namma_project/features/today/application/today_prayer_port.dart';
import 'package:namma_project/features/today/application/today_tasks_port.dart';
import 'package:namma_project/features/today/application/today_xp_port.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_prayer_reference.dart';
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
  _TaskSnapshot(this.ownerId);
  @override
  final String ownerId;
  @override
  List<TodayTaskReference> project(TodayCalendar calendar) => [
    TodayTaskReference(
      taskId: 'one',
      ownerId: ownerId,
      title: 'One',
      scheduledLocalDate: calendar.localDate,
      scheduledMinuteOfDay: null,
      estimatedDurationMinutes: null,
      isCompleted: true,
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
  List<TodayHabitReference> project(TodayCalendar calendar) => [];
}

class _Tasks implements TodayTasksPort {
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String taskId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async => const AppResult.success(null);
  final a = StreamController<TodayTaskReadSnapshot>.broadcast(sync: true);
  final b = StreamController<TodayTaskReadSnapshot>.broadcast(sync: true);
  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) =>
      ownerId == 'a' ? a.stream : b.stream;
}

class _Habits implements TodayHabitsPort {
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String habitId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async => const AppResult.success(null);
  final stream = StreamController<TodayHabitReadSnapshot>.broadcast(sync: true);
  @override
  Stream<TodayHabitReadSnapshot> watchHabits(String ownerId) => stream.stream;
}

class _Xp implements TodayXpPort {
  final stream = StreamController<List<TodayAwardReference>>.broadcast(
    sync: true,
  );
  @override
  Stream<List<TodayAwardReference>> watchAwards(String ownerId) =>
      stream.stream;
}

class _Prayer implements TodayPrayerPort {
  final a = StreamController<TodayPrayerReference>.broadcast(sync: true);
  final b = StreamController<TodayPrayerReference>.broadcast(sync: true);

  @override
  Stream<TodayPrayerReference> watchPrayer(String ownerId) =>
      ownerId == 'a' ? a.stream : b.stream;

  Future<void> close() async {
    await a.close();
    await b.close();
  }
}

TodayPrayerReference _prayerFor(
  String owner,
  String city, {
  String date = '2026-10-12',
}) => TodayPrayerReference(
  ownerId: owner,
  city: city,
  timeZoneId: 'Africa/Cairo',
  localDate: date,
  nextName: PrayerName.asr,
  nextUtc: DateTime.utc(2026, 10, 12, 13),
  followingName: PrayerName.maghrib,
  followingUtc: DateTime.utc(2026, 10, 12, 16),
  nowUtc: DateTime.utc(2026, 10, 12, 12),
);

void main() {
  test('Prayer follows the exact owner and can retry independently', () async {
    final tasks = _Tasks();
    final habits = _Habits();
    final xp = _Xp();
    final prayer = _Prayer();
    final cubit = TodayCubit(
      scope: TodayScope.account(accountId: 'a', generation: 1),
      calendar: _Clock(),
      tasks: tasks,
      habits: habits,
      xp: xp,
      prayer: prayer,
    );
    prayer.a.add(_prayerFor('b', 'Wrong owner'));
    expect(cubit.state.prayer!.status, TodaySectionStatus.loading);
    prayer.a.add(_prayerFor('a', 'Cairo'));
    expect(cubit.state.prayer!.value?.city, 'Cairo');
    cubit.changeScope(TodayScope.account(accountId: 'b', generation: 2));
    expect(cubit.state.prayer!.value, isNull);
    prayer.a.add(_prayerFor('a', 'Stale'));
    expect(cubit.state.prayer!.value, isNull);
    prayer.b.addError(StateError('offline'));
    expect(cubit.state.prayer!.status, TodaySectionStatus.unavailable);
    cubit.retryPrayer();
    prayer.b.add(_prayerFor('b', 'Dubai', date: '2026-10-13'));
    tasks.b.add(_TaskSnapshot('b'));
    expect(cubit.state.prayer!.value?.city, 'Dubai');
    expect(cubit.state.prayer!.value?.localDate, '2026-10-13');
    expect(
      cubit.state.tasks.value?.items.single.scheduledLocalDate,
      TodayLocalDate(2026, 10, 12),
    );
    await cubit.close();
    await tasks.a.close();
    await tasks.b.close();
    await habits.stream.close();
    await xp.stream.close();
    await prayer.close();
  });

  test(
    'each source becomes available independently; identity change clears old values',
    () async {
      final tasks = _Tasks();
      final habits = _Habits();
      final xp = _Xp();
      final cubit = TodayCubit(
        scope: TodayScope.account(accountId: 'a', generation: 1),
        calendar: _Clock(),
        tasks: tasks,
        habits: habits,
        xp: xp,
      );
      expect(cubit.state.tasks.status, TodaySectionStatus.loading);
      tasks.a.add(_TaskSnapshot('a'));
      expect(cubit.state.tasks.value?.percent, 100);
      expect(cubit.state.habits.status, TodaySectionStatus.loading);
      habits.stream.add(_HabitSnapshot('a'));
      expect(cubit.state.habits.status, TodaySectionStatus.empty);
      xp.stream.add([]);
      expect(cubit.state.xp.value?.amount, 0);
      cubit.changeScope(TodayScope.account(accountId: 'b', generation: 2));
      expect(cubit.state.tasks.value, isNull);
      expect(cubit.state.habits.value, isNull);
      expect(cubit.state.xp.value, isNull);
      tasks.a.add(_TaskSnapshot('a'));
      expect(cubit.state.tasks.value, isNull);
      tasks.b.add(_TaskSnapshot('b'));
      expect(cubit.state.tasks.value?.items.single.ownerId, 'b');
      await cubit.close();
      await tasks.a.close();
      await tasks.b.close();
      await habits.stream.close();
      await xp.stream.close();
    },
  );

  test(
    'source failure does not turn other sections into zero or block them',
    () async {
      final tasks = _Tasks();
      final habits = _Habits();
      final xp = _Xp();
      final cubit = TodayCubit(
        scope: TodayScope.account(accountId: 'a', generation: 1),
        calendar: _Clock(),
        tasks: tasks,
        habits: habits,
        xp: xp,
        initialDeadline: const Duration(milliseconds: 20),
      );
      tasks.a.addError(StateError('offline'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(cubit.state.tasks.status, TodaySectionStatus.unavailable);
      expect(cubit.state.habits.status, TodaySectionStatus.unavailable);
      xp.stream.add([]);
      expect(cubit.state.xp.status, TodaySectionStatus.unavailable);
      cubit.retryXp();
      xp.stream.add([]);
      expect(cubit.state.xp.status, TodaySectionStatus.empty);
      await cubit.close();
      await tasks.a.close();
      await tasks.b.close();
      await habits.stream.close();
      await xp.stream.close();
    },
  );
}
