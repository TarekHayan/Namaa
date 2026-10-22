import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/today/application/today_calendar_port.dart';
import 'package:namma_project/features/today/data/habits_today_adapter.dart';
import 'package:namma_project/features/today/data/tasks_today_adapter.dart';
import 'package:namma_project/features/today/data/xp_today_adapter.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/presentation/today_cubit.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import '../test/support/today_fixtures.dart';

class _Clock implements TodayCalendarPort {
  @override
  TodayCalendar sample({required int projectionRevision}) => TodayCalendar(
    localDate: TodayLocalDate(2026, 10, 12),
    nowUtc: DateTime.utc(2026, 10, 12, 12),
    utcOffsetMinutes: 0,
    dayStartUtc: DateTime.utc(2026, 10, 12),
    nextDayStartUtc: DateTime.utc(2026, 10, 13),
    projectionRevision: projectionRevision,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'encrypted preview owner records survive restart and ten read-only refreshes',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'namaa_today_offline_',
      );
      final path = '${directory.path}${Platform.pathSeparator}today.db';
      final vault = SecureCredentialVault(store: InMemorySecureKeyValueStore());
      final key = await resolveDatabaseKey(vault);
      FoundationDatabase? database;
      addTearDown(() async {
        await database?.close();
        await directory.delete(recursive: true);
      });
      database = await FoundationDatabase.openEncrypted(path: path, key: key);
      final tasks = DriftTaskRepository(
        database: database,
        codec: const TaskPayloadCodec(),
      );
      final habits = DriftHabitRepository(
        database: database,
        codec: const HabitPayloadCodec(),
      );
      final ledger = DriftAwardLedger(database);
      final created = DateTime.utc(2026, 10, 10, 8);
      for (var index = 0; index < 10; index++) {
        var task = Task.create(
          id: TodayOwnerFixture.taskId(index + 1),
          accountId: kTasksPreviewAccountId,
          title: 'Trial task ${index + 1}',
          scheduledDate: DateTime(2026, 10, 12),
          createdAt: created,
        );
        if (index < 4) task = task.complete(DateTime.utc(2026, 10, 12, 8));
        final result = await tasks.commitTask(
          TaskWriteRequest(
            task: task,
            operationId: 'today-task-$index',
            kind: ChangeKind.create,
            queuedAt: created,
          ),
        );
        expect(result.failureOrNull, isNull);
      }
      for (final (sequence, scheduledDate, deleted) in [
        (11, DateTime(2026, 10, 11), false),
        (12, DateTime(2026, 10, 13), false),
        (14, DateTime(2026, 10, 12), true),
      ]) {
        var task = Task.create(
          id: TodayOwnerFixture.taskId(sequence),
          accountId: kTasksPreviewAccountId,
          title: 'Other-date task $sequence',
          scheduledDate: scheduledDate,
          createdAt: created,
        );
        if (deleted) task = task.markDeleted(DateTime.utc(2026, 10, 12, 10));
        expect(
          (await tasks.commitTask(
            TaskWriteRequest(
              task: task,
              operationId: 'today-extra-task-$sequence',
              kind: ChangeKind.create,
              queuedAt: created,
            ),
          )).failureOrNull,
          isNull,
        );
      }
      expect(
        (await tasks.commitTask(
          TaskWriteRequest(
            task: Task.create(
              id: TodayOwnerFixture.taskId(15),
              accountId: TodayFixtureAccounts.accountB,
              title: 'Other account task',
              scheduledDate: DateTime(2026, 10, 12),
              createdAt: created,
            ),
            operationId: 'today-foreign-task',
            kind: ChangeKind.create,
            queuedAt: created,
          ),
        )).failureOrNull,
        isNull,
      );
      for (var index = 0; index < 5; index++) {
        var habit = Habit.create(
          id: TodayOwnerFixture.habitId(index + 1),
          accountId: kHabitsPreviewAccountId,
          name: 'Trial habit ${index + 1}',
          weekdays: {DateTime.monday},
          revisionId: 'today-revision-$index',
          createdAt: created,
          effectiveLocalDate: '2026-10-10',
          utcOffsetMinutes: 0,
        );
        if (index == 0 || index == 4) {
          final day = HabitDay.completed(
            accountId: kHabitsPreviewAccountId,
            habitId: habit.id,
            localDate: '2026-10-12',
            completedAt: DateTime.utc(2026, 10, 12, 8),
            earnedAgainstRevisionId: habit.scheduleRevisions.first.revisionId,
            recordedUtcOffsetMinutes: 0,
          );
          expect(
            (await habits.commitDay(
              HabitDayWriteRequest(
                day: day,
                operationId: 'today-day-$index',
                kind: ChangeKind.create,
                queuedAt: created,
              ),
            )).failureOrNull,
            isNull,
          );
        }
        if (index == 4) {
          habit = habit.edit(
            name: habit.name,
            weekdays: {DateTime.tuesday},
            reminderMinuteOfDay: null,
            revisionId: 'today-revised-$index',
            editedAt: DateTime.utc(2026, 10, 12, 9),
            effectiveLocalDate: '2026-10-12',
            utcOffsetMinutes: 0,
          );
        }
        expect(
          (await habits.commitHabit(
            HabitWriteRequest(
              habit: habit,
              operationId: 'today-habit-$index',
              kind: ChangeKind.create,
              queuedAt: created,
            ),
          )).failureOrNull,
          isNull,
        );
      }
      expect(
        (await habits.commitHabit(
          HabitWriteRequest(
            habit: Habit.create(
              id: TodayOwnerFixture.habitId(6),
              accountId: kHabitsPreviewAccountId,
              name: 'Not due today',
              weekdays: {DateTime.tuesday},
              revisionId: 'today-extra-revision',
              createdAt: created,
              effectiveLocalDate: '2026-10-10',
              utcOffsetMinutes: 0,
            ),
            operationId: 'today-extra-habit',
            kind: ChangeKind.create,
            queuedAt: created,
          ),
        )).failureOrNull,
        isNull,
      );
      expect(
        (await ledger.insertOnce(
          TaskCompletionAward(
            accountId: kTasksPreviewAccountId,
            source: kTaskDoneAwardSource,
            sourceId: TodayOwnerFixture.taskId(1),
            amount: 20,
            awardedAt: DateTime.utc(2026, 10, 12, 8),
          ),
        )).failureOrNull,
        isNull,
      );
      expect(
        (await ledger.insertOnce(
          TaskCompletionAward(
            accountId: kTasksPreviewAccountId,
            source: kTaskDoneAwardSource,
            sourceId: TodayOwnerFixture.taskId(2),
            amount: 20,
            awardedAt: DateTime.utc(2026, 10, 11, 8),
          ),
        )).failureOrNull,
        isNull,
      );
      expect(
        (await ledger.insertOnce(
          TaskCompletionAward(
            accountId: kTasksPreviewAccountId,
            source: kTaskDoneAwardSource,
            sourceId: TodayOwnerFixture.taskId(14),
            amount: 20,
            awardedAt: DateTime.utc(2026, 10, 12, 8),
          ),
        )).failureOrNull,
        isNull,
      );

      Future<List<int>> counts(FoundationDatabase db) async {
        final values = <int>[];
        for (final table in [
          'task_records',
          'habit_records',
          'habit_day_records',
          'xp_awards',
          'pending_changes',
        ]) {
          values.add(
            (await db
                    .customSelect('SELECT COUNT(*) AS c FROM $table')
                    .getSingle())
                .read<int>('c'),
          );
        }
        return values;
      }

      final before = await counts(database);
      final scope = TodayScope.preview(
        taskOwnerId: kTasksPreviewAccountId,
        habitOwnerId: kHabitsPreviewAccountId,
        generation: 1,
      );
      Future<void> inspect(FoundationDatabase db) async {
        final cubit = TodayCubit(
          scope: scope,
          calendar: _Clock(),
          tasks: TasksTodayAdapter(
            DriftTaskRepository(database: db, codec: const TaskPayloadCodec()),
          ),
          habits: HabitsTodayAdapter(
            DriftHabitRepository(
              database: db,
              codec: const HabitPayloadCodec(),
            ),
          ),
          xp: XpTodayAdapter(DriftAwardLedger(db)),
        );
        try {
          await cubit.stream
              .firstWhere(
                (state) =>
                    state.tasks.value != null &&
                    state.habits.value != null &&
                    state.xp.value != null,
              )
              .timeout(const Duration(seconds: 5));
          expect(cubit.state.tasks.value?.completedCount, 4);
          expect(cubit.state.tasks.value?.totalCount, 10);
          expect(cubit.state.tasks.value?.percent, 40);
          expect(cubit.state.habits.value?.completedCount, 2);
          expect(cubit.state.habits.value?.totalCount, 5);
          expect(cubit.state.habits.value?.percent, 40);
          expect(cubit.state.xp.value?.amount, 40);
          for (var index = 0; index < 10; index++) {
            cubit.refresh();
          }
        } finally {
          await cubit.close();
        }
      }

      await inspect(database);
      expect(await counts(database), before);
      await database.close();
      database = await FoundationDatabase.openEncrypted(path: path, key: key);
      await inspect(database);
      expect(await counts(database), before);
    },
  );
}
