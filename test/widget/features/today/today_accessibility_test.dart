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
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_sidebar.dart';
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
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();

  @override
  Future<AppResult<Habit?>> readHabit({
    required String accountId,
    required String habitId,
  }) async =>
      AppResult.success(_rows().where((h) => h.id == habitId).firstOrNull);

  @override
  Future<AppResult<HabitDay?>> readDay({
    required String accountId,
    required String habitId,
    required String localDate,
  }) async => AppResult.success(
    _days()
        .where((d) => d.habitId == habitId && d.localDate == localDate)
        .firstOrNull,
  );

  @override
  Future<AppResult<void>> commitDay(HabitDayWriteRequest request) async {
    source.completed = true;
    source.updates.add(source);
    return const AppResult.success(null);
  }

  @override
  Future<AppResult<void>> commitHabit(HabitWriteRequest request) async =>
      const AppResult.success(null);

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
      isUrgentImportant: true,
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
  for (var index = 0; index < 120 && !_focusWithin(tester, target); index++) {
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
          Future<void> waitForHabitCompletion() async {
            for (var attempt = 0; attempt < 40; attempt++) {
              if (habits.completed &&
                  cubit.state.habits.value?.completedCount == 1) {
                return;
              }
              await tester.pump(const Duration(milliseconds: 100));
            }
            expect(habits.completed, isTrue);
            expect(cubit.state.habits.value?.completedCount, 1);
          }
          final taskAction = find.byKey(
            const ValueKey('today_task_action_task'),
          );
          if (keyboardOnly) {
            await _activateByKeyboard(tester, taskAction);
            await _activateByKeyboard(tester, find.byKey(kTodayBottomTasksKey));
            await _finishRouteTransition(tester);
            expect(find.byKey(kTasksMobileLayoutKey), findsOneWidget);
            expect(find.byKey(kTasksHistoryFilterKey), findsOneWidget);
            await _activateByKeyboard(tester, find.byType(BackButton));
            await _finishRouteTransition(tester);
            expect(find.byKey(kTodayScreenKey), findsOneWidget);

            // Open Habits via More bottom navigation destination
            await _activateByKeyboard(tester, find.byKey(kTodayBottomMoreKey));
            await tester.pumpAndSettle();
            await _activateByKeyboard(
              tester,
              find.byKey(kTodayBottomHabitsKey),
            );
            await _finishRouteTransition(tester);
            expect(find.byKey(kHabitsMobileLayoutKey), findsOneWidget);
            expect(find.text(_habitTitle), findsOneWidget);
            await _activateByKeyboard(
              tester,
              find.byKey(const ValueKey('habit-complete-habit')),
            );
            await waitForHabitCompletion();
            await _activateByKeyboard(tester, find.byType(BackButton));
            await _finishRouteTransition(tester);
            expect(find.byKey(kTodayScreenKey), findsOneWidget);
          } else {
            await Scrollable.ensureVisible(
              tester.element(taskAction),
              alignment: 0.5,
            );
            await tester.pump();
            await tester.tap(taskAction);
            await tester.pump();

            await tester.tap(find.byKey(kTodayBottomTasksKey));
            await _finishRouteTransition(tester);
            expect(find.byKey(kTasksMobileLayoutKey), findsOneWidget);
            expect(find.byKey(kTasksHistoryFilterKey), findsOneWidget);
            await tester.tap(find.byType(BackButton));
            await _finishRouteTransition(tester);
            expect(find.byKey(kTodayScreenKey), findsOneWidget);

            // Open Habits via More bottom navigation destination
            await tester.tap(find.byKey(kTodayBottomMoreKey));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(kTodayBottomHabitsKey));
            await _finishRouteTransition(tester);
            expect(find.byKey(kHabitsMobileLayoutKey), findsOneWidget);
            expect(find.text(_habitTitle), findsOneWidget);
            await tester.ensureVisible(
              find.byKey(const ValueKey('habit-complete-habit')),
            );
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('habit-complete-habit')),
            );
            await waitForHabitCompletion();
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

  // T024: Dedicated responsive, text-scale, safe-area and overflow test suite
  group('T024 Dashboard Responsive Viewport and Overflow Assertions', () {
    const viewports = [
      (width: 320.0, height: 640.0, name: 'iPhone SE / 320px narrow'),
      (width: 390.0, height: 844.0, name: 'iPhone 14 / 390px standard'),
      (width: 430.0, height: 932.0, name: 'iPhone 14 Pro Max / 430px large'),
    ];

    for (final vp in viewports) {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        testWidgets(
          'Dashboard renders with zero overflow on ${vp.name} in ${locale.languageCode} at 1.5x text scale',
          (tester) async {
            tester.view.physicalSize = Size(vp.width, vp.height);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

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
              await tasks.updates.close();
              await habits.updates.close();
            });

            FlutterErrorDetails? caughtDetails;
            final prevOnError = FlutterError.onError;
            FlutterError.onError = (details) {
              caughtDetails = details;
              prevOnError?.call(details);
            };

            await tester.pumpWidget(
              MaterialApp(
                locale: locale,
                localizationsDelegates:
                    FoundationLocalizations.localizationsDelegates,
                supportedLocales: FoundationLocalizations.supportedLocales,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: TodayScreen(
                    cubit: cubit,
                    stringsResolver: resolveTodayStrings,
                    onTasks: () {},
                    onHabits: () {},
                    onMindMaps: () {},
                    onPreferences: () {},
                  ),
                ),
              ),
            );
            tasks.updates.add(tasks);
            habits.updates.add(habits);
            await tester.pumpAndSettle();

            FlutterError.onError = prevOnError;

            // 1. Assert Directionality
            expect(
              Directionality.of(tester.element(find.byKey(kTodayScreenKey))),
              locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            );

            // 2. Assert all 8 prototype groups exist in the widget tree
            const groups = [
              Key('dashboard_group_progress'),
              Key('dashboard_group_prayer'),
              Key('dashboard_group_quran'),
              Key('dashboard_group_hubs'),
              Key('dashboard_group_timeline'),
              Key('dashboard_group_priority'),
              Key('dashboard_group_finance'),
              Key('dashboard_group_counters'),
            ];
            for (final groupKey in groups) {
              expect(find.byKey(groupKey), findsOneWidget);
            }

            // 3. Assert zero RenderFlex overflow errors
            final exc = tester.takeException();
            if (exc != null) {
              if (caughtDetails != null) {
                debugPrint('CAUGHT STACK TRACE:\n${caughtDetails!.toString()}');
                if (caughtDetails!.informationCollector != null) {
                  for (final node in caughtDetails!.informationCollector!()) {
                    debugPrint('INFO_COLLECTOR:\n${node.toStringDeep()}');
                  }
                }
              } else {
                debugPrint(
                  'OVERFLOW EXCEPTION on ${vp.name} [${locale.languageCode}]: $exc',
                );
              }
            }
            expect(exc, isNull);

            // 4. Assert scrolling to the 8th card (Counters) succeeds and it's visible above bottom nav
            final lastCard = find.byKey(const Key('dashboard_group_counters'));
            await tester.scrollUntilVisible(lastCard, 300);
            await tester.pumpAndSettle();
            expect(lastCard, findsOneWidget);

            // 5. Assert bottom navigation remains present and visible
            expect(find.byKey(kTodayBottomNavigationKey), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets(
      'Dashboard respects safe area insets and provides clearance above bottom navigation',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetPadding();
        });

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
          await tasks.updates.close();
          await habits.updates.close();
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
        tasks.updates.add(tasks);
        habits.updates.add(habits);
        await tester.pumpAndSettle();

        // Bottom nav is within safe area and last card scrolls cleanly
        final lastCard = find.byKey(const Key('dashboard_group_counters'));
        await tester.scrollUntilVisible(lastCard, 300);
        await tester.pumpAndSettle();
        expect(lastCard, findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Dashboard adapts to tablet (768px) and desktop (1200px) widths with constrained content and sidebar',
      (tester) async {
        // Desktop 1200px
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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
          await tasks.updates.close();
          await habits.updates.close();
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
        tasks.updates.add(tasks);
        habits.updates.add(habits);
        await tester.pumpAndSettle();

        // On desktop, sidebar is shown and bottom navigation is hidden
        expect(find.byKey(kTodaySidebarKey), findsOneWidget);
        expect(find.byKey(kTodayBottomNavigationKey), findsNothing);
        expect(tester.takeException(), isNull);

        // Switch to tablet 768px
        tester.view.physicalSize = const Size(768, 1024);
        await tester.pumpAndSettle();

        // On tablet, bottom navigation is shown and sidebar is hidden
        expect(find.byKey(kTodayBottomNavigationKey), findsOneWidget);
        expect(find.byKey(kTodaySidebarKey), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
