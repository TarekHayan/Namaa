import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:namma_project/features/today/presentation/today_state.dart';
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_habit_list.dart';
import 'package:namma_project/features/today/presentation/widgets/today_task_list.dart';

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
      isUrgentImportant: true,
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
  Completer<AppResult<void>> save = Completer<AppResult<void>>();
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
        home: Scaffold(
          body: BlocBuilder<TodayCubit, TodayState>(
            bloc: cubit,
            builder: (context, state) {
              final strings = resolveTodayStrings(context);
              return Column(
                children: [
                  TodayTaskList(
                    tasks: state.tasks.value?.items ?? const [],
                    strings: strings,
                    actions: state.taskActions,
                    allowActions: true,
                    onSetCompleted: cubit.setTaskCompleted,
                  ),
                  TodayHabitList(
                    habits: state.habits.value?.items ?? const [],
                    strings: strings,
                    actions: state.habitActions,
                    onSetCompleted: cubit.setHabitCompleted,
                  ),
                ],
              );
            },
          ),
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

  testWidgets(
    'Home Dashboard provides real task completion/opening and read-only habit with More flow',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 2000 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      var tasksOpened = 0;
      var habitsOpened = 0;
      var matrixOpened = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          supportedLocales: FoundationLocalizations.supportedLocales,
          home: TodayScreen(
            cubit: cubit,
            stringsResolver: resolveTodayStrings,
            onTasks: () => tasksOpened++,
            onHabits: () => habitsOpened++,
            onMindMaps: () {},
            onPreferences: () {},
            onTaskMatrix: () => matrixOpened++,
          ),
        ),
      );

      tasks.stream.add(_TaskSnapshot(false));
      habits.stream.add(_HabitSnapshot());
      await tester.pumpAndSettle();

      // 1. Home Habit is read-only: NO inline habit completion action on Home
      expect(
        find.byKey(const ValueKey('today_habit_action_habit')),
        findsNothing,
      );

      // 2. Tapping Habit in Progress Hero directs user to Habits owner screen
      await tester.tap(find.byKey(kTodayHabitsNavigationKey));
      await tester.pumpAndSettle();
      expect(habitsOpened, 1);

      // 3. More -> Habits owner flow
      await tester.tap(find.byKey(kTodayBottomMoreKey));
      await tester.pumpAndSettle();
      expect(find.byKey(kTodayBottomHabitsKey), findsOneWidget);
      await tester.tap(find.byKey(kTodayBottomHabitsKey));
      await tester.pumpAndSettle();
      expect(habitsOpened, 2);

      // 4. Existing Task completion in Do First section
      final taskAction = find.byKey(const ValueKey('today_task_action_task'));
      await tester.scrollUntilVisible(taskAction, 300);
      await tester.pumpAndSettle();
      await tester.tap(taskAction);
      await tester.pump();

      tasks.save.complete(const AppResult.success(null));
      tasks.stream.add(_TaskSnapshot(true));
      await tester.pumpAndSettle();

      // Task completed
      expect(cubit.state.tasks.value?.completedCount, 1);

      // 5. Existing Task opening: Matrix button in Priority section
      final matrixBtn = find.byKey(const Key('today_open_matrix'));
      await tester.scrollUntilVisible(matrixBtn, 300);
      await tester.pumpAndSettle();
      await tester.tap(matrixBtn);
      await tester.pumpAndSettle();
      expect(matrixOpened, 1);
    },
  );
}
