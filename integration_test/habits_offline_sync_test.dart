import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/app.dart';
import 'package:namma_project/app/composition/configure_dependencies.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/presentation/habits_screen.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/habits_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('preview habit create, complete, restart and undo stay local', (
    tester,
  ) async {
    final path = TemporaryDatabasePath();
    final file = path.allocate();
    final key = List<int>.generate(32, (i) => i + 70);
    final clock = HabitsTestClock();
    final ids = HabitsTestIds();
    var database = await FoundationDatabase.openEncrypted(path: file, key: key);
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
    final habit = (await actions.createHabit(
      const CreateHabitInput(
        name: 'Offline reading',
        weekdays: {DateTime.monday},
      ),
    )).valueOrNull!;
    expect(
      (await actions.completeHabitToday(habit.id)).valueOrNull?.isCompleted,
      isTrue,
    );
    await database.close();
    database = await FoundationDatabase.openEncrypted(path: file, key: key);
    store = repository();
    actions = commands(store);
    expect(
      (await store.readDay(
        accountId: kHabitsPreviewAccountId,
        habitId: habit.id,
        localDate: clock.localDate,
      )).valueOrNull?.isCompleted,
      isTrue,
    );
    expect(
      (await actions.undoHabitToday(habit.id)).valueOrNull?.isCompleted,
      isFalse,
    );
    await database.close();
    path.dispose();
  });

  testWidgets('debug preview navigation completes and restores one due habit', (
    tester,
  ) async {
    final path = TemporaryDatabasePath();
    final file = path.allocate();
    final vault = InMemorySecureKeyValueStore();
    Future<void> configure() => configureDependencies(
      environment: FoundationEnvironment.tasksPreview,
      secureStoreOverride: vault,
      databasePathOverride: file,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await GetIt.instance.reset();
      path.dispose();
    });

    await configure();
    await tester.pumpWidget(const FoundationApp());
    await tester.pumpAndSettle();
    expect(find.byKey(kFoundationHabitsNavigationKey), findsOneWidget);
    await tester.tap(find.byKey(kFoundationHabitsNavigationKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kHabitsEmptyKey), findsOneWidget);
    await tester.tap(find.byKey(kHabitAddButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(kHabitNameFieldKey), 'Preview reading');
    await tester.tap(
      find.byKey(Key('habit-weekday-${DateTime.now().weekday}')),
    );
    await tester.tap(find.byKey(kHabitSaveButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('Preview reading'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.undo), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await GetIt.instance.reset();
    await configure();
    await tester.pumpWidget(const FoundationApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kFoundationHabitsNavigationKey));
    await tester.pumpAndSettle();
    expect(find.text('Preview reading'), findsOneWidget);
    expect(find.byIcon(Icons.undo), findsOneWidget);
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
