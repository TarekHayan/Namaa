import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/habits_strings_adapter.dart';
import 'package:namma_project/app/routing/owner_entry_intent.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/habits/presentation/habits_cubit.dart';
import 'package:namma_project/features/habits/presentation/habits_screen.dart';

import '../../../support/habits_test_support.dart';

void main() {
  testWidgets(
    'new-Habit intent opens the owner form once; cancel creates nothing',
    (tester) async {
      final repository = _WidgetHabitRepository();
      final clock = HabitsTestClock();
      final cubit = HabitsCubit(
        repository: repository,
        commands: HabitCommands(
          repository: repository,
          session: const HabitsPreviewSession(),
          nowUtc: clock.utcNow,
          localCalendar: clock.captureLocalCalendar,
        ),
        localCalendar: clock.captureLocalCalendar,
      );
      addTearDown(() async {
        await cubit.close();
        await repository.close();
      });
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          supportedLocales: FoundationLocalizations.supportedLocales,
          home: HabitsScreen(
            cubit: cubit,
            accountId: kHabitsPreviewAccountId,
            stringsResolver: resolveHabitsStrings,
            entryIntent: OwnerEntryIntent.newHabit,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(kHabitNameFieldKey), findsOneWidget);
      Navigator.of(tester.element(find.byKey(kHabitNameFieldKey))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(kHabitNameFieldKey), findsNothing);
      expect(repository._habits, isEmpty);
      await tester.pump();
      expect(find.byKey(kHabitNameFieldKey), findsNothing);
    },
  );

  testWidgets('empty, create validation, complete and undo are accessible', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repository = _WidgetHabitRepository();
    final clock = HabitsTestClock();
    final ids = HabitsTestIds();
    final cubit = HabitsCubit(
      repository: repository,
      commands: HabitCommands(
        repository: repository,
        session: const HabitsPreviewSession(),
        nowUtc: clock.utcNow,
        localCalendar: clock.captureLocalCalendar,
        nextHabitId: ids.nextHabitId,
        nextRevisionId: ids.nextRevisionId,
        nextOperationId: ids.nextOperationId,
      ),
      localCalendar: clock.captureLocalCalendar,
    );
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: HabitsScreen(
          cubit: cubit,
          accountId: kHabitsPreviewAccountId,
          stringsResolver: resolveHabitsStrings,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kHabitsEmptyKey), findsOneWidget);
    await tester.tap(find.byKey(kHabitAddButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kHabitSaveButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kHabitNameValidationKey), findsOneWidget);
    await tester.enterText(find.byKey(kHabitNameFieldKey), 'Reading');
    await tester.tap(find.byKey(const Key('habit-weekday-1')));
    await tester.tap(find.byKey(kHabitSaveButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('Reading'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byTooltip('Complete today'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(find.byTooltip('Undo today'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    semantics.dispose();
  });
}

final class _WidgetHabitRepository implements HabitRepository {
  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();
  final Map<String, Habit> _habits = {};
  final Map<String, HabitDay> _days = {};
  final StreamController<List<Habit>> _habitChanges =
      StreamController.broadcast(sync: true);
  final StreamController<List<HabitDay>> _dayChanges =
      StreamController.broadcast(sync: true);

  @override
  Future<AppResult<Habit?>> readHabit({
    required String accountId,
    required String habitId,
  }) async => AppResult.success(
    _habits[habitId]?.accountId == accountId ? _habits[habitId] : null,
  );

  @override
  Future<AppResult<HabitDay?>> readDay({
    required String accountId,
    required String habitId,
    required String localDate,
  }) async => AppResult.success(_days['$accountId:$habitId:$localDate']);

  @override
  Stream<List<Habit>> watchHabits(String accountId) {
    scheduleMicrotask(() => _habitChanges.add(_habits.values.toList()));
    return _habitChanges.stream.map(
      (rows) => rows.where((habit) => habit.accountId == accountId).toList(),
    );
  }

  @override
  Stream<List<HabitDay>> watchDays(String accountId) {
    scheduleMicrotask(() => _dayChanges.add(_days.values.toList()));
    return _dayChanges.stream.map(
      (rows) => rows.where((day) => day.accountId == accountId).toList(),
    );
  }

  @override
  Future<AppResult<void>> commitHabit(HabitWriteRequest request) async {
    _habits[request.habit.id] = request.habit;
    _habitChanges.add(_habits.values.toList());
    return const AppResult.success(null);
  }

  @override
  Future<AppResult<void>> commitDay(HabitDayWriteRequest request) async {
    final day = request.day;
    _days['${day.accountId}:${day.habitId}:${day.localDate}'] = day;
    _dayChanges.add(_days.values.toList());
    return const AppResult.success(null);
  }

  Future<void> close() async {
    await _habitChanges.close();
    await _dayChanges.close();
  }
}
