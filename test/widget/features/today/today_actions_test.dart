import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/today_localization_adapter.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/today/application/today_calendar_port.dart';
import 'package:namma_project/features/today/application/today_habits_port.dart';
import 'package:namma_project/features/today/application/today_tasks_port.dart';
import 'package:namma_project/features/today/application/today_xp_port.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/presentation/today_cubit.dart';
import 'package:namma_project/features/today/presentation/today_screen.dart';

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
  _TaskSnapshot(this.completed);
  final bool completed;
  @override
  String get ownerId => 'owner';
  @override
  List<TodayTaskReference> project(TodayCalendar day) => [
    TodayTaskReference(
      taskId: 'task',
      ownerId: ownerId,
      title: 'Walk',
      scheduledLocalDate: day.localDate,
      scheduledMinuteOfDay: null,
      estimatedDurationMinutes: null,
      isCompleted: completed,
      isUrgentImportant: false,
      isOverdue: false,
      ownerOrder: 0,
    ),
  ];
}

class _HabitSnapshot implements TodayHabitReadSnapshot {
  @override
  String get ownerId => 'owner';
  @override
  List<TodayHabitReference> project(TodayCalendar day) => [
    TodayHabitReference(
      habitId: 'habit',
      ownerId: ownerId,
      name: 'Read',
      localDate: day.localDate,
      isDue: true,
      isCompleted: false,
      earnedWhileDue: false,
      currentStreak: 0,
      ownerOrder: 0,
    ),
  ];
}

class _Tasks implements TodayTasksPort {
  final stream = StreamController<TodayTaskReadSnapshot>.broadcast(sync: true);
  final save = Completer<AppResult<void>>();
  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) => stream.stream;
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String taskId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) => save.future;
}

class _Habits implements TodayHabitsPort {
  final stream = StreamController<TodayHabitReadSnapshot>.broadcast(sync: true);
  @override
  Stream<TodayHabitReadSnapshot> watchHabits(String ownerId) => stream.stream;
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
  testWidgets('inline action is item-specific and XP remains ledger-owned', (
    tester,
  ) async {
    final tasks = _Tasks();
    final habits = _Habits();
    final cubit = TodayCubit(
      scope: TodayScope.account(accountId: 'owner', generation: 1),
      calendar: _Clock(),
      tasks: tasks,
      habits: habits,
      xp: _Xp(),
    );
    addTearDown(() async {
      await cubit.close();
      await tasks.stream.close();
      await habits.stream.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: TodayScreen(
          cubit: cubit,
          stringsResolver: resolveTodayStrings,
          onTasks: () {},
          onHabits: () {},
          onMindMaps: () {},
          onPreferences: () {},
        ),
      ),
    );
    tasks.stream.add(_TaskSnapshot(false));
    habits.stream.add(_HabitSnapshot());
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('today_task_action_task')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('today_task_action_task')));
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);
    expect(cubit.state.xp.value?.amount, 0);
    expect(
      find.byKey(const ValueKey('today_habit_action_habit')),
      findsOneWidget,
    );
    tasks.save.complete(const AppResult.success(null));
    tasks.stream.add(_TaskSnapshot(true));
    await tester.pump();
    expect(cubit.state.tasks.value?.completedCount, 1);
    expect(cubit.state.xp.value?.amount, 0);
  });
}
