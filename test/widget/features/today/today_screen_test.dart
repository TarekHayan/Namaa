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

class _MutableClock implements TodayCalendarPort {
  int day = 12;
  @override
  TodayCalendar sample({required int projectionRevision}) => TodayCalendar(
    localDate: TodayLocalDate(2026, 10, day),
    nowUtc: DateTime.utc(2026, 10, day, 12),
    utcOffsetMinutes: 0,
    dayStartUtc: DateTime.utc(2026, 10, day),
    nextDayStartUtc: DateTime.utc(2026, 10, day + 1),
    projectionRevision: projectionRevision,
  );
}

class _TaskSnapshot implements TodayTaskReadSnapshot {
  @override
  String get ownerId => 'owner';
  @override
  List<TodayTaskReference> project(TodayCalendar day) => [
    TodayTaskReference(
      taskId: 'task',
      ownerId: 'owner',
      title: 'Visible Task',
      scheduledLocalDate: day.localDate,
      scheduledMinuteOfDay: 540,
      estimatedDurationMinutes: 30,
      isCompleted: true,
      isUrgentImportant: false,
      isOverdue: false,
      ownerOrder: 0,
    ),
  ];
}

class _ManyTasks implements TodayTaskReadSnapshot {
  @override
  String get ownerId => 'owner';
  @override
  List<TodayTaskReference> project(TodayCalendar day) => [
    for (var index = 0; index < 25; index++)
      TodayTaskReference(
        taskId: 'task-$index',
        ownerId: ownerId,
        title: 'Task $index',
        scheduledLocalDate: day.localDate,
        scheduledMinuteOfDay: null,
        estimatedDurationMinutes: null,
        isCompleted: false,
        isUrgentImportant: false,
        isOverdue: false,
        ownerOrder: index,
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
      ownerId: 'owner',
      name: 'Visible Habit',
      localDate: day.localDate,
      isDue: true,
      isCompleted: false,
      earnedWhileDue: false,
      currentStreak: 3,
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
  final controller = StreamController<TodayTaskReadSnapshot>.broadcast(
    sync: true,
  );
  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) => controller.stream;
}

class _Habits implements TodayHabitsPort {
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String habitId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async => const AppResult.success(null);
  final controller = StreamController<TodayHabitReadSnapshot>.broadcast(
    sync: true,
  );
  @override
  Stream<TodayHabitReadSnapshot> watchHabits(String ownerId) =>
      controller.stream;
}

class _Xp implements TodayXpPort {
  final controller = StreamController<List<TodayAwardReference>>.broadcast(
    sync: true,
  );
  @override
  Stream<List<TodayAwardReference>> watchAwards(String ownerId) =>
      controller.stream;
}

void main() {
  testWidgets('large task agenda loads more without changing owner totals', (
    tester,
  ) async {
    final tasks = _Tasks();
    final habits = _Habits();
    final xp = _Xp();
    final cubit = TodayCubit(
      scope: TodayScope.account(accountId: 'owner', generation: 1),
      calendar: _Clock(),
      tasks: tasks,
      habits: habits,
      xp: xp,
    );
    addTearDown(() async {
      await cubit.close();
      await tasks.controller.close();
      await habits.controller.close();
      await xp.controller.close();
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
    tasks.controller.add(_ManyTasks());
    habits.controller.add(_HabitSnapshot());
    xp.controller.add([]);
    await tester.pump();
    expect(cubit.state.tasks.value?.totalCount, 25);
    expect(find.byKey(const ValueKey('today_task_task-24')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('today_tasks_show_more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('today_tasks_show_more')));
    await tester.pump();
    expect(find.byKey(const ValueKey('today_task_task-24')), findsOneWidget);
    expect(cubit.state.tasks.value?.totalCount, 25);
  });

  testWidgets(
    'resume refreshes the visible local day and marks failed data outdated',
    (tester) async {
      final tasks = _Tasks();
      final habits = _Habits();
      final xp = _Xp();
      final clock = _MutableClock();
      final cubit = TodayCubit(
        scope: TodayScope.account(accountId: 'owner', generation: 1),
        calendar: clock,
        tasks: tasks,
        habits: habits,
        xp: xp,
      );
      addTearDown(() async {
        await cubit.close();
        await tasks.controller.close();
        await habits.controller.close();
        await xp.controller.close();
      });
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
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
      tasks.controller.add(_TaskSnapshot());
      habits.controller.add(_HabitSnapshot());
      xp.controller.add([]);
      await tester.pump();
      tasks.controller.addError(StateError('offline'));
      await tester.pump();
      expect(
        find.text('Showing older information. Try again to update it.'),
        findsOneWidget,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      clock.day = 13;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(cubit.state.calendar.localDate, TodayLocalDate(2026, 10, 13));
      expect(find.text('Visible Task'), findsNothing);
      expect(find.text('This section is unavailable right now.'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('renders independent read-only summaries and owner navigation', (
    tester,
  ) async {
    final tasks = _Tasks();
    final habits = _Habits();
    final xp = _Xp();
    final cubit = TodayCubit(
      scope: TodayScope.account(accountId: 'owner', generation: 1),
      calendar: _Clock(),
      tasks: tasks,
      habits: habits,
      xp: xp,
    );
    addTearDown(() async {
      await cubit.close();
      await tasks.controller.close();
      await habits.controller.close();
      await xp.controller.close();
    });
    var taskOpens = 0;
    var habitOpens = 0;
    var mapOpens = 0;
    var preferenceOpens = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: TodayScreen(
          cubit: cubit,
          stringsResolver: resolveTodayStrings,
          onTasks: () => taskOpens++,
          onHabits: () => habitOpens++,
          onMindMaps: () => mapOpens++,
          onPreferences: () => preferenceOpens++,
        ),
      ),
    );
    expect(find.text('Loading this section…'), findsNWidgets(3));
    tasks.controller.add(_TaskSnapshot());
    habits.controller.add(_HabitSnapshot());
    xp.controller.add([
      TodayAwardReference(
        ownerId: 'owner',
        source: 'task_done',
        sourceId: 'task',
        amount: 15,
        awardedAtUtc: DateTime.utc(2026, 10, 12, 8),
      ),
    ]);
    await tester.pump();
    expect(find.text('Visible Task'), findsOneWidget);
    expect(find.text('Visible Habit'), findsOneWidget);
    expect(find.textContaining('100%'), findsOneWidget);
    expect(find.text('0/1 · 0%'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.byKey(kTodayTasksNavigationKey));
    await tester.scrollUntilVisible(find.byKey(kTodayHabitsNavigationKey), 250);
    await tester.tap(find.byKey(kTodayHabitsNavigationKey));
    await tester.tap(find.byKey(kTodayPreferencesKey));
    expect(taskOpens, 1);
    expect(habitOpens, 1);
    expect(preferenceOpens, 1);
    await tester.scrollUntilVisible(
      find.byKey(kTodayMindMapsNavigationKey),
      300,
    );
    await tester.tap(find.byKey(kTodayMindMapsNavigationKey));
    expect(mapOpens, 1);
  });
}
