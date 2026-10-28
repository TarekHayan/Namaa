import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/today_localization_adapter.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/app/routing/owner_entry_intent.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/presentation/today_state.dart';
import 'package:namma_project/features/today/presentation/widgets/today_dashboard_header.dart';

TodayState _sampleTodayState() {
  final day = TodayLocalDate(2026, 10, 24);
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
  );
}

void main() {
  testWidgets('owner route carries only a validated one-shot entry intent', (
    tester,
  ) async {
    OwnerEntryIntent? seen;
    final routing = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('Today')),
      cloudSession: const TasksPreviewSession(),
      tasksBuilder: (context, accountId) => Builder(
        builder: (childContext) {
          seen = OwnerEntryIntentScope.maybeOf(childContext);
          return Scaffold(body: Text('Tasks $accountId'));
        },
      ),
    );
    addTearDown(routing.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: routing.router,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
      ),
    );
    routing.router.go(kTasksRoute, extra: OwnerEntryIntent.newTask);
    await tester.pumpAndSettle();
    expect(find.textContaining('Tasks '), findsOneWidget);
    expect(seen, OwnerEntryIntent.newTask);

    routing.router.go(kFoundationRootRoute);
    await tester.pumpAndSettle();
    routing.router.go(
      kTasksRoute,
      extra: <String, Object>{'accountId': 'other'},
    );
    await tester.pumpAndSettle();
    expect(seen, isNull);
  });

  testWidgets(
    'quick-add popup opens New Task / New Habit owner forms and cancellation stays on Today',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      OwnerEntryIntent? taskIntent;
      OwnerEntryIntent? habitIntent;

      final routing = FoundationAppRouter(
        rootBuilder: (context) => Scaffold(
          appBar: TodayDashboardHeader(
            state: _sampleTodayState(),
            strings: resolveTodayStrings(context),
            colors: AppColors.light,
            onPreferences: () {},
            onNewTask: () => unawaited(
              GoRouter.of(
                context,
              ).push<void>(kTasksRoute, extra: OwnerEntryIntent.newTask),
            ),
            onNewHabit: () => unawaited(
              GoRouter.of(
                context,
              ).push<void>(kHabitsRoute, extra: OwnerEntryIntent.newHabit),
            ),
          ),
          body: const Center(child: Text('Today Content')),
        ),
        cloudSession: const TasksPreviewSession(),
        tasksBuilder: (context, accountId) => Builder(
          builder: (childContext) {
            taskIntent = OwnerEntryIntentScope.maybeOf(childContext);
            return Scaffold(
              appBar: AppBar(leading: const BackButton()),
              body: Text('Tasks Form $accountId'),
            );
          },
        ),
        habitsSession: const TasksPreviewSession(),
        habitsBuilder: (context, accountId) => Builder(
          builder: (childContext) {
            habitIntent = OwnerEntryIntentScope.maybeOf(childContext);
            return Scaffold(
              appBar: AppBar(leading: const BackButton()),
              body: Text('Habits Form $accountId'),
            );
          },
        ),
      );
      addTearDown(routing.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: routing.router,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          supportedLocales: FoundationLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      // Find quick-add popup button (with Icons.add_rounded)
      final quickAddBtn = find.byIcon(Icons.add_rounded);
      expect(quickAddBtn, findsOneWidget);

      // 1. Open quick-add and cancel
      await tester.tap(quickAddBtn);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('today_new_task')), findsOneWidget);
      expect(find.byKey(const Key('today_new_habit')), findsOneWidget);

      // Dismiss popup menu without selecting by tapping outside
      await tester.tapAt(const Offset(20, 200));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('today_new_task')), findsNothing);
      expect(find.text('Today Content'), findsOneWidget);
      expect(taskIntent, isNull);
      expect(habitIntent, isNull);

      // 2. Open quick-add and select New Task
      await tester.tap(quickAddBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('today_new_task')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tasks Form'), findsOneWidget);
      expect(taskIntent, OwnerEntryIntent.newTask);

      // Pop back to Today
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Today Content'), findsOneWidget);

      // 3. Open quick-add and select New Habit
      await tester.tap(quickAddBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('today_new_habit')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Habits Form'), findsOneWidget);
      expect(habitIntent, OwnerEntryIntent.newHabit);

      // Pop back to Today
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Today Content'), findsOneWidget);
    },
  );
}
