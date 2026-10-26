import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_projection.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/domain/today_section.dart';
import 'package:namma_project/features/today/presentation/today_dashboard_view.dart';
import 'package:namma_project/features/today/presentation/today_state.dart';
import 'package:namma_project/features/today/presentation/today_strings.dart';
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_dashboard_header.dart';

void main() {
  testWidgets('wide header follows prototype height and sixteen-pixel gap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: TodayDashboardView(
          state: _state(),
          strings: const _Strings(),
          onRefresh: () {},
          onTasks: () {},
          onHabits: () {},
          onMindMaps: () {},
          onPreferences: () {},
          onRetryTasks: () {},
          onRetryHabits: () {},
          onRetryXp: () {},
          onSetTaskCompleted: (_, _) {},
          onSetHabitCompleted: (_, _) {},
          onNewTask: () {},
        ),
      ),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.preferredSize.height, TodayDashboardHeader.toolbarHeight);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(TodayDashboardDateLine),
      ),
      findsOneWidget,
    );
    expect(find.text('Quick add'), findsOneWidget);
    final heroTop = tester.getTopLeft(find.byKey(kDashboardProgressGroup)).dy;
    expect(heroTop, inInclusiveRange(64, 96));
  });

  testWidgets(
    'translucent header keeps its date while content scrolls behind',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          supportedLocales: FoundationLocalizations.supportedLocales,
          home: TodayDashboardView(
            state: _state(),
            strings: const _Strings(),
            onRefresh: () {},
            onTasks: () {},
            onHabits: () {},
            onMindMaps: () {},
            onPreferences: () {},
            onRetryTasks: () {},
            onRetryHabits: () {},
            onRetryXp: () {},
            onSetTaskCompleted: (_, _) {},
            onSetHabitCompleted: (_, _) {},
          ),
        ),
      );

      expect(
        tester
            .widget<Scaffold>(find.byKey(kTodayScreenKey))
            .extendBodyBehindAppBar,
        isTrue,
      );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.preferredSize.height, lessThan(130));
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      final backdrop = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(BackdropFilter),
              matching: find.byType(Container),
            )
            .first,
      );
      final tint = (backdrop.decoration! as BoxDecoration).color!;
      expect(tint.a, greaterThan(0));
      expect(tint.a, lessThan(1));
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.byType(Image)),
        findsNothing,
      );
      expect(find.text('Good morning'), findsOneWidget);

      final date = find.byType(TodayDashboardDateLine);
      expect(date, findsOneWidget);
      final initialDateTop = tester.getTopLeft(date).dy;
      final progress = find.byKey(kDashboardProgressGroup);
      expect(
        tester.getTopLeft(progress).dy,
        greaterThan(appBar.preferredSize.height),
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -170));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(date).dy, initialDateTop);
      expect(
        tester.getTopLeft(progress).dy,
        lessThan(appBar.preferredSize.height),
      );
      expect(find.text('Good morning'), findsOneWidget);
    },
  );

  testWidgets('failed owner sources expose independent retry controls', (
    tester,
  ) async {
    final failure = AppFailure.recoverable(
      category: AppFailureCategory.persistence,
      messageKey: 'todaySourceUnavailable',
      occurredAt: DateTime.utc(2026, 10, 24),
    );
    final state = _state().copyWith(
      tasks: TodaySection<TodayTaskSummary>.unavailable(failure),
      habits: TodaySection<TodayHabitSummary>.unavailable(failure),
      xp: TodaySection<TodayXpSummary>.unavailable(failure),
    );
    var taskRetries = 0;
    var habitRetries = 0;
    var xpRetries = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: TodayDashboardView(
          state: state,
          strings: const _Strings(),
          onRefresh: () {},
          onTasks: () {},
          onHabits: () {},
          onMindMaps: () {},
          onPreferences: () {},
          onRetryTasks: () => taskRetries++,
          onRetryHabits: () => habitRetries++,
          onRetryXp: () => xpRetries++,
          onSetTaskCompleted: (_, _) {},
          onSetHabitCompleted: (_, _) {},
        ),
      ),
    );
    await tester.tap(find.text('Retry Tasks'));
    await tester.tap(find.text('Retry Habits'));
    await tester.tap(find.text('Retry XP'));
    expect((taskRetries, habitRetries, xpRetries), (1, 1, 1));
  });

  testWidgets(
    'Home preserves the eight prototype groups and five destinations',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          supportedLocales: FoundationLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TodayDashboardView(
              state: _state(),
              strings: const _Strings(),
              onRefresh: () {},
              onTasks: () {},
              onHabits: () {},
              onMindMaps: () {},
              onPreferences: () {},
              onRetryTasks: () {},
              onRetryHabits: () {},
              onRetryXp: () {},
              onSetTaskCompleted: (_, _) {},
              onSetHabitCompleted: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      const groups = [
        kDashboardProgressGroup,
        kDashboardPrayerGroup,
        kDashboardQuranGroup,
        kDashboardHubsGroup,
        kDashboardTimelineGroup,
        kDashboardPriorityGroup,
        kDashboardFinanceGroup,
        kDashboardCountersGroup,
      ];
      final yPositions = <double>[];
      for (final group in groups) {
        final finder = find.byKey(group);
        expect(finder, findsOneWidget);
        yPositions.add(tester.getTopLeft(finder).dy);
      }
      for (var index = 1; index < yPositions.length; index++) {
        expect(yPositions[index], greaterThan(yPositions[index - 1]));
      }

      expect(find.byKey(const Key('dashboard_group_habits')), findsNothing);
      expect(find.byKey(const Key('dashboard_group_explore')), findsNothing);
      expect(find.text('Prayer'), findsWidgets);
      expect(find.text('Focus'), findsWidgets);
      expect(find.text('Quran'), findsWidgets);
      expect(find.text('Adhkar'), findsWidgets);
      expect(find.text('Qiyam'), findsWidgets);
      expect(find.text('Counters'), findsWidgets);

      final destinations = tester.widgetList<NavigationDestination>(
        find.descendant(
          of: find.byKey(kTodayBottomNavigationKey),
          matching: find.byType(NavigationDestination),
        ),
      );
      expect(destinations.map((destination) => destination.label).toList(), [
        'Home',
        'Tasks',
        'Track',
        'Personal finances',
        'More',
      ]);
    },
  );
}

TodayState _state() {
  final calendar = TodayCalendar(
    localDate: TodayLocalDate(2024, 3, 11),
    nowUtc: DateTime.utc(2024, 3, 11, 10),
    utcOffsetMinutes: 0,
    dayStartUtc: DateTime.utc(2024, 3, 11),
    nextDayStartUtc: DateTime.utc(2024, 3, 12),
    projectionRevision: 1,
  );
  return TodayState(
    scope: TodayScope.account(accountId: 'owner', generation: 1),
    calendar: calendar,
    tasks: TodaySection.available(
      const TodayTaskSummary(
        items: [],
        completedCount: 0,
        overdueCount: 0,
        doFirst: [],
      ),
    ),
    habits: TodaySection.available(
      const TodayHabitSummary(items: [], completedCount: 0),
    ),
    xp: TodaySection.available(const TodayXpSummary(awards: [], amount: 0)),
  );
}

class _Strings implements TodayStrings {
  const _Strings();
  @override
  String get agenda => 'Agenda';
  @override
  String get appearance => 'Appearance';
  @override
  String get arabic => 'Arabic';
  @override
  String get completed => 'Completed';
  @override
  String get completeHabit => 'Complete habit';
  @override
  String get completeTask => 'Complete task';
  @override
  String get dark => 'Dark';
  @override
  String get doFirst => 'Do first';
  @override
  String get english => 'English';
  @override
  String get habits => 'Habits';
  @override
  String get language => 'Language';
  @override
  String get light => 'Light';
  @override
  String get loading => 'Loading';
  @override
  String get mindMaps => 'Mind maps';
  @override
  String get newHabit => 'New habit';
  @override
  String get newTask => 'New task';
  @override
  String get noHabits => 'No habits';
  @override
  String get noPriorityTasks => 'No priority tasks';
  @override
  String get noTasks => 'No tasks';
  @override
  String get open => 'Open';
  @override
  String get openMatrix => 'Matrix';
  @override
  String get openOverdue => 'Overdue';
  @override
  String get outdated => 'Outdated';
  @override
  String get overdue => 'Overdue';
  @override
  String get preferences => 'Preferences';
  @override
  String get reopenTask => 'Reopen task';
  @override
  String get retry => 'Retry';
  @override
  String get saveFailed => 'Save failed';
  @override
  String get saving => 'Saving';
  @override
  String get showMore => 'Show more';
  @override
  String get staleDay => 'Stale day';
  @override
  String get streak => 'Streak';
  @override
  String get system => 'System';
  @override
  String get tasks => 'Tasks';
  @override
  String get timed => 'Timed';
  @override
  String get title => 'Today';
  @override
  String get uncertain => 'Uncertain';
  @override
  String get unavailable => 'Unavailable';
  @override
  String get undoHabit => 'Undo habit';
  @override
  String get untimed => 'Untimed';
  @override
  String get xp => 'XP';
  @override
  String formatCount(int value) => '$value';
  @override
  String formatDate(TodayLocalDate date) => date.key;
  @override
  String formatDurationMinutes(int minutes) => '$minutes min';
  @override
  String formatPercent(int value) => '$value%';
  @override
  String formatTime(int minuteOfDay) => '$minuteOfDay';
  @override
  String formatXp(int value) => '$value XP';
}
