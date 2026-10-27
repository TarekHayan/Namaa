import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/app.dart';
import 'package:namma_project/app/composition/configure_dependencies.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/application/habit_remote_reader.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/data/habit_reconciler.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/habits/presentation/habits_screen.dart';
import 'package:namma_project/features/habits/presentation/habits_state.dart';
import 'package:namma_project/features/today/presentation/today_screen.dart';
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_sidebar.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/habits_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'two devices merge dates and replay ten times without leaking accounts',
    (tester) async {
      final paths = [TemporaryDatabasePath(), TemporaryDatabasePath()];
      final files = [paths[0].allocate(), paths[1].allocate()];
      final key = List<int>.generate(32, (i) => i + 110);
      final clockA = HabitsTestClock();
      final clockB = HabitsTestClock();
      final idsA = HabitsTestIds();
      final idsB = HabitsTestIds();
      // The real client uses random IDs; stable per-device prefixes model that.
      var dbA = await FoundationDatabase.openEncrypted(
        path: files[0],
        key: key,
      );
      final dbB = await FoundationDatabase.openEncrypted(
        path: files[1],
        key: key,
      );
      DriftHabitRepository repo(FoundationDatabase db) =>
          DriftHabitRepository(database: db, codec: const HabitPayloadCodec());
      var storeA = repo(dbA);
      final storeB = repo(dbB);
      HabitCommands commands(
        DriftHabitRepository store,
        HabitsTestClock clock,
        HabitsTestIds ids,
        String account,
      ) => HabitCommands(
        repository: store,
        session: _AccountSession(account),
        nowUtc: clock.utcNow,
        localCalendar: clock.captureLocalCalendar,
        nextHabitId: ids.nextHabitId,
        nextRevisionId: ids.nextRevisionId,
        nextOperationId: () =>
            '${account == kHabitsTestAccountB
                ? 'foreign'
                : identical(ids, idsA)
                ? 'device-a'
                : 'device-b'}-${ids.nextOperationId()}',
      );
      var actionsA = commands(storeA, clockA, idsA, kHabitsTestAccountA);
      final actionsB = commands(storeB, clockB, idsB, kHabitsTestAccountA);
      final foreignActions = commands(
        storeB,
        clockB,
        HabitsTestIds(),
        kHabitsTestAccountB,
      );
      final cloud = _HabitCloud();
      Future<void> send(FoundationDatabase db, String account) async {
        final outbox = DriftLocalStore(db);
        final pending = (await outbox.readPendingChanges(account)).valueOrNull!;
        for (final change in pending) {
          cloud.apply(change);
          expect(
            (await outbox.acknowledgeChange(
              change.operationId,
              change.operationId,
              change.versionTimestamp,
            )).failureOrNull,
            isNull,
          );
        }
      }

      Future<void> receive(
        FoundationDatabase db,
        DriftHabitRepository store,
        String account,
      ) async {
        final result = await HabitReconciler(
          store: store,
          localStore: DriftLocalStore(db),
        ).reconcile(accountId: account, remote: cloud.snapshot(account));
        expect(result.failureOrNull, isNull);
      }

      addTearDown(() async {
        await dbA.close();
        await dbB.close();
        for (final path in paths) {
          path.dispose();
        }
      });

      final habit = (await actionsA.createHabit(
        const CreateHabitInput(
          name: 'Reading',
          weekdays: HabitsTestSchedules.daily,
        ),
      )).valueOrNull!;
      await actionsA.completeHabitToday(habit.id);
      await send(dbA, kHabitsTestAccountA);
      await receive(dbB, storeB, kHabitsTestAccountA);
      clockB.advance(const Duration(days: 1));
      expect(
        (await actionsB.completeHabitToday(habit.id)).failureOrNull,
        isNull,
      );
      await send(dbB, kHabitsTestAccountA);
      await receive(dbA, storeA, kHabitsTestAccountA);
      expect(
        (await storeA.readDay(
          accountId: kHabitsTestAccountA,
          habitId: habit.id,
          localDate: '2026-10-12',
        )).valueOrNull?.isCompleted,
        isTrue,
      );
      expect(
        (await storeA.readDay(
          accountId: kHabitsTestAccountA,
          habitId: habit.id,
          localDate: '2026-10-13',
        )).valueOrNull?.isCompleted,
        isTrue,
      );

      final foreign = (await foreignActions.createHabit(
        const CreateHabitInput(
          name: 'Private',
          weekdays: HabitsTestSchedules.daily,
        ),
      )).valueOrNull!;
      await dbB.rawExecute(
        '''CREATE TRIGGER fail_foreign_edit BEFORE INSERT ON pending_changes
        WHEN NEW.operation_id LIKE 'foreign-%' BEGIN SELECT RAISE(ABORT, 'injected'); END''',
      );
      expect(
        (await foreignActions.editHabit(
          EditHabitInput(
            habitId: foreign.id,
            name: 'Should not save',
            weekdays: HabitsTestSchedules.daily,
            reminderMinuteOfDay: null,
          ),
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await storeB.readHabit(
          accountId: kHabitsTestAccountB,
          habitId: foreign.id,
        )).valueOrNull?.name,
        'Private',
      );
      await dbB.rawExecute('DROP TRIGGER fail_foreign_edit');
      await send(dbB, kHabitsTestAccountB);
      expect(
        cloud
            .snapshot(kHabitsTestAccountA)
            .habits
            .any((h) => h.accountId == kHabitsTestAccountB),
        isFalse,
      );
      expect(
        (await storeA.readHabit(
          accountId: kHabitsTestAccountA,
          habitId: foreign.id,
        )).valueOrNull?.accountId,
        kHabitsTestAccountA,
      );
      expect(
        (await storeA.readHabit(
          accountId: kHabitsTestAccountB,
          habitId: foreign.id,
        )).valueOrNull,
        isNull,
      );

      clockA.advance(const Duration(days: 1));
      await actionsA.undoHabitToday(habit.id);
      await send(dbA, kHabitsTestAccountA);
      await receive(dbB, storeB, kHabitsTestAccountA);
      expect(
        (await storeB.readDay(
          accountId: kHabitsTestAccountA,
          habitId: habit.id,
          localDate: '2026-10-13',
        )).valueOrNull?.isCompleted,
        isFalse,
      );
      clockB.advance(const Duration(hours: 1));
      await actionsB.editHabit(
        EditHabitInput(
          habitId: habit.id,
          name: 'Books',
          weekdays: HabitsTestSchedules.daily,
          reminderMinuteOfDay: null,
        ),
      );
      await send(dbB, kHabitsTestAccountA);
      clockA.advance(const Duration(hours: 2));
      await actionsA.deleteHabit(habit.id, confirmed: true);
      await send(dbA, kHabitsTestAccountA);
      await receive(dbB, storeB, kHabitsTestAccountA);
      expect(
        (await storeB.readHabit(
          accountId: kHabitsTestAccountA,
          habitId: habit.id,
        )).valueOrNull?.isDeleted,
        isTrue,
      );
      // Both devices have sent their changes; an incoming server snapshot is
      // not a local pending edit and must not create a synthetic conflict.
      expect(await dbB.rawScalar('SELECT count(*) FROM conflict_records'), 0);

      for (var trial = 0; trial < 10; trial++) {
        await dbA.close();
        dbA = await FoundationDatabase.openEncrypted(path: files[0], key: key);
        storeA = repo(dbA);
        actionsA = commands(storeA, clockA, idsA, kHabitsTestAccountA);
        await send(dbA, kHabitsTestAccountA);
        await receive(dbA, storeA, kHabitsTestAccountA);
        expect(
          (await storeA.readHabit(
            accountId: kHabitsTestAccountA,
            habitId: habit.id,
          )).valueOrNull?.isDeleted,
          isTrue,
        );
        expect(
          await dbA.rawScalar('SELECT count(*) FROM habit_day_records'),
          2,
        );
      }
    },
  );
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
    Future<void> openHabitsFromToday() async {
      if (find.byKey(kTodaySidebarKey).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(kTodaySidebarHabitsKey));
      } else {
        await tester.tap(find.byKey(kTodayBottomMoreKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(kTodayBottomHabitsKey));
      }
      await tester.pumpAndSettle();
      expect(find.byType(HabitsScreen), findsOneWidget);
    }

    Future<void> waitForPreviewHabit({required bool completed}) async {
      final cubit = tester
          .widget<HabitsScreen>(find.byType(HabitsScreen))
          .cubit;
      bool matches(HabitsState state) =>
          state is HabitsReady &&
          state.today.any(
            (value) =>
                value.habit.name == 'Preview reading' &&
                value.isDue &&
                value.isCompleted == completed,
          );
      if (!matches(cubit.state)) {
        await cubit.stream
            .firstWhere(matches)
            .timeout(const Duration(seconds: 10));
      }
      await tester.pumpAndSettle();
    }

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
    expect(find.byKey(kTodayScreenKey), findsOneWidget);
    await openHabitsFromToday();
    expect(find.byKey(kHabitsEmptyKey), findsOneWidget);
    await tester.tap(find.byKey(kHabitAddButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(kHabitNameFieldKey), 'Preview reading');
    for (var weekday = 1; weekday <= 7; weekday++) {
      final chip = find.byKey(Key('habit-weekday-$weekday'));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
    }
    await tester.tap(find.byKey(kHabitSaveButtonKey));
    await waitForPreviewHabit(completed: false);
    expect(find.text('Preview reading'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await waitForPreviewHabit(completed: true);
    expect(find.byIcon(Icons.undo), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await GetIt.instance.reset();
    await configure();
    await tester.pumpWidget(const FoundationApp());
    await tester.pumpAndSettle();
    await openHabitsFromToday();
    await waitForPreviewHabit(completed: true);
    expect(find.text('Preview reading'), findsOneWidget);
    expect(find.byIcon(Icons.undo), findsOneWidget);
    await tester.tap(find.byIcon(Icons.undo));
    await waitForPreviewHabit(completed: false);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}

final class _AccountSession implements CloudSessionPort {
  const _AccountSession(this.account);
  final String account;
  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);
  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.value(
    CloudSessionSnapshot(
      status: CloudSessionStatus.signedIn,
      accountId: account,
    ),
  );
  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult.success(CloudSyncContext(accountId: account));
}

final class _HabitCloud {
  final _habits = <String, Habit>{};
  final _days = <String, HabitDay>{};
  final _receipts = <String, String>{};
  final HabitPayloadCodec codec = const HabitPayloadCodec();

  void apply(PendingChangeRecord change) {
    final receipt = '${change.accountId}:${change.operationId}';
    final previous = _receipts[receipt];
    if (previous != null) {
      if (previous != change.serializedChange) {
        throw StateError('operation identity collision');
      }
      return;
    }
    _receipts[receipt] = change.serializedChange;
    if (change.entityType == 'habit') {
      final habit = codec.decodeHabit(change.serializedChange);
      if (habit.accountId != change.accountId) {
        throw StateError('foreign Habit');
      }
      final key = '${habit.accountId}:${habit.id}';
      final old = _habits[key];
      if (old == null || habit.updatedAt.isAfter(old.updatedAt)) {
        _habits[key] = habit;
      }
    } else if (change.entityType == 'habit_day') {
      final day = codec.decodeDay(change.serializedChange);
      if (day.accountId != change.accountId) throw StateError('foreign day');
      final key = '${day.accountId}:${day.habitId}:${day.localDate}';
      final old = _days[key];
      if (old == null || day.updatedAt.isAfter(old.updatedAt)) {
        _days[key] = day;
      }
    }
  }

  HabitRemoteSnapshot snapshot(String account) => HabitRemoteSnapshot(
    habits: _habits.values.where((habit) => habit.accountId == account),
    days: _days.values.where((day) => day.accountId == account),
  );
}
