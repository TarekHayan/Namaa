import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/today/application/today_adhkar_qiyam_port.dart';
import 'package:namma_project/features/today/application/today_calendar_port.dart';
import 'package:namma_project/features/today/application/today_habits_port.dart';
import 'package:namma_project/features/today/application/today_tasks_port.dart';
import 'package:namma_project/features/today/application/today_xp_port.dart';
import 'package:namma_project/features/today/domain/today_adhkar_qiyam_reference.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/domain/today_section.dart';
import 'package:namma_project/features/today/presentation/today_cubit.dart';

/// T058: Home watches the Adhkar/Qiyam port as its own independent source.
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

class _AdhkarQiyam implements TodayAdhkarQiyamPort {
  final a = StreamController<TodayAdhkarQiyamReference>.broadcast(sync: true);
  final b = StreamController<TodayAdhkarQiyamReference>.broadcast(sync: true);
  final watched = <(String, String?)>[];

  @override
  Stream<TodayAdhkarQiyamReference> watch(
    String ownerId, {
    String? qiyamOwnerId,
  }) {
    watched.add((ownerId, qiyamOwnerId));
    return ownerId == 'a' ? a.stream : b.stream;
  }

  Future<void> close() async {
    await a.close();
    await b.close();
  }
}

TodayAdhkarQiyamReference _reference(
  String owner, {
  int morning = 3,
  bool scheduleUnavailable = false,
  TodayQiyamTonight tonight = TodayQiyamTonight.unanswered,
}) => TodayAdhkarQiyamReference(
  ownerId: owner,
  scheduleUnavailable: scheduleUnavailable,
  adhkarLoadFailed: false,
  morningCompleted: morning,
  morningTotal: 10,
  eveningCompleted: 0,
  eveningTotal: 9,
  period: TodayAdhkarPeriod.morning,
  qiyamLoadFailed: false,
  tonight: tonight,
  adhkarStreak: 2,
  qiyamStreak: 1,
);

TodayCubit _cubit(
  _Tasks tasks,
  _Habits habits,
  _Xp xp,
  TodayAdhkarQiyamPort? source, {
  TodayScope? scope,
  Duration deadline = const Duration(seconds: 10),
}) => TodayCubit(
  scope: scope ?? TodayScope.account(accountId: 'a', generation: 1),
  calendar: _Clock(),
  tasks: tasks,
  habits: habits,
  xp: xp,
  adhkarQiyam: source,
  initialDeadline: deadline,
);

Future<void> _closeAll(_Tasks t, _Habits h, _Xp x, _AdhkarQiyam s) async {
  await t.a.close();
  await t.b.close();
  await h.stream.close();
  await x.stream.close();
  await s.close();
}

void main() {
  test('without a port the section is absent', () async {
    final tasks = _Tasks();
    final habits = _Habits();
    final xp = _Xp();
    final cubit = _cubit(tasks, habits, xp, null);
    expect(cubit.state.adhkarQiyam, isNull);
    await cubit.close();
    await tasks.a.close();
    await tasks.b.close();
    await habits.stream.close();
    await xp.stream.close();
  });

  test('follows the exact owners and ignores another owner\'s value', () async {
    final tasks = _Tasks();
    final habits = _Habits();
    final xp = _Xp();
    final source = _AdhkarQiyam();
    final cubit = _cubit(tasks, habits, xp, source);
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.loading);
    expect(source.watched.single, ('a', 'a'));
    source.a.add(_reference('b', morning: 9));
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.loading);
    source.a.add(_reference('a'));
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.available);
    expect(cubit.state.adhkarQiyam!.value!.morningCompleted, 3);
    // A change of the counts replaces the value in place.
    source.a.add(_reference('a', morning: 4));
    expect(cubit.state.adhkarQiyam!.value!.morningCompleted, 4);
    // Identity change clears the old value and follows the new owner.
    cubit.changeScope(TodayScope.account(accountId: 'b', generation: 2));
    expect(cubit.state.adhkarQiyam!.value, isNull);
    source.a.add(_reference('a', morning: 7));
    expect(cubit.state.adhkarQiyam!.value, isNull);
    source.b.add(_reference('b', morning: 1));
    expect(cubit.state.adhkarQiyam!.value!.morningCompleted, 1);
    await cubit.close();
    await _closeAll(tasks, habits, xp, source);
  });

  test('a preview scope watches the two closed preview owners', () async {
    final tasks = _Tasks();
    final habits = _Habits();
    final xp = _Xp();
    final source = _AdhkarQiyam();
    final cubit = _cubit(
      tasks,
      habits,
      xp,
      source,
      scope: TodayScope.preview(
        taskOwnerId: 'a',
        habitOwnerId: 'h',
        adhkarOwnerId: 'adhkar-owner',
        qiyamOwnerId: 'qiyam-owner',
        generation: 1,
      ),
    );
    expect(source.watched.single, ('adhkar-owner', 'qiyam-owner'));
    await cubit.close();
    await _closeAll(tasks, habits, xp, source);
  });

  test('an unavailable schedule is an empty section, not progress', () async {
    final tasks = _Tasks();
    final habits = _Habits();
    final xp = _Xp();
    final source = _AdhkarQiyam();
    final cubit = _cubit(tasks, habits, xp, source);
    source.a.add(
      _reference(
        'a',
        morning: 0,
        scheduleUnavailable: true,
        tonight: TodayQiyamTonight.locked,
      ),
    );
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.empty);
    await cubit.close();
    await _closeAll(tasks, habits, xp, source);
  });

  test('a failed source never blocks Tasks, Habits or XP, and retries '
      'on its own', () async {
    final tasks = _Tasks();
    final habits = _Habits();
    final xp = _Xp();
    final source = _AdhkarQiyam();
    final cubit = _cubit(tasks, habits, xp, source);
    tasks.a.add(_TaskSnapshot('a'));
    source.a.addError(StateError('offline'));
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.unavailable);
    expect(cubit.state.tasks.status, TodaySectionStatus.available);
    expect(cubit.state.habits.status, TodaySectionStatus.loading);
    xp.stream.add([]);
    expect(cubit.state.xp.status, TodaySectionStatus.empty);
    cubit.retryAdhkarQiyam();
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.loading);
    source.a.add(_reference('a'));
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.available);
    expect(cubit.state.tasks.status, TodaySectionStatus.available);
    await cubit.close();
    await _closeAll(tasks, habits, xp, source);
  });

  test('a source that never answers fails at its own deadline while the '
      'others stay available', () async {
    final tasks = _Tasks();
    final habits = _Habits();
    final xp = _Xp();
    final source = _AdhkarQiyam();
    final cubit = _cubit(
      tasks,
      habits,
      xp,
      source,
      deadline: const Duration(milliseconds: 50),
    );
    tasks.a.add(_TaskSnapshot('a'));
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.loading);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.unavailable);
    expect(cubit.state.tasks.status, TodaySectionStatus.available);
    // A late value after the failure is ignored until a retry.
    source.a.add(_reference('a'));
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.unavailable);
    await cubit.close();
    await _closeAll(tasks, habits, xp, source);
  });

  test('a source that completes without a value is unavailable', () async {
    final tasks = _Tasks();
    final habits = _Habits();
    final xp = _Xp();
    final source = _AdhkarQiyam();
    final cubit = _cubit(tasks, habits, xp, source);
    await source.a.close();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.unavailable);
    await cubit.close();
    await tasks.a.close();
    await tasks.b.close();
    await habits.stream.close();
    await xp.stream.close();
    await source.b.close();
  });

  test('suspend drops the value and stops listening', () async {
    final tasks = _Tasks();
    final habits = _Habits();
    final xp = _Xp();
    final source = _AdhkarQiyam();
    final cubit = _cubit(tasks, habits, xp, source);
    source.a.add(_reference('a'));
    cubit.suspend();
    expect(cubit.state.adhkarQiyam!.status, TodaySectionStatus.loading);
    source.a.add(_reference('a', morning: 8));
    expect(cubit.state.adhkarQiyam!.value, isNull);
    await cubit.close();
    await _closeAll(tasks, habits, xp, source);
  });
}
