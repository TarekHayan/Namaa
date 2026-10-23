import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/habits_test_support.dart';

void main() {
  late TemporaryDatabasePath path;
  late FoundationDatabase database;
  late HabitsTestClock clock;
  late HabitsTestIds ids;
  late HabitCommands commands;

  setUp(() async {
    path = TemporaryDatabasePath();
    database = await FoundationDatabase.openEncrypted(
      path: path.allocate(),
      key: List<int>.generate(32, (i) => i + 30),
    );
    clock = HabitsTestClock();
    ids = HabitsTestIds();
    commands = HabitCommands(
      repository: DriftHabitRepository(
        database: database,
        codec: const HabitPayloadCodec(),
      ),
      session: const TasksPreviewSession(),
      nowUtc: clock.utcNow,
      localCalendar: clock.captureLocalCalendar,
      nextHabitId: ids.nextHabitId,
      nextRevisionId: ids.nextRevisionId,
      nextOperationId: ids.nextOperationId,
    );
  });
  tearDown(() async {
    await database.close();
    path.dispose();
  });

  test(
    'create, complete and undo only today; ten repeat taps are idempotent',
    () async {
      final habit = (await commands.createHabit(
        const CreateHabitInput(name: 'Read', weekdays: {DateTime.monday}),
      )).valueOrNull!;
      expect(habit.accountId, kTasksPreviewAccountId);
      for (var i = 0; i < 10; i++) {
        expect(
          (await commands.completeHabitToday(habit.id)).failureOrNull,
          isNull,
        );
      }
      expect(
        await database.rawScalar('SELECT count(*) FROM habit_day_records'),
        1,
      );
      expect(
        (await commands.undoHabitToday(habit.id)).valueOrNull!.completedAt,
        isNull,
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM habit_day_records'),
        1,
      );
    },
  );

  test('blank, empty and unscheduled writes have typed failures', () async {
    expect(
      (await commands.createHabit(
        const CreateHabitInput(name: ' ', weekdays: {1}),
      )).failureOrNull?.category,
      AppFailureCategory.validation,
    );
    expect(
      (await commands.createHabit(
        const CreateHabitInput(name: 'Read', weekdays: {}),
      )).failureOrNull?.category,
      AppFailureCategory.validation,
    );
    final habit = (await commands.createHabit(
      const CreateHabitInput(name: 'Read', weekdays: {DateTime.tuesday}),
    )).valueOrNull!;
    expect(
      (await commands.completeHabitToday(habit.id)).failureOrNull?.category,
      AppFailureCategory.validation,
    );
    expect(
      (await commands.completeHabitToday(
        habit.id,
        expectedAccountId: kHabitsTestAccountB,
      )).failureOrNull?.category,
      AppFailureCategory.authorization,
    );
    expect(
      await database.rawScalar('SELECT count(*) FROM habit_day_records'),
      0,
    );
  });

  test('completion follows the acting device date after midnight', () async {
    final habit = (await commands.createHabit(
      const CreateHabitInput(
        name: 'Every day',
        weekdays: HabitsTestSchedules.daily,
      ),
    )).valueOrNull!;
    clock.advance(const Duration(days: 1));
    final day = (await commands.completeHabitToday(habit.id)).valueOrNull!;
    expect(day.localDate, '2026-10-13');
    expect(
      await database.rawScalar(
        "SELECT count(*) FROM habit_day_records WHERE local_date = '2026-10-12'",
      ),
      0,
    );
  });

  test(
    'Today rejects a stale displayed day with no day or outbox write',
    () async {
      final habit = (await commands.createHabit(
        const CreateHabitInput(
          name: 'Every day',
          weekdays: HabitsTestSchedules.daily,
        ),
      )).valueOrNull!;
      final pendingBefore = await database.rawScalar(
        'SELECT count(*) FROM pending_changes',
      );
      clock.advance(const Duration(days: 1));

      final result = await commands.completeHabitToday(
        habit.id,
        expectedAccountId: kTasksPreviewAccountId,
        expectedLocalDate: '2026-10-12',
      );

      expect(result.failureOrNull?.messageKey, 'habits.validation.stale_day');
      expect(
        await database.rawScalar('SELECT count(*) FROM habit_day_records'),
        0,
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM pending_changes'),
        pendingBefore,
      );
    },
  );

  test('a day change during command reads is rejected before write', () async {
    final habit = (await commands.createHabit(
      const CreateHabitInput(
        name: 'Every day',
        weekdays: HabitsTestSchedules.daily,
      ),
    )).valueOrNull!;
    var captures = 0;
    final guarded = HabitCommands(
      repository: DriftHabitRepository(
        database: database,
        codec: const HabitPayloadCodec(),
      ),
      session: const TasksPreviewSession(),
      nowUtc: clock.utcNow,
      localCalendar: () {
        captures++;
        if (captures == 2) clock.advance(const Duration(days: 1));
        return clock.captureLocalCalendar();
      },
      nextOperationId: ids.nextOperationId,
    );

    final result = await guarded.completeHabitToday(habit.id);
    expect(result.failureOrNull?.messageKey, 'habits.validation.stale_day');
    expect(
      await database.rawScalar('SELECT count(*) FROM habit_day_records'),
      0,
    );
  });

  test(
    'retained same-day completion can be undone after schedule removal',
    () async {
      final habit = (await commands.createHabit(
        const CreateHabitInput(name: 'Read', weekdays: {DateTime.monday}),
      )).valueOrNull!;
      expect(
        (await commands.completeHabitToday(habit.id)).failureOrNull,
        isNull,
      );
      clock.advance(const Duration(hours: 1));
      expect(
        (await commands.editHabit(
          EditHabitInput(
            habitId: habit.id,
            name: habit.name,
            weekdays: {DateTime.tuesday},
            reminderMinuteOfDay: null,
          ),
        )).failureOrNull,
        isNull,
      );

      final result = await commands.undoHabitToday(
        habit.id,
        expectedAccountId: kTasksPreviewAccountId,
        expectedLocalDate: '2026-10-12',
      );
      expect(result.failureOrNull, isNull);
      expect(result.valueOrNull?.isCompleted, isFalse);
      expect(
        await database.rawScalar('SELECT count(*) FROM habit_day_records'),
        1,
      );
    },
  );

  test(
    'account switch during fresh reads rejects the Habit day write',
    () async {
      final habit = (await commands.createHabit(
        const CreateHabitInput(
          name: 'Every day',
          weekdays: HabitsTestSchedules.daily,
        ),
      )).valueOrNull!;
      final pendingBefore = await database.rawScalar(
        'SELECT count(*) FROM pending_changes',
      );
      final guarded = HabitCommands(
        repository: DriftHabitRepository(
          database: database,
          codec: const HabitPayloadCodec(),
        ),
        session: _SwitchingSession(),
        nowUtc: clock.utcNow,
        localCalendar: clock.captureLocalCalendar,
        nextOperationId: ids.nextOperationId,
      );

      final result = await guarded.completeHabitToday(
        habit.id,
        expectedAccountId: kTasksPreviewAccountId,
        expectedLocalDate: '2026-10-12',
      );
      expect(result.failureOrNull?.category, AppFailureCategory.authorization);
      expect(
        await database.rawScalar('SELECT count(*) FROM habit_day_records'),
        0,
      );
      expect(
        await database.rawScalar('SELECT count(*) FROM pending_changes'),
        pendingBefore,
      );
    },
  );

  test(
    'concurrent complete and undo serialize against one fresh day',
    () async {
      final habit = (await commands.createHabit(
        const CreateHabitInput(
          name: 'Every day',
          weekdays: HabitsTestSchedules.daily,
        ),
      )).valueOrNull!;
      final completed = commands.completeHabitToday(habit.id);
      final undone = commands.undoHabitToday(habit.id);
      final results = await Future.wait([completed, undone]);
      expect(results.first.failureOrNull, isNull);
      final day =
          (await DriftHabitRepository(
                database: database,
                codec: const HabitPayloadCodec(),
              ).readDay(
                accountId: kTasksPreviewAccountId,
                habitId: habit.id,
                localDate: '2026-10-12',
              ))
              .valueOrNull;
      expect(day, isNotNull);
      expect(day!.isCompleted, results.last.failureOrNull != null);
      expect(
        await database.rawScalar('SELECT count(*) FROM habit_day_records'),
        1,
      );
    },
  );
}

class _SwitchingSession implements CloudSessionPort {
  int calls = 0;
  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async {
    calls++;
    return AppResult.success(
      CloudSyncContext(
        accountId: calls == 1 ? kTasksPreviewAccountId : kHabitsTestAccountB,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
