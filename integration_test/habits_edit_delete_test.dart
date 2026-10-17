import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/habits_strings_adapter.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/presentation/habits_cubit.dart';
import 'package:namma_project/features/habits/presentation/habits_screen.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/habits_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'same-day edit preserves earned day; delete survives encrypted restart',
    (tester) async {
      final path = TemporaryDatabasePath();
      final file = path.allocate();
      final key = List<int>.generate(32, (i) => i + 120);
      final clock = HabitsTestClock();
      final ids = HabitsTestIds();
      var database = await FoundationDatabase.openEncrypted(
        path: file,
        key: key,
      );
      DriftHabitRepository store() => DriftHabitRepository(
        database: database,
        codec: const HabitPayloadCodec(),
      );
      HabitCommands actions(DriftHabitRepository repo) => HabitCommands(
        repository: repo,
        session: const HabitsPreviewSession(),
        nowUtc: clock.utcNow,
        localCalendar: clock.captureLocalCalendar,
        nextHabitId: ids.nextHabitId,
        nextRevisionId: ids.nextRevisionId,
        nextOperationId: ids.nextOperationId,
      );
      var repository = store();
      var commands = actions(repository);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await database.close();
        path.dispose();
      });
      final habit = (await commands.createHabit(
        const CreateHabitInput(name: 'Reading', weekdays: {DateTime.monday}),
      )).valueOrNull!;
      await commands.completeHabitToday(habit.id);
      final edited = (await commands.editHabit(
        EditHabitInput(
          habitId: habit.id,
          name: 'Books',
          weekdays: {DateTime.wednesday},
          reminderMinuteOfDay: 540,
        ),
      )).valueOrNull!;
      expect(edited.isDueOn('2026-10-12'), isFalse);
      expect(
        (await repository.readDay(
          accountId: kHabitsPreviewAccountId,
          habitId: habit.id,
          localDate: '2026-10-12',
        )).valueOrNull?.isCompleted,
        isTrue,
      );
      final cubit = HabitsCubit(
        repository: repository,
        commands: commands,
        localCalendar: clock.captureLocalCalendar,
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          supportedLocales: FoundationLocalizations.supportedLocales,
          home: HabitsScreen(
            cubit: cubit,
            accountId: kHabitsPreviewAccountId,
            stringsResolver: resolveHabitsStrings,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Current streak (days): 1'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('habit-delete-${habit.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('habit_confirm_delete')));
      await repository
          .watchHabits(kHabitsPreviewAccountId)
          .firstWhere((habits) => habits.isEmpty)
          .timeout(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('Books'), findsNothing);
      await cubit.close();
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
      database = await FoundationDatabase.openEncrypted(path: file, key: key);
      repository = store();
      commands = actions(repository);
      expect(
        (await repository.readHabit(
          accountId: kHabitsPreviewAccountId,
          habitId: habit.id,
        )).valueOrNull?.isDeleted,
        isTrue,
      );
      expect(
        (await repository.readDay(
          accountId: kHabitsPreviewAccountId,
          habitId: habit.id,
          localDate: '2026-10-12',
        )).valueOrNull?.isCompleted,
        isTrue,
      );
      expect(
        await repository.watchHabits(kHabitsPreviewAccountId).first,
        isEmpty,
      );
    },
  );
}
