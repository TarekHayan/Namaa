import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/task_completion_unit_of_work.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/today/application/today_actions.dart';
import 'package:namma_project/features/today/application/today_calendar_port.dart';
import 'package:namma_project/features/today/application/today_tasks_port.dart';
import 'package:namma_project/features/today/data/habits_today_adapter.dart';
import 'package:namma_project/features/today/data/tasks_today_adapter.dart';
import 'package:namma_project/features/today/data/xp_today_adapter.dart';
import 'package:namma_project/features/today/domain/today_agenda.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_priority.dart';
import 'package:namma_project/features/today/domain/today_projection.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/domain/today_section.dart';
import 'package:namma_project/features/today/presentation/today_cubit.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import '../test/support/today_fixtures.dart';

class _Clock implements TodayCalendarPort {
  TodayLocalDate localDate = TodayLocalDate(2026, 10, 12);
  int utcOffsetMinutes = 0;
  @override
  TodayCalendar sample({required int projectionRevision}) {
    final start = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
    ).subtract(Duration(minutes: utcOffsetMinutes));
    final next = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day + 1,
    ).subtract(Duration(minutes: utcOffsetMinutes));
    return TodayCalendar(
      localDate: localDate,
      nowUtc: start.add(const Duration(hours: 12)),
      utcOffsetMinutes: utcOffsetMinutes,
      dayStartUtc: start,
      nextDayStartUtc: next,
      projectionRevision: projectionRevision,
    );
  }
}

class _RecoveringTasks implements TodayTasksPort {
  _RecoveringTasks(this.delegate);
  final TodayTasksPort delegate;
  bool failOnce = true;

  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) {
    if (!failOnce) return delegate.watchTasks(ownerId);
    failOnce = false;
    return (() async* {
      yield await delegate.watchTasks(ownerId).first;
      throw StateError('simulated read interruption after local snapshot');
    })();
  }

  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String taskId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) => delegate.setCompleted(
    ownerId: ownerId,
    taskId: taskId,
    expectedLocalDate: expectedLocalDate,
    completed: completed,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ten offline Today desired-state cycles retain one award across restart',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'namaa_today_actions_',
      );
      final path = '${directory.path}${Platform.pathSeparator}today.db';
      final key = await resolveDatabaseKey(
        SecureCredentialVault(store: InMemorySecureKeyValueStore()),
      );
      var database = await FoundationDatabase.openEncrypted(
        path: path,
        key: key,
      );
      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });
      var sequence = 0;
      TodayActions actions() {
        final tasks = DriftTaskRepository(
          database: database,
          codec: const TaskPayloadCodec(),
        );
        final habits = DriftHabitRepository(
          database: database,
          codec: const HabitPayloadCodec(),
        );
        DateTime now() => DateTime.utc(
          2026,
          10,
          12,
          12,
        ).add(Duration(microseconds: ++sequence));
        String operation() => 'today-action-${++sequence}';
        return TodayActions(
          tasks: TasksTodayAdapter(
            tasks,
            completionService: TaskCompletionService(
              repository: tasks,
              unitOfWork: DriftTaskCompletionUnitOfWork(
                database: database,
                codec: const TaskPayloadCodec(),
                awardLedger: DriftAwardLedger(database),
              ),
              session: const TasksPreviewSession(),
              nowUtc: now,
              currentLocalDate: () => DateTime(2026, 10, 12),
              nextOperationId: operation,
            ),
          ),
          habits: HabitsTodayAdapter(
            habits,
            commands: HabitCommands(
              repository: habits,
              session: const HabitsPreviewSession(),
              nowUtc: now,
              localCalendar: () =>
                  (localDate: '2026-10-12', utcOffsetMinutes: 0),
              nextOperationId: operation,
            ),
          ),
        );
      }

      final task = Task.create(
        id: TodayOwnerFixture.taskId(1),
        accountId: kTasksPreviewAccountId,
        title: 'Offline task',
        scheduledDate: DateTime(2026, 10, 12),
        createdAt: DateTime.utc(2026, 10, 11, 8),
        completionXp: 25,
      );
      expect(
        (await DriftTaskRepository(
              database: database,
              codec: const TaskPayloadCodec(),
            ).commitTask(
              TaskWriteRequest(
                task: task,
                operationId: 'today-seed-task',
                kind: ChangeKind.create,
                queuedAt: task.createdAt,
              ),
            ))
            .failureOrNull,
        isNull,
      );
      final habit = Habit.create(
        id: TodayOwnerFixture.habitId(1),
        accountId: kHabitsPreviewAccountId,
        name: 'Offline habit',
        weekdays: {DateTime.monday},
        revisionId: 'today-seed-revision',
        createdAt: DateTime.utc(2026, 10, 11, 8),
        effectiveLocalDate: '2026-10-11',
        utcOffsetMinutes: 0,
      );
      expect(
        (await DriftHabitRepository(
              database: database,
              codec: const HabitPayloadCodec(),
            ).commitHabit(
              HabitWriteRequest(
                habit: habit,
                operationId: 'today-seed-habit',
                kind: ChangeKind.create,
                queuedAt: habit.createdAt,
              ),
            ))
            .failureOrNull,
        isNull,
      );
      final scope = TodayScope.preview(
        taskOwnerId: kTasksPreviewAccountId,
        habitOwnerId: kHabitsPreviewAccountId,
        generation: 1,
      );
      final day = TodayLocalDate(2026, 10, 12);
      var dispatch = actions();
      for (var cycle = 0; cycle < 10; cycle++) {
        expect(
          (await dispatch.setTaskCompleted(
            scope: scope,
            expectedLocalDate: day,
            taskId: task.id,
            completed: true,
          )).failureOrNull,
          isNull,
          reason: 'Task complete cycle $cycle',
        );
        expect(
          (await dispatch.setHabitCompleted(
            scope: scope,
            expectedLocalDate: day,
            habitId: habit.id,
            completed: true,
          )).failureOrNull,
          isNull,
          reason: 'Habit complete cycle $cycle',
        );
        expect(await database.rawScalar('SELECT count(*) FROM xp_awards'), 1);
        expect(
          (await dispatch.setTaskCompleted(
            scope: scope,
            expectedLocalDate: day,
            taskId: task.id,
            completed: false,
          )).failureOrNull,
          isNull,
          reason: 'Task reopen cycle $cycle',
        );
        expect(
          (await dispatch.setHabitCompleted(
            scope: scope,
            expectedLocalDate: day,
            habitId: habit.id,
            completed: false,
          )).failureOrNull,
          isNull,
          reason: 'Habit undo cycle $cycle',
        );
        if (cycle == 4) {
          await database.close();
          database = await FoundationDatabase.openEncrypted(
            path: path,
            key: key,
          );
          dispatch = actions();
        }
      }
      // A return from the owner must read its current Task, not a captured
      // Today copy. The same stable ID feeds agenda and priority references.
      final ownerRepository = DriftTaskRepository(
        database: database,
        codec: const TaskPayloadCodec(),
      );
      final currentTask = (await ownerRepository.readTask(
        accountId: kTasksPreviewAccountId,
        taskId: task.id,
      )).valueOrNull!;
      final renamed = currentTask.copyWith(
        title: 'Edited in Tasks',
        updatedAt: DateTime.utc(2026, 10, 12, 13),
      );
      expect(
        (await ownerRepository.commitTask(
          TaskWriteRequest(
            task: renamed,
            operationId: 'today-owner-edit',
            kind: ChangeKind.update,
            queuedAt: renamed.updatedAt,
          ),
        )).failureOrNull,
        isNull,
      );
      final calendar = _Clock().sample(projectionRevision: 0);
      final latest = (await TasksTodayAdapter(
        ownerRepository,
      ).watchTasks(kTasksPreviewAccountId).first).project(calendar);
      final summary = TodayProjection.tasks(scope, calendar, latest);
      expect(summary.items.single.title, 'Edited in Tasks');
      expect(summary.items.single.taskId, task.id);
      expect(
        TodayAgenda.project(
          day,
          latest,
          ownerId: kTasksPreviewAccountId,
        ).untimed.single.taskId,
        task.id,
      );
      expect(
        TodayPriority.project(
          kTasksPreviewAccountId,
          day,
          latest,
        ).doFirst.single.taskId,
        task.id,
      );
      expect(await database.rawScalar('SELECT count(*) FROM xp_awards'), 1);
      expect(
        await database.rawScalar('SELECT count(*) FROM habit_day_records'),
        1,
      );
      expect(
        await DriftAwardLedger(
          database,
        ).watchAwards(kHabitsPreviewAccountId).first,
        isEmpty,
      );
    },
  );

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
        final clock = _Clock();
        final recoveringTasks = _RecoveringTasks(
          TasksTodayAdapter(
            DriftTaskRepository(database: db, codec: const TaskPayloadCodec()),
          ),
        );
        final cubit = TodayCubit(
          scope: scope,
          calendar: clock,
          tasks: recoveringTasks,
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
          if (cubit.state.tasks.status != TodaySectionStatus.stale) {
            await cubit.stream
                .firstWhere(
                  (state) => state.tasks.status == TodaySectionStatus.stale,
                )
                .timeout(const Duration(seconds: 5));
          }
          expect(cubit.state.tasks.value?.totalCount, 10);
          expect(cubit.state.habits.status, TodaySectionStatus.available);
          expect(cubit.state.xp.status, TodaySectionStatus.available);
          cubit.retryTasks();
          if (cubit.state.tasks.status != TodaySectionStatus.available) {
            await cubit.stream
                .firstWhere(
                  (state) => state.tasks.status == TodaySectionStatus.available,
                )
                .timeout(const Duration(seconds: 5));
          }
          for (var index = 0; index < 10; index++) {
            cubit.refresh();
          }
          clock.localDate = TodayLocalDate(2026, 10, 13);
          cubit.resumeForeground();
          expect(cubit.state.tasks.value?.totalCount, 1);
          expect(cubit.state.xp.value?.amount, 0);
          clock.localDate = TodayLocalDate(2026, 10, 12);
          clock.utcOffsetMinutes = 60;
          cubit.refresh();
          expect(cubit.state.tasks.value?.totalCount, 10);
          expect(cubit.state.habits.value?.completedCount, 2);
          expect(cubit.state.xp.value?.amount, 40);
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
