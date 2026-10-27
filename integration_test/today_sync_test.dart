import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_environment.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_session_adapter.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/task_completion_unit_of_work.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/data/sync/synchronization_coordinator.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/data/habit_reconciler.dart';
import 'package:namma_project/features/habits/data/supabase_habit_reader.dart';
import 'package:namma_project/features/habits/data/supabase_habit_sync_adapter.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/supabase_task_reader.dart';
import 'package:namma_project/features/tasks/data/supabase_task_sync_adapter.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/data/task_reconciler.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/today/application/today_calendar_port.dart';
import 'package:namma_project/features/today/data/habits_today_adapter.dart';
import 'package:namma_project/features/today/data/tasks_today_adapter.dart';
import 'package:namma_project/features/today/data/xp_today_adapter.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';
import 'package:namma_project/features/today/presentation/today_cubit.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';

import '../test/support/foundation_test_support.dart';

/// Default: two independent sessions/stores on one host. With a shared UUID,
/// day and A/B roles, run first on Windows then Android for device evidence.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('staging owner changes converge in two isolated Today sessions', (
    tester,
  ) async {
    const url = String.fromEnvironment('NAMAA_SUPABASE_URL');
    const key = String.fromEnvironment('NAMAA_SUPABASE_PUBLISHABLE_KEY');
    const emailA = String.fromEnvironment('NAMAA_STAGING_TEST_USER_A_EMAIL');
    const passwordA = String.fromEnvironment(
      'NAMAA_STAGING_TEST_USER_A_PASSWORD',
    );
    const emailB = String.fromEnvironment('NAMAA_STAGING_TEST_USER_B_EMAIL');
    const passwordB = String.fromEnvironment(
      'NAMAA_STAGING_TEST_USER_B_PASSWORD',
    );
    const role = String.fromEnvironment('NAMAA_TWO_DEVICE_ROLE');
    const runId = String.fromEnvironment('NAMAA_TWO_DEVICE_RUN_ID');
    const dayKey = String.fromEnvironment('NAMAA_TWO_DEVICE_DAY');
    expect(role, anyOf('', 'A', 'B'));
    if (role.isNotEmpty) {
      expect(runId, matches(RegExp(r'^[0-9a-f-]{36}$')));
      TodayLocalDate.parse(dayKey);
    }
    for (final value in [url, key, emailA, passwordA, emailB, passwordB]) {
      expect(
        value,
        isNotEmpty,
        reason: 'Isolated staging credentials are required',
      );
    }
    final uri = Uri.parse(url);
    final config = SupabaseEnvironmentConfig.isolatedNonProduction(
      url: uri,
      publishableKey: key,
      approvedHosts: {uri.host},
    );
    final clientA = createSupabaseClient(config);
    final clientB = createSupabaseClient(config);
    final foreignClient = createSupabaseClient(config);
    addTearDown(clientA.dispose);
    addTearDown(clientB.dispose);
    addTearDown(foreignClient.dispose);
    final authA = await clientA.auth.signInWithPassword(
      email: emailA,
      password: passwordA,
    );
    final authB = await clientB.auth.signInWithPassword(
      email: emailA,
      password: passwordA,
    );
    final foreignAuth = await foreignClient.auth.signInWithPassword(
      email: emailB,
      password: passwordB,
    );
    final owner = authA.user!.id;
    expect(authB.user!.id, owner);
    expect(foreignAuth.user!.id, isNot(owner));

    final paths = [TemporaryDatabasePath(), TemporaryDatabasePath()];
    final encryptionKey = List<int>.generate(32, (i) => i + 21);
    final dbA = await FoundationDatabase.openEncrypted(
      path: paths[0].allocate(),
      key: encryptionKey,
    );
    final dbB = await FoundationDatabase.openEncrypted(
      path: paths[1].allocate(),
      key: encryptionKey,
    );
    addTearDown(() async {
      await dbA.close();
      await dbB.close();
      for (final path in paths) {
        path.dispose();
      }
    });
    const taskCodec = TaskPayloadCodec();
    const habitCodec = HabitPayloadCodec();
    final tasksA = DriftTaskRepository(database: dbA, codec: taskCodec);
    final tasksB = DriftTaskRepository(database: dbB, codec: taskCodec);
    final habitsA = DriftHabitRepository(database: dbA, codec: habitCodec);
    final habitsB = DriftHabitRepository(database: dbB, codec: habitCodec);
    final awardsA = DriftAwardLedger(dbA);
    final awardsB = DriftAwardLedger(dbB);
    final sessionA = SupabaseSessionAdapter(
      gateway: SupabaseAuthGatewayImpl(clientA),
    );
    expect((await sessionA.initialize()).failureOrNull, isNull);

    final today = role.isEmpty
        ? DateTime.now().toUtc()
        : DateTime.parse('${dayKey}T12:00:00Z');
    final localDate = TodayLocalDate(today.year, today.month, today.day);
    if (role == 'A') {
      expect(
        localDate,
        TodayLocalDate.fromCivil(DateTime.now().toUtc()),
        reason: 'The writing device must run on its agreed UTC day',
      );
    }
    final clockA = _Clock(localDate, 0);
    final clockB = _Clock(localDate, 0);
    final scope = TodayScope.account(accountId: owner, generation: 1);
    final todayA = TodayCubit(
      scope: scope,
      calendar: clockA,
      tasks: TasksTodayAdapter(tasksA),
      habits: HabitsTodayAdapter(habitsA),
      xp: XpTodayAdapter(awardsA),
    );
    final todayB = TodayCubit(
      scope: scope,
      calendar: clockB,
      tasks: TasksTodayAdapter(tasksB),
      habits: HabitsTodayAdapter(habitsB),
      xp: XpTodayAdapter(awardsB),
    );
    addTearDown(() async {
      await todayA.close();
      await todayB.close();
    });

    final taskId = role.isEmpty ? _uuid() : runId;
    final habitId = role.isEmpty
        ? _uuid()
        : '${runId[0] == 'a' ? 'b' : 'a'}${runId.substring(1)}';
    final taskGatewayB = SupabaseTaskGatewayImpl(clientB);
    final habitGatewayB = SupabaseHabitGatewayImpl(clientB);
    if (role != 'B') {
      final task = Task.create(
        id: taskId,
        accountId: owner,
        title: 'Today sync $taskId',
        scheduledDate: DateTime(today.year, today.month, today.day),
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
      );
      expect(
        (await tasksA.commitTask(
          TaskWriteRequest(
            task: task,
            operationId: 'today-seed-$taskId',
            kind: ChangeKind.create,
            queuedAt: task.createdAt,
          ),
        )).failureOrNull,
        isNull,
      );
      final habit = Habit.create(
        id: habitId,
        accountId: owner,
        name: 'Today sync $habitId',
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        revisionId: _uuid(),
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
        effectiveLocalDate: localDate.key,
        utcOffsetMinutes: 0,
      );
      expect(
        (await habitsA.commitHabit(
          HabitWriteRequest(
            habit: habit,
            operationId: 'today-seed-$habitId',
            kind: ChangeKind.create,
            queuedAt: habit.createdAt,
          ),
        )).failureOrNull,
        isNull,
      );

      final taskCompletion = TaskCompletionService(
        repository: tasksA,
        unitOfWork: DriftTaskCompletionUnitOfWork(
          database: dbA,
          codec: taskCodec,
          awardLedger: awardsA,
        ),
        session: sessionA,
        nowUtc: () => DateTime.now().toUtc(),
        currentLocalDate: () => DateTime(today.year, today.month, today.day),
        nextOperationId: _uuid,
      );
      expect(
        (await taskCompletion.completeTask(
          taskId,
          expectedAccountId: owner,
          expectedLocalDate: DateTime(today.year, today.month, today.day),
        )).failureOrNull,
        isNull,
      );
      final habitCommands = HabitCommands(
        repository: habitsA,
        session: sessionA,
        nowUtc: () => DateTime.now().toUtc(),
        localCalendar: () => (localDate: localDate.key, utcOffsetMinutes: 0),
        nextOperationId: _uuid,
      );
      expect(
        (await habitCommands.completeHabitToday(
          habitId,
          expectedAccountId: owner,
          expectedLocalDate: localDate.key,
        )).failureOrNull,
        isNull,
      );

      final pendingStore = DriftLocalStore(dbA);
      final pending = (await pendingStore.readPendingChanges(
        owner,
      )).valueOrNull!;
      expect(pending, hasLength(4));
      final taskGatewayA = SupabaseTaskGatewayImpl(clientA);
      final habitGatewayA = SupabaseHabitGatewayImpl(clientA);
      final taskOutbound = SupabaseTaskSyncAdapter(gateway: taskGatewayA);
      final habitOutbound = SupabaseHabitSyncAdapter(gateway: habitGatewayA);
      final outbound = await SynchronizationCoordinator(
        localStore: pendingStore,
        cloudSession: sessionA,
        cloudSync: EntityDispatchRouter(
          foundationAdapter: taskOutbound,
          taskAdapter: taskOutbound,
          habitAdapter: habitOutbound,
          habitDayAdapter: habitOutbound,
        ),
      ).synchronize();
      expect(outbound.failureOrNull, isNull);
      expect(outbound.valueOrNull!.recoverableFailures, 0);
      expect(outbound.valueOrNull!.equalTimestampConflicts, 0);
      expect(
        (await pendingStore.readPendingChanges(owner)).valueOrNull,
        isEmpty,
      );
    }

    final taskReader = SupabaseTaskReader(
      gateway: taskGatewayB,
      codec: taskCodec,
    );
    final habitReader = SupabaseHabitReader(gateway: habitGatewayB);
    var remoteTasks = await taskReader.readAllTasks(owner);
    var remoteAwards = await taskReader.readAllTaskAwards(owner);
    var remoteHabits = await habitReader.readAll(owner);
    if (role == 'B') {
      final until = DateTime.now().add(const Duration(minutes: 3));
      while (DateTime.now().isBefore(until) &&
          ((remoteTasks.valueOrNull
                      ?.where((row) => row.id == taskId && row.isCompleted)
                      .isEmpty ??
                  true) ||
              (remoteAwards.valueOrNull
                      ?.where((row) => row.sourceId == taskId)
                      .isEmpty ??
                  true) ||
              (remoteHabits.valueOrNull?.days
                      .where((row) => row.habitId == habitId)
                      .isEmpty ??
                  true))) {
        await Future<void>.delayed(const Duration(seconds: 2));
        remoteTasks = await taskReader.readAllTasks(owner);
        remoteAwards = await taskReader.readAllTaskAwards(owner);
        remoteHabits = await habitReader.readAll(owner);
      }
    }
    expect(remoteTasks.failureOrNull, isNull);
    expect(remoteAwards.failureOrNull, isNull);
    expect(remoteHabits.failureOrNull, isNull);
    expect(
      remoteTasks.valueOrNull!.where(
        (row) => row.id == taskId && row.isCompleted,
      ),
      hasLength(1),
    );
    expect(
      remoteAwards.valueOrNull!.where((row) => row.sourceId == taskId),
      hasLength(1),
    );
    expect(
      remoteHabits.valueOrNull!.habits.where((row) => row.id == habitId),
      hasLength(1),
    );
    expect(
      remoteHabits.valueOrNull!.days.where((row) => row.habitId == habitId),
      hasLength(1),
    );

    final propagation = Stopwatch()..start();
    Duration? taskLocalAt;
    Duration? habitLocalAt;
    Duration? awardLocalAt;
    Duration? taskTodayAt;
    Duration? habitTodayAt;
    Duration? awardTodayAt;
    final observations = <StreamSubscription<dynamic>>[
      tasksB.watchTasks(owner).listen((rows) {
        if (taskLocalAt == null &&
            rows.any((row) => row.id == taskId && row.isCompleted)) {
          taskLocalAt = propagation.elapsed;
        }
      }),
      habitsB.watchDays(owner).listen((rows) {
        if (habitLocalAt == null &&
            rows.any((row) => row.habitId == habitId && row.isCompleted)) {
          habitLocalAt = propagation.elapsed;
        }
      }),
      awardsB.watchAwards(owner).listen((rows) {
        if (awardLocalAt == null && rows.any((row) => row.sourceId == taskId)) {
          awardLocalAt = propagation.elapsed;
        }
      }),
      todayB.stream.listen((state) {
        if (taskTodayAt == null &&
            (state.tasks.value?.items.any(
                  (row) => row.taskId == taskId && row.isCompleted,
                ) ??
                false)) {
          taskTodayAt = propagation.elapsed;
        }
        if (habitTodayAt == null &&
            (state.habits.value?.items.any(
                  (row) => row.habitId == habitId && row.isCompleted,
                ) ??
                false)) {
          habitTodayAt = propagation.elapsed;
        }
        if (awardTodayAt == null &&
            (state.xp.value?.awards.any((row) => row.sourceId == taskId) ??
                false)) {
          awardTodayAt = propagation.elapsed;
        }
      }),
    ];
    addTearDown(() async {
      for (final observation in observations) {
        await observation.cancel();
      }
    });
    expect(
      (await TaskReconciler(
            repository: tasksB,
            localStore: DriftLocalStore(dbB),
            codec: taskCodec,
          ).reconcile(accountId: owner, remoteTasks: remoteTasks.valueOrNull!))
          .failureOrNull,
      isNull,
    );
    expect(
      (await HabitReconciler(
            store: habitsB,
            localStore: DriftLocalStore(dbB),
          ).reconcile(accountId: owner, remote: remoteHabits.valueOrNull!))
          .failureOrNull,
      isNull,
    );
    for (final award in remoteAwards.valueOrNull!) {
      expect((await awardsB.applyRemoteAward(award)).failureOrNull, isNull);
    }
    final localAppliedAt = propagation.elapsed;
    while (propagation.elapsed - localAppliedAt < const Duration(seconds: 2) &&
        (taskLocalAt == null ||
            habitLocalAt == null ||
            awardLocalAt == null ||
            taskTodayAt == null ||
            habitTodayAt == null ||
            awardTodayAt == null)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(taskLocalAt, isNotNull);
    expect(habitLocalAt, isNotNull);
    expect(awardLocalAt, isNotNull);
    expect(taskTodayAt, isNotNull);
    expect(habitTodayAt, isNotNull);
    expect(awardTodayAt, isNotNull);
    expect(taskTodayAt! - taskLocalAt!, lessThan(const Duration(seconds: 2)));
    expect(habitTodayAt! - habitLocalAt!, lessThan(const Duration(seconds: 2)));
    expect(awardTodayAt! - awardLocalAt!, lessThan(const Duration(seconds: 2)));
    if (role != 'B') {
      expect(
        todayA.state.tasks.value!.items.where(
          (row) => row.taskId == taskId && row.isCompleted,
        ),
        hasLength(1),
      );
    }
    expect(
      todayB.state.tasks.value!.items.where(
        (row) => row.taskId == taskId && row.isCompleted,
      ),
      hasLength(1),
    );
    expect(
      todayB.state.habits.value!.items.where(
        (row) => row.habitId == habitId && row.isCompleted,
      ),
      hasLength(1),
    );
    expect(
      todayB.state.xp.value!.awards.where((row) => row.sourceId == taskId),
      hasLength(1),
    );

    clockB.localDate = localDate.next;
    clockB.offsetMinutes = -120;
    todayB.refresh();
    expect(
      todayB.state.tasks.value!.items.where((row) => row.taskId == taskId),
      isEmpty,
    );
    expect(
      todayB.state.habits.value!.items.where(
        (row) => row.habitId == habitId && row.isCompleted,
      ),
      isEmpty,
    );
    expect(
      todayB.state.xp.value!.awards.where((row) => row.sourceId == taskId),
      isEmpty,
    );
    final storedTask = await tasksB.readTask(accountId: owner, taskId: taskId);
    final storedDay = await habitsB.readDay(
      accountId: owner,
      habitId: habitId,
      localDate: localDate.key,
    );
    expect(
      storedTask.valueOrNull?.scheduledDate,
      DateTime(localDate.year, localDate.month, localDate.day),
    );
    expect(storedDay.valueOrNull?.localDate, localDate.key);
    final foreignTasks = await SupabaseTaskReader(
      gateway: SupabaseTaskGatewayImpl(foreignClient),
      codec: taskCodec,
    ).readAllTasks(foreignAuth.user!.id);
    final foreignAwards = await SupabaseTaskReader(
      gateway: SupabaseTaskGatewayImpl(foreignClient),
      codec: taskCodec,
    ).readAllTaskAwards(foreignAuth.user!.id);
    final foreignHabits = await SupabaseHabitReader(
      gateway: SupabaseHabitGatewayImpl(foreignClient),
    ).readAll(foreignAuth.user!.id);
    expect(foreignTasks.failureOrNull, isNull);
    expect(foreignAwards.failureOrNull, isNull);
    expect(foreignHabits.failureOrNull, isNull);
    expect(foreignTasks.valueOrNull!.where((row) => row.id == taskId), isEmpty);
    expect(
      foreignAwards.valueOrNull!.where((row) => row.sourceId == taskId),
      isEmpty,
    );
    expect(
      foreignHabits.valueOrNull!.habits.where((row) => row.id == habitId),
      isEmpty,
    );
    expect(
      foreignHabits.valueOrNull!.days.where((row) => row.habitId == habitId),
      isEmpty,
    );
  });
}

class _Clock implements TodayCalendarPort {
  _Clock(this.localDate, this.offsetMinutes);
  TodayLocalDate localDate;
  int offsetMinutes;
  @override
  TodayCalendar sample({required int projectionRevision}) {
    final start = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
    ).subtract(Duration(minutes: offsetMinutes));
    final next = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day + 1,
    ).subtract(Duration(minutes: offsetMinutes));
    return TodayCalendar(
      localDate: localDate,
      nowUtc: start.add(const Duration(hours: 12)),
      utcOffsetMinutes: offsetMinutes,
      dayStartUtc: start,
      nextDayStartUtc: next,
      projectionRevision: projectionRevision,
    );
  }
}

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
