import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/today_localization_adapter.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/task_completion_unit_of_work.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
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
import 'package:namma_project/features/today/domain/today_section.dart';
import 'package:namma_project/features/today/presentation/today_cubit.dart';
import 'package:namma_project/features/today/presentation/today_screen.dart';
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

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  final limit = Stopwatch()..start();
  while (!ready() && limit.elapsed < const Duration(seconds: 10)) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(ready(), isTrue, reason: 'Owner-confirmed Today state never appeared');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('500 Tasks, 100 Habits, 200 persisted awards stay responsive', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp(
      'namaa_today_scale_',
    );
    final path = '${directory.path}${Platform.pathSeparator}today.db';
    final key = await resolveDatabaseKey(
      SecureCredentialVault(store: InMemorySecureKeyValueStore()),
    );
    final db = await FoundationDatabase.openEncrypted(path: path, key: key);
    addTearDown(() async {
      await db.close();
      await directory.delete(recursive: true);
    });
    final tasks = DriftTaskRepository(
      database: db,
      codec: const TaskPayloadCodec(),
    );
    final habits = DriftHabitRepository(
      database: db,
      codec: const HabitPayloadCodec(),
    );
    final awards = DriftAwardLedger(db);
    final created = DateTime.utc(2026, 10, 11, 8);

    // All fixture writes finish before the stopwatch starts. They use the same
    // encrypted owner stores as the app; Today itself has no benchmark branch.
    for (var index = 0; index < 500; index++) {
      final task = Task.create(
        id: TodayOwnerFixture.taskId(index + 1),
        accountId: kTasksPreviewAccountId,
        title: 'Task ${index + 1}',
        scheduledDate: DateTime(2026, 10, 12),
        createdAt: created,
      );
      expect(
        (await tasks.commitTask(
          TaskWriteRequest(
            task: task,
            operationId: 'scale-task-$index',
            kind: ChangeKind.create,
            queuedAt: created,
          ),
        )).failureOrNull,
        isNull,
      );
    }
    for (var index = 0; index < 100; index++) {
      final habit = Habit.create(
        id: TodayOwnerFixture.habitId(index + 1),
        accountId: kHabitsPreviewAccountId,
        name: 'Habit ${index + 1}',
        weekdays: {DateTime.monday},
        revisionId: 'scale-revision-$index',
        createdAt: created,
        effectiveLocalDate: '2026-10-11',
        utcOffsetMinutes: 0,
      );
      expect(
        (await habits.commitHabit(
          HabitWriteRequest(
            habit: habit,
            operationId: 'scale-habit-$index',
            kind: ChangeKind.create,
            queuedAt: created,
          ),
        )).failureOrNull,
        isNull,
      );
    }
    for (var index = 0; index < 200; index++) {
      // A previously completed and reopened Task retains its one-time award.
      expect(
        (await awards.insertOnce(
          TaskCompletionAward(
            accountId: kTasksPreviewAccountId,
            source: kTaskDoneAwardSource,
            sourceId: TodayOwnerFixture.taskId(index + 1),
            amount: 20,
            awardedAt: DateTime.utc(2026, 10, 12, 8),
          ),
        )).failureOrNull,
        isNull,
      );
    }
    expect(await db.rawScalar('SELECT count(*) FROM task_records'), 500);
    expect(await db.rawScalar('SELECT count(*) FROM habit_records'), 100);
    expect(await db.rawScalar('SELECT count(*) FROM xp_awards'), 200);

    var sequence = 0;
    DateTime now() =>
        DateTime.utc(2026, 10, 12, 12).add(Duration(microseconds: ++sequence));
    final completion = TaskCompletionService(
      repository: tasks,
      unitOfWork: DriftTaskCompletionUnitOfWork(
        database: db,
        codec: const TaskPayloadCodec(),
        awardLedger: awards,
      ),
      session: const TasksPreviewSession(),
      nowUtc: now,
      currentLocalDate: () => DateTime(2026, 10, 12),
      nextOperationId: () => 'scale-action-${++sequence}',
    );
    final startup = Stopwatch()..start();
    final cubit = TodayCubit(
      scope: TodayScope.preview(
        taskOwnerId: kTasksPreviewAccountId,
        habitOwnerId: kHabitsPreviewAccountId,
        generation: 1,
      ),
      calendar: _Clock(),
      tasks: TasksTodayAdapter(tasks, completionService: completion),
      habits: HabitsTodayAdapter(habits),
      xp: XpTodayAdapter(awards),
    );
    addTearDown(cubit.close);
    int? stateReadyMs;
    final readyWatch = cubit.stream.listen((state) {
      if (stateReadyMs == null &&
          state.tasks.value?.totalCount == 500 &&
          state.habits.value?.totalCount == 100 &&
          state.xp.value?.amount == 4000) {
        stateReadyMs = startup.elapsedMilliseconds;
      }
    });
    addTearDown(readyWatch.cancel);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: TodayScreen(
          cubit: cubit,
          stringsResolver: resolveTodayStrings,
          onTasks: () {},
          onHabits: () {},
          onMindMaps: () {},
          onPreferences: () {},
        ),
      ),
    );
    final afterFirstPumpMs = startup.elapsedMilliseconds;
    await _until(
      tester,
      () =>
          cubit.state.tasks.status == TodaySectionStatus.available &&
          cubit.state.tasks.value?.totalCount == 500 &&
          cubit.state.habits.value?.totalCount == 100 &&
          cubit.state.xp.value?.amount == 4000,
    );
    await tester.pump();
    startup.stop();
    expect(find.byKey(kTodayScreenKey), findsOneWidget);

    final action = Stopwatch()..start();
    await cubit.setTaskCompleted(TodayOwnerFixture.taskId(500), true);
    await _until(tester, () => cubit.state.tasks.value?.completedCount == 1);
    await tester.pump();
    action.stop();

    final inbound = Stopwatch()..start();
    final changed = (await tasks.readTask(
      accountId: kTasksPreviewAccountId,
      taskId: TodayOwnerFixture.taskId(499),
    )).valueOrNull!.copyWith(title: 'Owner changed 499', updatedAt: now());
    expect(
      (await tasks.commitTask(
        TaskWriteRequest(
          task: changed,
          operationId: 'scale-owner-edit',
          kind: ChangeKind.update,
          queuedAt: changed.updatedAt,
        ),
      )).failureOrNull,
      isNull,
    );
    await _until(
      tester,
      () =>
          cubit.state.tasks.value?.items.any(
            (task) => task.title == 'Owner changed 499',
          ) ==
          true,
    );
    await tester.pump();
    inbound.stop();

    debugPrint(
      'TODAY_SCALE target=${Platform.operatingSystem} mode=${const bool.fromEnvironment('dart.vm.product')
          ? 'release'
          : const bool.fromEnvironment('dart.vm.profile')
          ? 'profile'
          : 'debug'} '
      'tasks=500 habits=100 awards=200 '
      'state_ready_ms=$stateReadyMs first_pump_ms=$afterFirstPumpMs '
      'initial_ms=${startup.elapsedMilliseconds} '
      'action_ms=${action.elapsedMilliseconds} '
      'owner_update_ms=${inbound.elapsedMilliseconds}',
    );
    expect(startup.elapsed, lessThanOrEqualTo(const Duration(seconds: 2)));
    expect(action.elapsed, lessThanOrEqualTo(const Duration(seconds: 2)));
    expect(inbound.elapsed, lessThanOrEqualTo(const Duration(seconds: 2)));
  });
}
