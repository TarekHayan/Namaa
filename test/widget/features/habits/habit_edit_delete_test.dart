import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/habits_strings_adapter.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/habits/presentation/habit_editor.dart';
import 'package:namma_project/features/habits/presentation/habits_cubit.dart';
import 'package:namma_project/features/habits/presentation/habits_screen.dart';

import '../../../support/habits_test_support.dart';

void main() {
  testWidgets('edit, inactive reminder, confirmed delete and failed save', (
    tester,
  ) async {
    final repository = _Repository();
    final clock = HabitsTestClock();
    final ids = HabitsTestIds();
    final commands = HabitCommands(
      repository: repository,
      session: const HabitsPreviewSession(),
      nowUtc: clock.utcNow,
      localCalendar: clock.captureLocalCalendar,
      nextHabitId: ids.nextHabitId,
      nextRevisionId: ids.nextRevisionId,
      nextOperationId: ids.nextOperationId,
    );
    final first = (await commands.createHabit(
      const CreateHabitInput(name: 'Reading', weekdays: {DateTime.monday}),
    )).valueOrNull!;
    final second = (await commands.createHabit(
      const CreateHabitInput(name: 'Walking', weekdays: {DateTime.monday}),
    )).valueOrNull!;
    final cubit = HabitsCubit(
      repository: repository,
      commands: commands,
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
    await tester.tap(find.byKey(ValueKey('habit-edit-${first.id}')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Notifications are not active yet. A chosen time is saved for later.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reading'), findsWidgets);
    expect(find.byKey(const Key('habit-weekday-1')), findsOneWidget);
    await tester.enterText(find.byKey(kHabitNameFieldKey), 'Books');
    await tester.tap(find.byKey(kHabitReminderButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kHabitSaveButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('Books'), findsOneWidget);
    expect(repository.habits[first.id]?.reminderMinuteOfDay, isNotNull);
    expect(find.text('Walking'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('habit-delete-${first.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('habit_delete_confirmation')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Books'), findsOneWidget);
    repository.failNext = true;
    await tester.tap(find.byKey(ValueKey('habit-delete-${first.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('habit_confirm_delete')));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save your change. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('Walking'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('habit-delete-${first.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('habit_confirm_delete')));
    await tester.pumpAndSettle();
    expect(find.text('Books'), findsNothing);
    expect(find.byKey(ValueKey('habit-history-${first.id}')), findsNothing);
    expect(find.text('Walking'), findsOneWidget);
    expect(repository.habits[first.id]?.isDeleted, isTrue);
    expect(repository.habits[second.id]?.isDeleted, isFalse);
  });
}

final class _Repository implements HabitRepository {
  final Map<String, Habit> habits = {};
  final Map<String, HabitDay> days = {};
  final StreamController<List<Habit>> _habits = StreamController.broadcast(
    sync: true,
  );
  final StreamController<List<HabitDay>> _days = StreamController.broadcast(
    sync: true,
  );
  bool failNext = false;
  @override
  Future<AppResult<Habit?>> readHabit({
    required String accountId,
    required String habitId,
  }) async => AppResult.success(
    habits[habitId]?.accountId == accountId ? habits[habitId] : null,
  );
  @override
  Future<AppResult<HabitDay?>> readDay({
    required String accountId,
    required String habitId,
    required String localDate,
  }) async => AppResult.success(days['$accountId:$habitId:$localDate']);
  @override
  Stream<List<Habit>> watchHabits(String accountId) {
    scheduleMicrotask(() => _habits.add(habits.values.toList()));
    return _habits.stream.map(
      (rows) => rows
          .where((habit) => habit.accountId == accountId && !habit.isDeleted)
          .toList(),
    );
  }

  @override
  Stream<List<HabitDay>> watchDays(String accountId) {
    scheduleMicrotask(() => _days.add(days.values.toList()));
    return _days.stream.map(
      (rows) => rows.where((day) => day.accountId == accountId).toList(),
    );
  }

  @override
  Future<AppResult<void>> commitHabit(HabitWriteRequest request) async {
    if (failNext) {
      failNext = false;
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'habits.error.save',
          occurredAt: DateTime.utc(2026, 10, 12),
        ),
      );
    }
    habits[request.habit.id] = request.habit;
    _habits.add(habits.values.toList());
    return const AppResult.success(null);
  }

  @override
  Future<AppResult<void>> commitDay(HabitDayWriteRequest request) async {
    final day = request.day;
    days['${day.accountId}:${day.habitId}:${day.localDate}'] = day;
    _days.add(days.values.toList());
    return const AppResult.success(null);
  }

  Future<void> close() async {
    await _habits.close();
    await _days.close();
  }
}
