import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/habits_strings_adapter.dart';
import 'package:namma_project/app/l10n/tasks_strings_adapter.dart';
import 'package:namma_project/app/l10n/today_localization_adapter.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/habits/presentation/habits_cubit.dart';
import 'package:namma_project/features/habits/presentation/habits_screen.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_completion_unit_of_work.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/tasks/presentation/tasks_cubit.dart';
import 'package:namma_project/features/tasks/presentation/tasks_screen.dart';
import 'package:namma_project/features/today/application/today_calendar_port.dart';
import 'package:namma_project/features/today/application/today_habits_port.dart';
import 'package:namma_project/features/today/application/today_tasks_port.dart';
import 'package:namma_project/features/today/application/today_xp_port.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/presentation/today_cubit.dart';
import 'package:namma_project/features/today/presentation/today_screen.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

const _ownerId = 'owner';
const _taskTitle =
    'اقرأ Read and reflect on a very long mixed-language task title';
const _habitTitle = 'مراجعة Review a long habit title in both languages';

final class _Session implements CloudSessionPort {
  const _Session();
  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);
  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      const AppResult.success(CloudSyncContext(accountId: _ownerId));
  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.value(
    const CloudSessionSnapshot(
      status: CloudSessionStatus.signedIn,
      accountId: _ownerId,
    ),
  );
}

final class _OwnerTasks implements TaskRepository {
  _OwnerTasks(this.source);
  final _Tasks source;
  List<Task> _rows() => [
    Task.restore(
      id: 'task',
      accountId: _ownerId,
      title: _taskTitle,
      scheduledDate: DateTime(2026, 10, 12),
      createdAt: DateTime.utc(2026, 10, 11),
      updatedAt: DateTime.utc(2026, 10, 12, 12),
      completedAt: source.completed ? DateTime.utc(2026, 10, 12, 12) : null,
    ),
  ];
  @override
  Stream<List<Task>> watchTasks(String accountId) => Stream.value(_rows());

  @override
  Stream<List<TaskConflictRecord>> watchConflicts(String accountId) =>
      Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _OwnerHabits implements HabitRepository {
  _OwnerHabits(this.source);
  final _Habits source;
  List<Habit> _rows() => [
    Habit.create(
      id: 'habit',
      accountId: _ownerId,
      name: _habitTitle,
      weekdays: {DateTime.monday},
      revisionId: 'revision',
      createdAt: DateTime.utc(2026, 10, 11),
      effectiveLocalDate: '2026-10-11',
      utcOffsetMinutes: 0,
    ),
  ];
  List<HabitDay> _days() => source.completed
      ? [
          HabitDay.completed(
            accountId: _ownerId,
            habitId: 'habit',
            localDate: '2026-10-12',
            completedAt: DateTime.utc(2026, 10, 12, 12),
            earnedAgainstRevisionId: 'revision',
            recordedUtcOffsetMinutes: 0,
          ),
        ]
      : [];
  @override
  Stream<List<Habit>> watchHabits(String accountId) => Stream.value(_rows());
  @override
  Stream<List<HabitDay>> watchDays(String accountId) => Stream.value(_days());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Awards implements AwardLedgerPort {
  @override
  Stream<List<TaskCompletionAward>> watchAwards(String accountId) =>
      Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnitOfWork implements TaskCompletionUnitOfWork {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

class _Tasks implements TodayTasksPort, TodayTaskReadSnapshot {
  final updates = StreamController<TodayTaskReadSnapshot>.broadcast(sync: true);
  bool completed = false;
  @override
  String get ownerId => 'owner';
  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) => updates.stream;
  @override
  List<TodayTaskReference> project(TodayCalendar day) => [
    TodayTaskReference(
      taskId: 'task',
      ownerId: ownerId,
      title: _taskTitle,
      scheduledLocalDate: day.localDate,
      scheduledMinuteOfDay: null,
      estimatedDurationMinutes: null,
      isCompleted: completed,
      isUrgentImportant: false,
      isOverdue: false,
      ownerOrder: 0,
    ),
  ];
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String taskId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async {
    this.completed = completed;
    updates.add(this);
    return const AppResult.success(null);
  }
}

class _Habits implements TodayHabitsPort, TodayHabitReadSnapshot {
  final updates = StreamController<TodayHabitReadSnapshot>.broadcast(
    sync: true,
  );
  bool completed = false;
  @override
  String get ownerId => 'owner';
  @override
  Stream<TodayHabitReadSnapshot> watchHabits(String ownerId) => updates.stream;
  @override
  List<TodayHabitReference> project(TodayCalendar day) => [
    TodayHabitReference(
      habitId: 'habit',
      ownerId: ownerId,
      name: _habitTitle,
      localDate: day.localDate,
      isDue: true,
      isCompleted: completed,
      earnedWhileDue: completed,
      currentStreak: completed ? 1 : 0,
      ownerOrder: 0,
    ),
  ];
  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String habitId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async {
    this.completed = completed;
    updates.add(this);
    return const AppResult.success(null);
  }
}

class _Xp implements TodayXpPort {
  @override
  Stream<List<TodayAwardReference>> watchAwards(String ownerId) =>
      Stream.value([]);
}

bool _focusWithin(WidgetTester tester, Finder target) {
  if (target.evaluate().isEmpty) return false;
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;
  final targetElement = tester.element(target);
  if (identical(focusContext, targetElement)) return true;
  var found = false;
  focusContext.visitAncestorElements((ancestor) {
    found = identical(ancestor, targetElement);
    return !found;
  });
  return found;
}

Future<void> _activateByKeyboard(WidgetTester tester, Finder target) async {
  if (FocusManager.instance.primaryFocus == null) {
    FocusManager.instance.rootScope.requestFocus();
    await tester.pump();
  }
  for (var index = 0; index < 60 && !_focusWithin(tester, target); index++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  expect(
    _focusWithin(tester, target),
    isTrue,
    reason:
        'Control must be reachable using Tab; built=${target.evaluate().length} focus=${FocusManager.instance.primaryFocus?.debugLabel} scroll=${tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels}',
  );
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump();
}

Future<void> _finishRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final keyboardOnly in const [false, true]) {
      testWidgets(
        '${locale.languageCode} ${keyboardOnly ? 'keyboard' : 'touch'} Today journey at narrow width and 1.5x text',
        (tester) async {
          tester.view.physicalSize = const Size(360, 760);
          tester.view.devicePixelRatio = 1;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          final semantics = tester.ensureSemantics();
          final tasks = _Tasks();
          final habits = _Habits();
          final cubit = TodayCubit(
            scope: TodayScope.account(accountId: 'owner', generation: 1),
            calendar: _Clock(),
            tasks: tasks,
            habits: habits,
            xp: _Xp(),
          );
          const session = _Session();
          final ownerTasks = _OwnerTasks(tasks);
          final ownerHabits = _OwnerHabits(habits);
          final taskOwnerCubit = TasksCubit(
            repository: ownerTasks,
            commands: TaskCommands(
              repository: ownerTasks,
              session: session,
              localDate: () => DateTime(2026, 10, 12),
            ),
            completionService: TaskCompletionService(
              repository: ownerTasks,
              unitOfWork: _UnitOfWork(),
              session: session,
            ),
            awardLedger: _Awards(),
            localDate: () => DateTime(2026, 10, 12),
            nowUtc: () => DateTime.utc(2026, 10, 12, 12),
          );
          final habitOwnerCubit = HabitsCubit(
            repository: ownerHabits,
            commands: HabitCommands(
              repository: ownerHabits,
              session: session,
              localCalendar: () =>
                  (localDate: '2026-10-12', utcOffsetMinutes: 0),
            ),
            localCalendar: () => (localDate: '2026-10-12', utcOffsetMinutes: 0),
          );
          late final FoundationAppRouter routing;
          routing = FoundationAppRouter(
            rootBuilder: (context) => TodayScreen(
              cubit: cubit,
              stringsResolver: resolveTodayStrings,
              onTasks: () => GoRouter.of(context).push<void>(kTasksRoute),
              onHabits: () => GoRouter.of(context).push<void>(kHabitsRoute),
              onMindMaps: () {},
              onPreferences: () {},
            ),
            cloudSession: session,
            tasksBuilder: (_, accountId) => TasksScreen(
              cubit: taskOwnerCubit,
              accountId: accountId,
              stringsResolver: resolveTasksStrings,
            ),
            habitsSession: session,
            habitsBuilder: (_, accountId) => HabitsScreen(
              cubit: habitOwnerCubit,
              accountId: accountId,
              stringsResolver: resolveHabitsStrings,
            ),
          );
          addTearDown(() async {
            routing.dispose();
            await cubit.close();
            await taskOwnerCubit.close();
            await habitOwnerCubit.close();
            await tasks.updates.close();
            await habits.updates.close();
          });
          await tester.pumpWidget(
            MaterialApp.router(
              locale: locale,
              localizationsDelegates:
                  FoundationLocalizations.localizationsDelegates,
              supportedLocales: FoundationLocalizations.supportedLocales,
              routerConfig: routing.router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
            ),
          );
          tasks.updates.add(tasks);
          habits.updates.add(habits);
          await tester.pump();
          expect(
            Directionality.of(tester.element(find.byKey(kTodayScreenKey))),
            locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          expect(cubit.state.tasks.value?.totalCount, 1);
          expect(cubit.state.habits.value?.totalCount, 1);
          expect(
            find.byTooltip(
              resolveTodayStrings(
                tester.element(find.byKey(kTodayScreenKey)),
              ).preferences,
            ),
            findsOneWidget,
          );
          final clock = Stopwatch()..start();
          final taskAction = find.byKey(
            const ValueKey('today_task_action_task'),
          );
          final habitAction = find.byKey(
            const ValueKey('today_habit_action_habit'),
          );
          if (keyboardOnly) {
            await _activateByKeyboard(tester, taskAction);
            await _activateByKeyboard(
              tester,
              find.byKey(kTodayTasksNavigationKey),
            );
            await _finishRouteTransition(tester);
            expect(find.byKey(kTasksMobileLayoutKey), findsOneWidget);
            expect(find.byKey(kTasksHistoryFilterKey), findsOneWidget);
            await _activateByKeyboard(tester, find.byType(BackButton));
            await _finishRouteTransition(tester);
            expect(find.byKey(kTodayScreenKey), findsOneWidget);
            await _activateByKeyboard(tester, habitAction);
            await _activateByKeyboard(
              tester,
              find.byKey(kTodayHabitsNavigationKey),
            );
            await _finishRouteTransition(tester);
            expect(find.byKey(kHabitsMobileLayoutKey), findsOneWidget);
            expect(find.text(_habitTitle), findsOneWidget);
            await _activateByKeyboard(tester, find.byType(BackButton));
            await _finishRouteTransition(tester);
            expect(find.byKey(kTodayScreenKey), findsOneWidget);
          } else {
            await tester.ensureVisible(taskAction);
            await tester.pump();
            await tester.tap(taskAction);
            await tester.pump();
            await tester.scrollUntilVisible(habitAction, 200);
            await tester.ensureVisible(habitAction);
            await tester.pump();
            await tester.tap(habitAction);
            await tester.pump();
            await tester.scrollUntilVisible(
              find.byKey(kTodayTasksNavigationKey),
              -200,
            );
            await tester.ensureVisible(find.byKey(kTodayTasksNavigationKey));
            await tester.pump();
            await tester.tap(find.byKey(kTodayTasksNavigationKey));
            await _finishRouteTransition(tester);
            expect(find.byKey(kTasksMobileLayoutKey), findsOneWidget);
            expect(find.byKey(kTasksHistoryFilterKey), findsOneWidget);
            await tester.tap(find.byType(BackButton));
            await _finishRouteTransition(tester);
            expect(find.byKey(kTodayScreenKey), findsOneWidget);
            await tester.scrollUntilVisible(
              find.byKey(kTodayHabitsNavigationKey),
              200,
            );
            await tester.ensureVisible(find.byKey(kTodayHabitsNavigationKey));
            await tester.pump();
            await tester.tap(find.byKey(kTodayHabitsNavigationKey));
            await _finishRouteTransition(tester);
            expect(find.byKey(kHabitsMobileLayoutKey), findsOneWidget);
            expect(find.text(_habitTitle), findsOneWidget);
            await tester.tap(find.byType(BackButton));
            await _finishRouteTransition(tester);
            expect(find.byKey(kTodayScreenKey), findsOneWidget);
          }
          clock.stop();
          expect(cubit.state.tasks.value?.completedCount, 1);
          expect(cubit.state.habits.value?.completedCount, 1);
          expect(clock.elapsed, lessThan(const Duration(minutes: 3)));
          semantics.dispose();
        },
      );
    }
  }
}
