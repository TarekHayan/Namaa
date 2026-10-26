import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/today_localization_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/features/today/domain/today_agenda.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_projection.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/domain/today_section.dart';
import 'package:namma_project/features/today/presentation/today_dashboard_view.dart';
import 'package:namma_project/features/today/presentation/today_state.dart';
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_coming_soon_page.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_sidebar.dart';
import 'package:namma_project/features/today/presentation/widgets/today_timeline_section.dart';

TodayState _createTestState({int xpAmount = 250}) {
  final day = TodayLocalDate(2026, 10, 24);
  final task = TodayTaskReference(
    taskId: 'task-1',
    ownerId: 'test-user',
    title: 'Test urgent task',
    scheduledLocalDate: day,
    scheduledMinuteOfDay: 600,
    estimatedDurationMinutes: 30,
    isCompleted: false,
    isUrgentImportant: true,
    isOverdue: false,
    ownerOrder: 1,
  );
  final habit = TodayHabitReference(
    habitId: 'habit-1',
    ownerId: 'test-user',
    name: 'Test daily habit',
    localDate: day,
    isDue: true,
    isCompleted: false,
    earnedWhileDue: false,
    currentStreak: 3,
    ownerOrder: 1,
  );

  return TodayState.loading(
    TodayScope.account(accountId: 'test-user', generation: 1),
    TodayCalendar(
      localDate: day,
      nowUtc: DateTime.utc(2026, 10, 24, 10),
      utcOffsetMinutes: 180,
      dayStartUtc: DateTime.utc(2026, 10, 24),
      nextDayStartUtc: DateTime.utc(2026, 10, 25),
      projectionRevision: 1,
    ),
  ).copyWith(
    xp: TodaySection<TodayXpSummary>.available(
      TodayXpSummary(awards: const [], amount: xpAmount),
    ),
    tasks: TodaySection<TodayTaskSummary>.available(
      TodayTaskSummary(
        items: [task],
        completedCount: 0,
        overdueCount: 0,
        doFirst: [task],
      ),
    ),
    habits: TodaySection<TodayHabitSummary>.available(
      TodayHabitSummary(items: [habit], completedCount: 0),
    ),
  );
}

Widget _wrapView({
  required TodayState state,
  required VoidCallback onTasks,
  required VoidCallback onHabits,
  required VoidCallback onMindMaps,
  required VoidCallback onPreferences,
  VoidCallback? onNewTask,
  VoidCallback? onNewHabit,
  VoidCallback? onTaskMatrix,
  VoidCallback? onTaskOverdue,
  void Function(String, bool)? onSetTaskCompleted,
}) {
  return MaterialApp(
    localizationsDelegates: FoundationLocalizations.localizationsDelegates,
    supportedLocales: FoundationLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Builder(
      builder: (context) => TodayDashboardView(
        state: state,
        strings: resolveTodayStrings(context),
        onRefresh: () {},
        onTasks: onTasks,
        onHabits: onHabits,
        onMindMaps: onMindMaps,
        onPreferences: onPreferences,
        onNewTask: onNewTask,
        onNewHabit: onNewHabit,
        onTaskMatrix: onTaskMatrix,
        onTaskOverdue: onTaskOverdue,
        onRetryTasks: () {},
        onRetryHabits: () {},
        onRetryXp: () {},
        onSetTaskCompleted: onSetTaskCompleted ?? (_, _) {},
        onSetHabitCompleted: (_, _) {},
      ),
    ),
  );
}

void main() {
  group('T037 Dashboard Navigation Tests', () {
    testWidgets('timeline places timed owner tasks among sample checkpoints', (
      tester,
    ) async {
      TodayTaskReference task(String id, int minute) => TodayTaskReference(
        taskId: id,
        ownerId: 'test-user',
        title: id,
        scheduledLocalDate: TodayLocalDate(2026, 10, 24),
        scheduledMinuteOfDay: minute,
        estimatedDurationMinutes: 30,
        isCompleted: false,
        isUrgentImportant: false,
        isOverdue: false,
        ownerOrder: 1,
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          supportedLocales: FoundationLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => SingleChildScrollView(
                child: TodayTimelineSection(
                  agenda: TodayAgenda(
                    timed: [task('late', 18 * 60), task('early', 5 * 60)],
                    untimed: const [],
                  ),
                  currentMinuteOfDay: 10 * 60,
                  strings: resolveTodayStrings(context),
                  colors: AppColors.light,
                  onOpenTasks: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayTimelineSection)),
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('today_timeline_task_early')))
            .dy,
        lessThan(tester.getTopLeft(find.text(copy.dashboardAdhkarMorning)).dy),
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('today_timeline_task_late')))
            .dy,
        greaterThan(
          tester.getTopLeft(find.text(copy.dashboardFocusPomodoroTitle)).dy,
        ),
      );
    });
    testWidgets('task cards open Tasks while explicit actions complete them', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opens = 0;
      var completions = 0;
      await tester.pumpWidget(
        _wrapView(
          state: _createTestState(),
          onTasks: () => opens++,
          onHabits: () {},
          onMindMaps: () {},
          onPreferences: () {},
          onSetTaskCompleted: (_, _) => completions++,
        ),
      );
      await tester.pumpAndSettle();

      final timelineCard = find.byKey(
        const ValueKey('today_timeline_task_task-1'),
      );
      await Scrollable.ensureVisible(
        tester.element(timelineCard),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(timelineCard);
      expect(opens, 1);
      expect(completions, 0);

      final priorityCard = find.byKey(
        const ValueKey('today_priority_task_task-1'),
      );
      await Scrollable.ensureVisible(
        tester.element(priorityCard),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(priorityCard);
      expect(opens, 2);
      expect(completions, 0);

      await tester.tap(find.byKey(const ValueKey('today_task_action_task-1')));
      expect(completions, 1);
    });

    testWidgets('pending task action is visible and cannot be repeated', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var completions = 0;
      await tester.pumpWidget(
        _wrapView(
          state: _createTestState().copyWith(
            taskActions: const {
              'task-1': TodayActionFeedback(TodayActionPhase.pending, true),
            },
          ),
          onTasks: () {},
          onHabits: () {},
          onMindMaps: () {},
          onPreferences: () {},
          onSetTaskCompleted: (_, _) => completions++,
        ),
      );
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('today_task_action_task-1'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(find.text('Saving…'), findsWidgets);
      expect(tester.widget<IconButton>(action).onPressed, isNull);
      expect(completions, 0);
    });

    testWidgets(
      'Phone bottom navigation handles 5 destinations and More sheet owner links',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var tasksCalled = 0;
        var habitsCalled = 0;
        var mindMapsCalled = 0;
        var preferencesCalled = 0;

        await tester.pumpWidget(
          _wrapView(
            state: _createTestState(),
            onTasks: () => tasksCalled++,
            onHabits: () => habitsCalled++,
            onMindMaps: () => mindMapsCalled++,
            onPreferences: () => preferencesCalled++,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Home destination - tapping Home stays on Home
        await tester.tap(find.text('Home').first);
        await tester.pumpAndSettle();
        expect(find.byKey(kTodayScreenKey), findsOneWidget);

        // 2. Tasks destination
        await tester.tap(find.byKey(kTodayBottomTasksKey));
        await tester.pumpAndSettle();
        expect(tasksCalled, 1);

        // 3. Track destination opens TodayComingSoonPage
        await tester.tap(find.byKey(kTodayBottomTrackKey));
        await tester.pumpAndSettle();
        expect(find.byType(TodayComingSoonPage), findsOneWidget);
        expect(find.text('Track'), findsWidgets);
        expect(find.text('Coming soon'), findsOneWidget);

        // Return to Home via back button
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(TodayComingSoonPage), findsNothing);

        // 4. Finance destination opens TodayComingSoonPage
        await tester.tap(find.byKey(kTodayBottomFinanceKey));
        await tester.pumpAndSettle();
        expect(find.byType(TodayComingSoonPage), findsOneWidget);
        expect(find.text('Finance'), findsWidgets);
        expect(find.text('Coming soon'), findsOneWidget);

        // Return to Home via Back to Home button
        await tester.tap(find.text('Back to Home'));
        await tester.pumpAndSettle();
        expect(find.byType(TodayComingSoonPage), findsNothing);

        // 5. More destination opens bottom sheet
        await tester.tap(find.byKey(kTodayBottomMoreKey));
        await tester.pumpAndSettle();

        // More contains Habits owner link
        expect(find.byKey(kTodayBottomHabitsKey), findsOneWidget);
        await tester.tap(find.byKey(kTodayBottomHabitsKey));
        await tester.pumpAndSettle();
        expect(habitsCalled, 1);

        // Re-open More to test Mind Maps owner link
        await tester.tap(find.byKey(kTodayBottomMoreKey));
        await tester.pumpAndSettle();
        expect(find.byKey(kTodayMoreMindMapsKey), findsOneWidget);
        await tester.tap(find.byKey(kTodayMoreMindMapsKey));
        await tester.pumpAndSettle();
        expect(mindMapsCalled, 1);

        // Re-open More to test Preferences
        await tester.tap(find.byKey(kTodayBottomMoreKey));
        await tester.pumpAndSettle();
        expect(find.byKey(kTodayMorePreferencesKey), findsOneWidget);
        await tester.tap(find.byKey(kTodayMorePreferencesKey));
        await tester.pumpAndSettle();
        expect(preferencesCalled, 1);
      },
    );

    testWidgets(
      'Desktop sidebar exposes all destinations directly and shows XP without level inference',
      (tester) async {
        tester.view.physicalSize = const Size(1280 * 2, 900 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var tasksCalled = 0;
        var habitsCalled = 0;
        var mindMapsCalled = 0;
        var preferencesCalled = 0;

        await tester.pumpWidget(
          _wrapView(
            state: _createTestState(xpAmount: 450),
            onTasks: () => tasksCalled++,
            onHabits: () => habitsCalled++,
            onMindMaps: () => mindMapsCalled++,
            onPreferences: () => preferencesCalled++,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(kTodaySidebarKey), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(kTodaySidebarKey),
            matching: find.text('More'),
          ),
          findsNothing,
        );
        for (final key in [
          kTodaySidebarPrayerKey,
          kTodaySidebarQuranKey,
          kTodaySidebarFocusKey,
          kTodaySidebarAdhkarKey,
          kTodaySidebarQiyamKey,
          kTodaySidebarCountersKey,
        ]) {
          expect(find.byKey(key), findsOneWidget);
        }

        // Tasks in sidebar
        await tester.tap(find.byKey(kTodaySidebarTasksKey));
        await tester.pumpAndSettle();
        expect(tasksCalled, 1);

        // Track in sidebar opens TodayComingSoonPage
        await tester.tap(find.byKey(kTodaySidebarTrackKey));
        await tester.pumpAndSettle();
        expect(find.byType(TodayComingSoonPage), findsOneWidget);
        expect(find.text('Track'), findsWidgets);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(kTodaySidebarPrayerKey));
        await tester.pumpAndSettle();
        expect(find.byType(TodayComingSoonPage), findsOneWidget);
        expect(find.text('Prayer'), findsWidgets);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Finance in sidebar opens TodayComingSoonPage
        await tester.tap(find.byKey(kTodaySidebarFinanceKey));
        await tester.pumpAndSettle();
        expect(find.byType(TodayComingSoonPage), findsOneWidget);
        expect(find.text('Finance'), findsWidgets);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Habits in sidebar
        await tester.tap(find.byKey(kTodaySidebarHabitsKey));
        await tester.pumpAndSettle();
        expect(habitsCalled, 1);

        // Mind Maps in sidebar
        await tester.tap(find.byKey(kTodaySidebarMindMapsKey));
        await tester.pumpAndSettle();
        expect(mindMapsCalled, 1);

        // Preferences in sidebar
        await tester.tap(find.byKey(kTodaySidebarPreferencesKey));
        await tester.pumpAndSettle();
        expect(preferencesCalled, 1);
      },
    );

    testWidgets(
      'Each quick hub opens TodayComingSoonPage with matching title',
      (tester) async {
        tester.view.physicalSize = const Size(400 * 3, 1600 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrapView(
            state: _createTestState(),
            onTasks: () {},
            onHabits: () {},
            onMindMaps: () {},
            onPreferences: () {},
          ),
        );
        await tester.pumpAndSettle();

        final hubTitles = [
          'Prayer',
          'Focus',
          'Quran',
          'Adhkar',
          'Qiyam',
          'Counters',
        ];

        for (final title in hubTitles) {
          final hubFinder = find.descendant(
            of: find.byKey(kDashboardHubsGroup),
            matching: find.text(title),
          );
          expect(hubFinder, findsOneWidget);
          await Scrollable.ensureVisible(
            tester.element(hubFinder),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          await tester.tap(hubFinder);
          await tester.pumpAndSettle();

          expect(find.byType(TodayComingSoonPage), findsOneWidget);
          expect(find.text('Coming soon'), findsOneWidget);

          // Pop back
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      'Each preview card opens TodayComingSoonPage with matching title',
      (tester) async {
        tester.view.physicalSize = const Size(400 * 3, 2400 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrapView(
            state: _createTestState(),
            onTasks: () {},
            onHabits: () {},
            onMindMaps: () {},
            onPreferences: () {},
          ),
        );
        await tester.pumpAndSettle();

        // 1. Prayer Card
        await tester.ensureVisible(find.byKey(kDashboardPrayerGroup));
        await tester.tap(find.byKey(kDashboardPrayerGroup));
        await tester.pumpAndSettle();
        expect(find.byType(TodayComingSoonPage), findsOneWidget);
        expect(find.text('Prayer'), findsWidgets);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // 2. Quran Card
        await tester.ensureVisible(find.byKey(kDashboardQuranGroup));
        final quranBtn = find.descendant(
          of: find.byKey(kDashboardQuranGroup),
          matching: find.text('Continue reading'),
        );
        await tester.ensureVisible(quranBtn);
        await tester.tap(quranBtn);
        await tester.pumpAndSettle();
        expect(find.byType(TodayComingSoonPage), findsOneWidget);
        expect(find.text('Quran'), findsWidgets);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // 3. Finance Card
        await tester.ensureVisible(find.byKey(kDashboardFinanceGroup));
        final financeDetails = find.descendant(
          of: find.byKey(kDashboardFinanceGroup),
          matching: find.byIcon(Icons.arrow_forward_ios_rounded),
        );
        await tester.ensureVisible(financeDetails);
        await tester.tap(financeDetails);
        await tester.pumpAndSettle();
        expect(find.byType(TodayComingSoonPage), findsOneWidget);
        expect(find.text('Finance'), findsWidgets);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // 4. Counters Card
        await tester.ensureVisible(find.byKey(kDashboardCountersGroup));
        final counterHeader = find.descendant(
          of: find.byKey(kDashboardCountersGroup),
          matching: find.byIcon(Icons.arrow_forward_ios_rounded),
        );
        await tester.ensureVisible(counterHeader);
        await tester.tap(counterHeader);
        await tester.pumpAndSettle();
        expect(find.byType(TodayComingSoonPage), findsOneWidget);
        expect(find.text('Counters'), findsWidgets);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      },
    );
  });
}
