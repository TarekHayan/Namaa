import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/habits_strings_adapter.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/habits/presentation/habit_history_view.dart';
import 'package:namma_project/features/habits/presentation/habits_cubit.dart';
import 'package:namma_project/features/habits/presentation/habits_screen.dart';

import '../../../support/habits_test_support.dart';

void main() {
  testWidgets('two independent streaks and read-only prior dates appear', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final clock = HabitsTestClock(initialUtc: DateTime.utc(2026, 10, 14, 9));
    Habit makeHabit(String id, String name, Set<int> weekdays) => Habit.create(
      id: id,
      accountId: kHabitsPreviewAccountId,
      name: name,
      weekdays: weekdays,
      revisionId: '$id-revision',
      createdAt: DateTime.utc(2026, 10, 12, 9),
      effectiveLocalDate: '2026-10-12',
      utcOffsetMinutes: 120,
    );
    final reading = makeHabit(kHabitsTestHabitId, 'Reading', {1, 3});
    final walking = makeHabit(kHabitsTestOtherHabitId, 'Walking', {
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    });
    HabitDay completed(Habit habit, String date) => HabitDay.completed(
      accountId: habit.accountId,
      habitId: habit.id,
      localDate: date,
      completedAt: DateTime.utc(2026, 10, int.parse(date.substring(8)), 10),
      earnedAgainstRevisionId: habit.currentRevision.revisionId,
      recordedUtcOffsetMinutes: 120,
    );
    final repository = _HistoryRepository(
      habits: [reading, walking],
      days: [
        completed(reading, '2026-10-12'),
        completed(reading, '2026-10-14'),
        completed(walking, '2026-10-12'),
      ],
    );
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
    addTearDown(cubit.close);

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
    expect(find.text('Current streak (days): 2'), findsOneWidget);
    expect(find.text('Current streak (days): 0'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('habit-history-${reading.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(kHabitHistoryDialogKey), findsOneWidget);
    expect(
      find.byKey(ValueKey('habit-history-date-${reading.id}-2026-10-12')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('habit-history-date-${reading.id}-2026-10-14')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(kHabitHistoryDialogKey),
        matching: find.byType(Checkbox),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(kHabitHistoryDialogKey),
        matching: find.byIcon(Icons.undo),
      ),
      findsNothing,
    );
    await tester.tap(
      find.byKey(ValueKey('habit-history-date-${reading.id}-2026-10-12')),
    );
    await tester.pumpAndSettle();
    expect(
      (await repository.readDay(
        accountId: reading.accountId,
        habitId: reading.id,
        localDate: '2026-10-12',
      )).valueOrNull?.isCompleted,
      isTrue,
    );
    semantics.dispose();
  });
}

final class _HistoryRepository implements HabitRepository {
  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();
  _HistoryRepository({required this.habits, required this.days});
  final List<Habit> habits;
  final List<HabitDay> days;

  @override
  Future<AppResult<Habit?>> readHabit({
    required String accountId,
    required String habitId,
  }) async => AppResult.success(
    _firstOrNull(
      habits.where(
        (habit) => habit.accountId == accountId && habit.id == habitId,
      ),
    ),
  );

  @override
  Future<AppResult<HabitDay?>> readDay({
    required String accountId,
    required String habitId,
    required String localDate,
  }) async => AppResult.success(
    _firstOrNull(
      days.where(
        (day) =>
            day.accountId == accountId &&
            day.habitId == habitId &&
            day.localDate == localDate,
      ),
    ),
  );

  @override
  Stream<List<Habit>> watchHabits(String accountId) => Stream.value(
    habits.where((habit) => habit.accountId == accountId).toList(),
  );

  @override
  Stream<List<HabitDay>> watchDays(String accountId) =>
      Stream.value(days.where((day) => day.accountId == accountId).toList());

  @override
  Future<AppResult<void>> commitHabit(HabitWriteRequest request) async =>
      const AppResult.success(null);

  @override
  Future<AppResult<void>> commitDay(HabitDayWriteRequest request) async =>
      const AppResult.success(null);

  T? _firstOrNull<T>(Iterable<T> values) =>
      values.isEmpty ? null : values.first;
}
