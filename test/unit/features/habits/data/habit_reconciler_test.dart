import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/habits/application/habit_remote_reader.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/data/habit_reconciler.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/habits_test_support.dart';

void main() {
  late TemporaryDatabasePath path;
  late FoundationDatabase database;
  late DriftHabitRepository repository;
  late HabitReconciler reconciler;
  final at = DateTime.utc(2026, 10, 12, 9);
  setUp(() async {
    path = TemporaryDatabasePath();
    database = await FoundationDatabase.openEncrypted(
      path: path.allocate(),
      key: List<int>.generate(32, (i) => i + 90),
    );
    repository = DriftHabitRepository(
      database: database,
      codec: const HabitPayloadCodec(),
    );
    reconciler = HabitReconciler(
      store: repository,
      localStore: DriftLocalStore(database),
      detectedAt: () => at,
    );
  });
  tearDown(() async {
    await database.close();
    path.dispose();
  });

  test('remote habit edit without a pending write is not a conflict', () async {
    final local = Habit.create(
      id: kHabitsTestHabitId,
      accountId: kHabitsTestAccountA,
      name: 'Read',
      weekdays: {1},
      revisionId: kHabitsTestRevisionId,
      createdAt: at,
      effectiveLocalDate: '2026-10-12',
      utcOffsetMinutes: 120,
    );
    expect((await repository.applyInboundHabit(local)).failureOrNull, isNull);
    final remote = local.edit(
      name: 'Read books',
      weekdays: {1},
      reminderMinuteOfDay: null,
      revisionId: 'remote-r2',
      editedAt: at.add(const Duration(minutes: 1)),
      effectiveLocalDate: '2026-10-12',
      utcOffsetMinutes: 120,
    );

    final result = await reconciler.reconcile(
      accountId: local.accountId,
      remote: HabitRemoteSnapshot(habits: [remote], days: []),
    );

    expect(result.valueOrNull?.conflictsRecorded, 0);
    expect(
      (await repository.readHabit(
        accountId: local.accountId,
        habitId: local.id,
      )).valueOrNull?.name,
      'Read books',
    );
    expect(
      await database.rawScalar('SELECT count(*) FROM conflict_records'),
      0,
    );
  });

  test(
    'different remote Habit at equal time is retained without outbox',
    () async {
      final local = Habit.create(
        id: kHabitsTestHabitId,
        accountId: kHabitsTestAccountA,
        name: 'Local',
        weekdays: {1},
        revisionId: kHabitsTestRevisionId,
        createdAt: at,
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
      );
      expect((await repository.applyInboundHabit(local)).failureOrNull, isNull);
      final remote = Habit.restore(
        id: local.id,
        accountId: local.accountId,
        name: 'Remote',
        scheduleRevisions: local.scheduleRevisions,
        createdAt: local.createdAt,
        updatedAt: local.updatedAt,
      );

      final result = await reconciler.reconcile(
        accountId: local.accountId,
        remote: HabitRemoteSnapshot(habits: [remote], days: []),
      );

      expect(result.failureOrNull, isNull);
      expect(result.valueOrNull?.equalTimestampConflicts, 1);
      expect(
        await database.rawScalar('SELECT count(*) FROM conflict_records'),
        1,
      );
      expect(
        (await repository.readHabit(
          accountId: local.accountId,
          habitId: local.id,
        )).valueOrNull?.name,
        'Local',
      );
    },
  );

  test(
    'newest winner and equal-time loser are atomic; pending is retained',
    () async {
      final local = Habit.create(
        id: kHabitsTestHabitId,
        accountId: kHabitsTestAccountA,
        name: 'Local',
        weekdays: {1},
        revisionId: kHabitsTestRevisionId,
        createdAt: at,
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
      );
      await repository.commitHabit(
        HabitWriteRequest(
          habit: local,
          operationId: 'local-op',
          kind: ChangeKind.create,
          queuedAt: at,
        ),
      );
      final remote = local.edit(
        name: 'Remote',
        weekdays: {1},
        reminderMinuteOfDay: null,
        revisionId: 'unused',
        editedAt: at.add(const Duration(minutes: 1)),
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
      );
      final first = await reconciler.reconcile(
        accountId: local.accountId,
        remote: HabitRemoteSnapshot(habits: [remote], days: []),
      );
      expect(first.failureOrNull, isNull);
      expect(first.valueOrNull!.conflictsRecorded, 1);
      expect(
        (await repository.readHabit(
          accountId: local.accountId,
          habitId: local.id,
        )).valueOrNull?.name,
        'Remote',
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM pending_changes'),
        1,
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM conflict_records'),
        1,
      );
      final equal = Habit.restore(
        id: local.id,
        accountId: local.accountId,
        name: 'Equal',
        scheduleRevisions: remote.scheduleRevisions,
        createdAt: remote.createdAt,
        updatedAt: remote.updatedAt,
      );
      final second = await reconciler.reconcile(
        accountId: local.accountId,
        remote: HabitRemoteSnapshot(habits: [equal], days: []),
      );
      expect(second.valueOrNull?.equalTimestampConflicts, 1);
      expect(
        (await repository.readHabit(
          accountId: local.accountId,
          habitId: local.id,
        )).valueOrNull?.name,
        'Remote',
      );
    },
  );

  test(
    'different dates merge and parent tombstone keeps day evidence',
    () async {
      final habit = Habit.create(
        id: kHabitsTestHabitId,
        accountId: kHabitsTestAccountA,
        name: 'Read',
        weekdays: {1, 2},
        revisionId: kHabitsTestRevisionId,
        createdAt: at,
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
      );
      final localDay = HabitDay.completed(
        accountId: habit.accountId,
        habitId: habit.id,
        localDate: '2026-10-12',
        completedAt: at,
        earnedAgainstRevisionId: kHabitsTestRevisionId,
        recordedUtcOffsetMinutes: 120,
      );
      await repository.commitHabit(
        HabitWriteRequest(
          habit: habit,
          operationId: 'h',
          kind: ChangeKind.create,
          queuedAt: at,
        ),
      );
      await repository.commitDay(
        HabitDayWriteRequest(
          day: localDay,
          operationId: 'd',
          kind: ChangeKind.create,
          queuedAt: at,
        ),
      );
      final remoteDay = HabitDay.completed(
        accountId: habit.accountId,
        habitId: habit.id,
        localDate: '2026-10-13',
        completedAt: at.add(const Duration(days: 1)),
        earnedAgainstRevisionId: kHabitsTestRevisionId,
        recordedUtcOffsetMinutes: 120,
      );
      final deleted = habit.delete(at.add(const Duration(hours: 1)));
      final result = await reconciler.reconcile(
        accountId: habit.accountId,
        remote: HabitRemoteSnapshot(habits: [deleted], days: [remoteDay]),
      );
      expect(result.failureOrNull, isNull);
      expect(
        (await repository.readDay(
          accountId: habit.accountId,
          habitId: habit.id,
          localDate: '2026-10-12',
        )).valueOrNull,
        isNotNull,
      );
      expect(
        (await repository.readDay(
          accountId: habit.accountId,
          habitId: habit.id,
          localDate: '2026-10-13',
        )).valueOrNull,
        isNotNull,
      );
      expect(
        (await repository.readHabit(
          accountId: habit.accountId,
          habitId: habit.id,
        )).valueOrNull?.isDeleted,
        isTrue,
      );
      expect(result.valueOrNull!.conflictsRecorded, greaterThanOrEqualTo(2));
    },
  );

  Habit syncedHabit() => Habit.create(
    id: kHabitsTestHabitId,
    accountId: kHabitsTestAccountA,
    name: 'Read',
    weekdays: {1},
    revisionId: kHabitsTestRevisionId,
    createdAt: at,
    effectiveLocalDate: '2026-10-12',
    utcOffsetMinutes: 120,
  );

  test(
    'a habit edit queued on top of the remote version is not a conflict',
    () async {
      final synced = syncedHabit();
      expect(
        (await repository.applyInboundHabit(synced)).failureOrNull,
        isNull,
      );
      final edited = synced.edit(
        name: 'Read daily',
        weekdays: {1},
        reminderMinuteOfDay: null,
        revisionId: 'local-r2',
        editedAt: at.add(const Duration(minutes: 1)),
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
      );
      expect(
        (await repository.commitHabit(
          HabitWriteRequest(
            habit: edited,
            operationId: 'edit-during-sync',
            kind: ChangeKind.update,
            queuedAt: edited.updatedAt,
          ),
        )).failureOrNull,
        isNull,
      );

      final result = await reconciler.reconcile(
        accountId: synced.accountId,
        remote: HabitRemoteSnapshot(habits: [synced], days: []),
      );

      expect(result.failureOrNull, isNull);
      expect(result.valueOrNull!.conflictsRecorded, 0);
      expect(
        await database.rawScalar('SELECT count(*) FROM conflict_records'),
        0,
      );
      expect(
        (await repository.readHabit(
          accountId: synced.accountId,
          habitId: synced.id,
        )).valueOrNull?.name,
        'Read daily',
      );
    },
  );

  test('undoing a day while its completion syncs is not a conflict', () async {
    final habit = syncedHabit();
    final completed = HabitDay.completed(
      accountId: habit.accountId,
      habitId: habit.id,
      localDate: '2026-10-12',
      completedAt: at,
      earnedAgainstRevisionId: kHabitsTestRevisionId,
      recordedUtcOffsetMinutes: 120,
    );
    expect((await repository.applyInboundHabit(habit)).failureOrNull, isNull);
    expect((await repository.applyInboundDay(completed)).failureOrNull, isNull);
    final undone = completed.undo(at.add(const Duration(seconds: 5)), 120);
    expect(
      (await repository.commitDay(
        HabitDayWriteRequest(
          day: undone,
          operationId: 'undo-during-sync',
          kind: ChangeKind.update,
          queuedAt: undone.updatedAt,
        ),
      )).failureOrNull,
      isNull,
    );

    // The snapshot was read after the completion uploaded but before undo.
    final result = await reconciler.reconcile(
      accountId: habit.accountId,
      remote: HabitRemoteSnapshot(habits: [habit], days: [completed]),
    );

    expect(result.failureOrNull, isNull);
    expect(result.valueOrNull!.conflictsRecorded, 0);
    expect(
      (await repository.readDay(
        accountId: habit.accountId,
        habitId: habit.id,
        localDate: '2026-10-12',
      )).valueOrNull?.isCompleted,
      isFalse,
    );
  });
}
