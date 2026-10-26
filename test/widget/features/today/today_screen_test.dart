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
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_coming_soon_page.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_sidebar.dart';

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
      isUrgentImportant: true,
      isOverdue: false,
      ownerOrder: 0,
    ),
  ];
}

class _TenTasksSnapshot implements TodayTaskReadSnapshot {
  @override
  String get ownerId => 'owner';
  @override
  List<TodayTaskReference> project(TodayCalendar day) => [
    for (var index = 0; index < 10; index++)
      TodayTaskReference(
        taskId: 'task-$index',
        ownerId: ownerId,
        title: 'Task $index',
        scheduledLocalDate: day.localDate,
        scheduledMinuteOfDay: 480 + index * 30,
        estimatedDurationMinutes: 25,
        isCompleted: index < 6, // 6 completed, 4 open -> 6/10 (60%)
        isUrgentImportant: index < 2,
        isOverdue: false,
        ownerOrder: index,
      ),
  ];
}

class _FiveHabitsSnapshot implements TodayHabitReadSnapshot {
  @override
  String get ownerId => 'owner';
  @override
  List<TodayHabitReference> project(TodayCalendar day) => [
    for (var index = 0; index < 5; index++)
      TodayHabitReference(
        habitId: 'habit-$index',
        ownerId: ownerId,
        name: 'Habit $index',
        localDate: day.localDate,
        isDue: true,
        isCompleted: index < 2, // 2 completed, 3 open -> 2/5 (40%)
        earnedWhileDue: false,
        currentStreak: 4,
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

class _EmptyTasksSnapshot implements TodayTaskReadSnapshot {
  @override
  String get ownerId => 'owner';
  @override
  List<TodayTaskReference> project(TodayCalendar day) => const [];
}

class _EmptyHabitsSnapshot implements TodayHabitReadSnapshot {
  @override
  String get ownerId => 'owner';
  @override
  List<TodayHabitReference> project(TodayCalendar day) => const [];
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
  testWidgets(
    'ten tasks and five habits prove separate ratios without blended scoring',
    (tester) async {
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

      tasks.controller.add(_TenTasksSnapshot());
      habits.controller.add(_FiveHabitsSnapshot());
      xp.controller.add([
        TodayAwardReference(
          ownerId: 'owner',
          source: 'task_done',
          sourceId: 'task-0',
          amount: 50,
          awardedAtUtc: DateTime.utc(2026, 10, 12, 8),
        ),
        TodayAwardReference(
          ownerId: 'owner',
          source: 'task_done',
          sourceId: 'task-1',
          amount: 100,
          awardedAtUtc: DateTime.utc(2026, 10, 12, 9),
        ),
      ]);
      await tester.pump();

      // Owner totals: 6/10 tasks (60%) and 2/5 habits (40%)
      expect(cubit.state.tasks.value?.totalCount, 10);
      expect(cubit.state.tasks.value?.completedCount, 6);
      expect(cubit.state.habits.value?.totalCount, 5);
      expect(cubit.state.habits.value?.completedCount, 2);

      // Verify separate breakdown readouts without blended scoring
      expect(find.textContaining('6/10 · 60%'), findsOneWidget);
      expect(find.textContaining('2/5 · 40%'), findsOneWidget);

      // Verify XP total readout
      expect(find.textContaining('150 XP'), findsOneWidget);

      // Verify sample overall gauge shows prototype 68%, NOT a blended score ((6+2)/(10+5) = 53%)
      expect(find.text('68%'), findsOneWidget);

      // Verify future domain cards render sample badges
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayScreen)),
      );
      expect(find.text(copy.dashboardSampleBadge), findsWidgets);
    },
  );

  testWidgets(
    'zero-denominator states do not display misleading 0% or 100% progress badges',
    (tester) async {
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

      tasks.controller.add(_EmptyTasksSnapshot());
      habits.controller.add(_EmptyHabitsSnapshot());
      xp.controller.add([]);
      await tester.pump();

      // Zero-denominator ratio displays 0/0 without any percent suffix
      expect(find.text('Tasks: 0/0'), findsOneWidget);
      expect(find.text('Habits: 0/0'), findsOneWidget);

      // Neither 0% nor 100% is displayed for the zero-denominator tasks/habits readouts
      expect(find.textContaining('0/0 · 0%'), findsNothing);
      expect(find.textContaining('0/0 · 100%'), findsNothing);
    },
  );

  testWidgets(
    'section status changes update live sections independently without altering sample cards',
    (tester) async {
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

      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayScreen)),
      );

      // Initially live sections are loading
      expect(find.text('Loading this section…'), findsWidgets);

      // Supply habits successfully while tasks fails
      habits.controller.add(_FiveHabitsSnapshot());
      tasks.controller.add(_TaskSnapshot());
      xp.controller.add([]);
      await tester.pump();

      tasks.controller.addError(StateError('offline'));
      await tester.pump();

      // Tasks live section is outdated
      expect(find.textContaining('Showing older information'), findsWidgets);

      // Habits live section remains healthy
      expect(find.textContaining('2/5 · 40%'), findsOneWidget);

      // Sample preview cards remain unaffected
      expect(find.text(copy.dashboardSampleBadge), findsWidgets);
    },
  );

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
        find.textContaining(
          'Showing older information. Try again to update it.',
        ),
        findsWidgets,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      clock.day = 13;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(cubit.state.calendar.localDate, TodayLocalDate(2026, 10, 13));
      expect(find.text('Visible Task'), findsNothing);
      expect(
        find.textContaining('This section is unavailable right now.'),
        findsWidgets,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('phone has bottom navigation and desktop has side navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    var mapOpens = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: TodayScreen(
          cubit: cubit,
          stringsResolver: resolveTodayStrings,
          onTasks: () => taskOpens++,
          onHabits: () {},
          onMindMaps: () => mapOpens++,
          onPreferences: () {},
        ),
      ),
    );

    tasks.controller.add(_TaskSnapshot());
    habits.controller.add(_HabitSnapshot());
    xp.controller.add([]);
    await tester.pump();

    expect(find.byKey(kTodayBottomNavigationKey), findsOneWidget);
    expect(find.byKey(kTodaySidebarKey), findsNothing);
    await tester.tap(find.byKey(kTodayBottomTasksKey));
    expect(taskOpens, 1);

    await tester.tap(find.byKey(kTodayBottomPrayerKey));
    await tester.pumpAndSettle();
    expect(find.byType(TodayComingSoonPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(TodayComingSoonPage))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kTodayBottomMoreKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kTodayMoreMindMapsKey), findsOneWidget);
    await tester.tap(find.byKey(kTodayMoreMindMapsKey));
    await tester.pumpAndSettle();
    expect(mapOpens, 1);

    await tester.tap(find.byKey(kTodayBottomMoreKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kTodayMorePreferencesKey), findsOneWidget);
    await tester.tap(find.byKey(kTodayMorePreferencesKey));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(kTodayBottomNavigationKey), findsNothing);
    expect(find.byKey(kTodaySidebarKey), findsOneWidget);
    await tester.tap(find.byKey(kTodaySidebarTasksKey));
    expect(taskOpens, 2);
    expect(tester.takeException(), isNull);
  });
}
