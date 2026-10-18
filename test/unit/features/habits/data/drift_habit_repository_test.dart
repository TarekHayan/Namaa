import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/habits_test_support.dart';

void main() {
  late TemporaryDatabasePath path;
  late FoundationDatabase database;
  late DriftHabitRepository repository;
  final key = List<int>.generate(32, (i) => i + 40);
  final at = DateTime.utc(2026, 10, 12, 9);

  setUp(() async {
    path = TemporaryDatabasePath();
    database = await FoundationDatabase.openEncrypted(
      path: path.allocate(),
      key: key,
    );
    repository = DriftHabitRepository(
      database: database,
      codec: const HabitPayloadCodec(),
    );
  });
  tearDown(() async {
    await database.close();
    path.dispose();
  });

  test(
    'habit and day writes queue stable operations and isolate accounts',
    () async {
      final habit = Habit.create(
        id: kHabitsTestHabitId,
        accountId: kHabitsTestAccountA,
        name: 'Read',
        weekdays: {1},
        revisionId: kHabitsTestRevisionId,
        createdAt: at,
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
      );
      final request = HabitWriteRequest(
        habit: habit,
        operationId: kHabitsTestOperationId,
        kind: ChangeKind.create,
        queuedAt: at,
      );
      expect((await repository.commitHabit(request)).failureOrNull, isNull);
      expect((await repository.commitHabit(request)).failureOrNull, isNull);
      final day = HabitDay.completed(
        accountId: kHabitsTestAccountA,
        habitId: habit.id,
        localDate: '2026-10-12',
        completedAt: at,
        earnedAgainstRevisionId: kHabitsTestRevisionId,
        recordedUtcOffsetMinutes: 120,
      );
      expect(
        (await repository.commitDay(
          HabitDayWriteRequest(
            day: day,
            operationId: 'day-op-1',
            kind: ChangeKind.create,
            queuedAt: at,
          ),
        )).failureOrNull,
        isNull,
      );
      expect(
        (await repository.readHabit(
          accountId: kHabitsTestAccountB,
          habitId: habit.id,
        )).valueOrNull,
        isNull,
      );
      expect(
        (await repository.readDay(
          accountId: kHabitsTestAccountA,
          habitId: habit.id,
          localDate: day.localDate,
        )).valueOrNull?.completedAt,
        at,
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM pending_changes'),
        2,
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM habit_day_records'),
        1,
      );
    },
  );

  test('failed outbox insert rolls back habit row', () async {
    final habit = Habit.create(
      id: kHabitsTestHabitId,
      accountId: kHabitsTestAccountA,
      name: 'Read',
      weekdays: {1},
      revisionId: kHabitsTestRevisionId,
      createdAt: at,
      effectiveLocalDate: '2026-10-12',
      utcOffsetMinutes: 120,
    );
    await database.rawExecute(
      "CREATE TRIGGER fail_habit_outbox BEFORE INSERT ON pending_changes WHEN NEW.entity_type = 'habit' BEGIN SELECT RAISE(ABORT, 'injected'); END",
    );
    expect(
      (await repository.commitHabit(
        HabitWriteRequest(
          habit: habit,
          operationId: 'fail-op',
          kind: ChangeKind.create,
          queuedAt: at,
        ),
      )).failureOrNull,
      isNotNull,
    );
    expect(await database.rawScalar('SELECT count(*) FROM habit_records'), 0);
  });

  test('encrypted restart retains day and pending write', () async {
    final habit = Habit.create(
      id: kHabitsTestHabitId,
      accountId: kHabitsTestAccountA,
      name: 'Read',
      weekdays: {1},
      revisionId: kHabitsTestRevisionId,
      createdAt: at,
      effectiveLocalDate: '2026-10-12',
      utcOffsetMinutes: 120,
    );
    await repository.commitHabit(
      HabitWriteRequest(
        habit: habit,
        operationId: 'habit-restart',
        kind: ChangeKind.create,
        queuedAt: at,
      ),
    );
    final day = HabitDay.completed(
      accountId: kHabitsTestAccountA,
      habitId: habit.id,
      localDate: '2026-10-12',
      completedAt: at,
      earnedAgainstRevisionId: kHabitsTestRevisionId,
      recordedUtcOffsetMinutes: 120,
    );
    await repository.commitDay(
      HabitDayWriteRequest(
        day: day,
        operationId: 'day-restart',
        kind: ChangeKind.create,
        queuedAt: at,
      ),
    );
    final file = database.resolvedPath;
    await database.close();
    database = await FoundationDatabase.openEncrypted(path: file, key: key);
    repository = DriftHabitRepository(
      database: database,
      codec: const HabitPayloadCodec(),
    );
    expect(
      (await repository.readDay(
        accountId: kHabitsTestAccountA,
        habitId: habit.id,
        localDate: day.localDate,
      )).valueOrNull?.isCompleted,
      isTrue,
    );
    expect(await database.rawScalar('SELECT count(*) FROM pending_changes'), 2);
  });

  test('failed day outbox update preserves confirmed completion', () async {
    final day = HabitDay.completed(
      accountId: kHabitsTestAccountA,
      habitId: kHabitsTestHabitId,
      localDate: '2026-10-12',
      completedAt: at,
      earnedAgainstRevisionId: kHabitsTestRevisionId,
      recordedUtcOffsetMinutes: 120,
    );
    await repository.commitDay(
      HabitDayWriteRequest(
        day: day,
        operationId: 'day-first',
        kind: ChangeKind.create,
        queuedAt: at,
      ),
    );
    await database.rawExecute(
      'CREATE TRIGGER fail_day_outbox BEFORE INSERT ON pending_changes '
      "WHEN NEW.entity_type = 'habit_day' BEGIN SELECT RAISE(ABORT, 'injected'); END",
    );
    final undone = day.undo(at.add(const Duration(minutes: 1)), 120);
    expect(
      (await repository.commitDay(
        HabitDayWriteRequest(
          day: undone,
          operationId: 'day-undo-failed',
          kind: ChangeKind.update,
          queuedAt: undone.updatedAt,
        ),
      )).failureOrNull,
      isNotNull,
    );
    expect(
      (await repository.readDay(
        accountId: kHabitsTestAccountA,
        habitId: day.habitId,
        localDate: day.localDate,
      )).valueOrNull?.isCompleted,
      isTrue,
    );
  });
}
