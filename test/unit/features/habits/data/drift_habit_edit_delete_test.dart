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
  final at = DateTime.utc(2026, 10, 12, 9);
  setUp(() async {
    path = TemporaryDatabasePath();
    database = await FoundationDatabase.openEncrypted(
      path: path.allocate(),
      key: List<int>.generate(32, (i) => i + 70),
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
    'edit and delete queue atomic versions, hide tombstone, retain day',
    () async {
      final habit = Habit.create(
        id: kHabitsTestHabitId,
        accountId: kHabitsTestAccountA,
        name: 'Read',
        weekdays: {1},
        revisionId: 'r1',
        createdAt: at,
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
      );
      Future<void> write(Habit value, ChangeKind kind, String op) async {
        expect(
          (await repository.commitHabit(
            HabitWriteRequest(
              habit: value,
              operationId: op,
              kind: kind,
              queuedAt: value.updatedAt,
            ),
          )).failureOrNull,
          isNull,
        );
      }

      await write(habit, ChangeKind.create, 'create');
      final day = HabitDay.completed(
        accountId: habit.accountId,
        habitId: habit.id,
        localDate: '2026-10-12',
        completedAt: at,
        earnedAgainstRevisionId: 'r1',
        recordedUtcOffsetMinutes: 120,
      );
      expect(
        (await repository.commitDay(
          HabitDayWriteRequest(
            day: day,
            operationId: 'day',
            kind: ChangeKind.create,
            queuedAt: at,
          ),
        )).failureOrNull,
        isNull,
      );
      final edited = habit.edit(
        name: 'Books',
        weekdays: {3},
        reminderMinuteOfDay: 600,
        revisionId: 'r2',
        editedAt: at.add(const Duration(minutes: 1)),
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
      );
      await write(edited, ChangeKind.update, 'edit');
      expect(
        (await repository.readHabit(
          accountId: habit.accountId,
          habitId: habit.id,
        )).valueOrNull?.scheduleRevisions,
        hasLength(2),
      );
      final deleted = edited.delete(at.add(const Duration(minutes: 2)));
      await write(deleted, ChangeKind.delete, 'delete');
      expect(await repository.watchHabits(habit.accountId).first, isEmpty);
      expect(
        (await repository.readDay(
          accountId: habit.accountId,
          habitId: habit.id,
          localDate: day.localDate,
        )).valueOrNull?.isCompleted,
        isTrue,
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM pending_changes'),
        4,
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM habit_day_records'),
        1,
      );
    },
  );

  test(
    'failed outbox update and delete roll back to last confirmed version',
    () async {
      final habit = Habit.create(
        id: kHabitsTestHabitId,
        accountId: kHabitsTestAccountA,
        name: 'Read',
        weekdays: {1},
        revisionId: 'r1',
        createdAt: at,
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
      );
      await repository.commitHabit(
        HabitWriteRequest(
          habit: habit,
          operationId: 'create',
          kind: ChangeKind.create,
          queuedAt: at,
        ),
      );
      await database.rawExecute(
        "CREATE TRIGGER fail_edit_delete BEFORE INSERT ON pending_changes WHEN NEW.operation_id IN ('edit', 'delete') BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      final edited = habit.edit(
        name: 'Books',
        weekdays: {3},
        reminderMinuteOfDay: null,
        revisionId: 'r2',
        editedAt: at.add(const Duration(minutes: 1)),
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
      );
      expect(
        (await repository.commitHabit(
          HabitWriteRequest(
            habit: edited,
            operationId: 'edit',
            kind: ChangeKind.update,
            queuedAt: edited.updatedAt,
          ),
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await repository.readHabit(
          accountId: habit.accountId,
          habitId: habit.id,
        )).valueOrNull?.name,
        'Read',
      );
      final deleted = habit.delete(at.add(const Duration(minutes: 2)));
      expect(
        (await repository.commitHabit(
          HabitWriteRequest(
            habit: deleted,
            operationId: 'delete',
            kind: ChangeKind.delete,
            queuedAt: deleted.updatedAt,
          ),
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await repository.readHabit(
          accountId: habit.accountId,
          habitId: habit.id,
        )).valueOrNull?.isDeleted,
        isFalse,
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM pending_changes'),
        1,
      );
    },
  );
}
