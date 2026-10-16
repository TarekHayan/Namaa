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
    'neutral day, closed miss and history survive restart for two habits',
    (tester) async {
      final path = TemporaryDatabasePath();
      final file = path.allocate();
      final key = List<int>.generate(32, (i) => i + 100);
      final clock = HabitsTestClock(); // Monday 2026-10-12.
      final ids = HabitsTestIds();
      var database = await FoundationDatabase.openEncrypted(
        path: file,
        key: key,
      );
      DriftHabitRepository repository() => DriftHabitRepository(
        database: database,
        codec: const HabitPayloadCodec(),
      );
      HabitCommands commands(DriftHabitRepository store) => HabitCommands(
        repository: store,
        session: const HabitsPreviewSession(),
        nowUtc: clock.utcNow,
        localCalendar: clock.captureLocalCalendar,
        nextHabitId: ids.nextHabitId,
        nextRevisionId: ids.nextRevisionId,
        nextOperationId: ids.nextOperationId,
      );
      var store = repository();
      var actions = commands(store);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await database.close();
        path.dispose();
      });

      final reading = (await actions.createHabit(
        const CreateHabitInput(
          name: 'Reading',
          weekdays: {DateTime.monday, DateTime.wednesday},
        ),
      )).valueOrNull!;
      final walking = (await actions.createHabit(
        const CreateHabitInput(
          name: 'Walking',
          weekdays: HabitsTestSchedules.daily,
        ),
      )).valueOrNull!;
      expect(
        (await actions.completeHabitToday(reading.id)).failureOrNull,
        isNull,
      );
      expect(
        (await actions.completeHabitToday(walking.id)).failureOrNull,
        isNull,
      );
      clock.advance(
        const Duration(days: 1),
      ); // Tuesday: neutral for Reading, missed for Walking.
      clock.advance(const Duration(days: 1)); // Wednesday.
      expect(
        (await actions.completeHabitToday(reading.id)).failureOrNull,
        isNull,
      );

      await database.close();
      database = await FoundationDatabase.openEncrypted(path: file, key: key);
      store = repository();
      actions = commands(store);
      final cubit = HabitsCubit(
        repository: store,
        commands: actions,
        localCalendar: clock.captureLocalCalendar,
      );
      addTearDown(cubit.close);
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
      expect(find.text('Current streak (days): 2'), findsOneWidget);
      expect(find.text('Current streak (days): 0'), findsOneWidget);
      expect(find.text('Today is still in progress'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('habit-history-${reading.id}')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('habit-history-date-${reading.id}-2026-10-12')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('habit-history-date-${reading.id}-2026-10-14')),
        findsOneWidget,
      );
    },
  );
}
