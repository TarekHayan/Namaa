import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/task_completion_unit_of_work.dart';
import 'package:namma_project/features/tasks/application/task_completion_unit_of_work.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import '../../../support/foundation_test_support.dart';
import '../../../support/tasks_test_support.dart';

void main() {
  final encryptionKey = List<int>.generate(32, (index) => 0x31 + index);
  const codec = TaskPayloadCodec();
  late TemporaryDatabasePath temporaryPath;
  late FoundationDatabase database;
  late DriftTaskRepository tasks;
  late DriftAwardLedger awards;
  late DriftTaskCompletionUnitOfWork completionUnit;

  setUp(() async {
    temporaryPath = TemporaryDatabasePath();
    database = await FoundationDatabase.openEncrypted(
      path: temporaryPath.allocate(),
      key: encryptionKey,
    );
    tasks = DriftTaskRepository(database: database, codec: codec);
    awards = DriftAwardLedger(database);
    completionUnit = DriftTaskCompletionUnitOfWork(
      database: database,
      codec: codec,
      awardLedger: awards,
    );
  });

  tearDown(() async {
    await database.close();
    temporaryPath.dispose();
  });

  test('award identity is the immutable account/task_done/Task key', () {
    final award = _award(
      accountId: kTasksTestAccountA,
      taskId: kTasksTestTaskId,
      amount: 35,
    );

    expect(award.source, kTaskDoneAwardSource);
    expect(award.sourceId, kTasksTestTaskId);
    expect(award.amount, 35);
    expect(award.uniqueKey, '$kTasksTestAccountA/task_done/$kTasksTestTaskId');
  });

  test('completion commit rejects an award that differs from its Task', () {
    final completedAt = DateTime.utc(2026, 10, 11, 9);
    final task = _task().complete(completedAt);

    expect(
      () => TaskCompletionCommit(
        task: task,
        firstAward: TaskCompletionAward(
          accountId: task.accountId,
          source: kTaskDoneAwardSource,
          sourceId: task.id,
          amount: task.completionXp + 1,
          awardedAt: completedAt,
        ),
        operationId: 'invalid-award',
        queuedAt: task.updatedAt,
      ),
      throwsArgumentError,
    );
  });

  test(
    'insertOnce preserves the first configured amount and timestamp',
    () async {
      final first = _award(
        accountId: kTasksTestAccountA,
        taskId: kTasksTestTaskId,
        amount: 35,
      );
      final later = TaskCompletionAward(
        accountId: first.accountId,
        source: first.source,
        sourceId: first.sourceId,
        amount: 99,
        awardedAt: first.awardedAt.add(const Duration(hours: 1)),
      );

      final inserted = await awards.insertOnce(first);
      final duplicate = await awards.insertOnce(later);
      final saved = await awards.readAward(
        accountId: kTasksTestAccountA,
        source: kTaskDoneAwardSource,
        sourceId: kTasksTestTaskId,
      );

      expect(inserted.valueOrNull, AwardInsertOutcome.inserted);
      expect(duplicate.valueOrNull, AwardInsertOutcome.alreadyExists);
      expect(saved.valueOrNull, first);
    },
  );

  test(
    'remote first award replaces a divergent offline copy by the same key',
    () async {
      final offline = _award(
        accountId: kTasksTestAccountA,
        taskId: kTasksTestTaskId,
        amount: 35,
      );
      final authoritative = TaskCompletionAward(
        accountId: offline.accountId,
        source: offline.source,
        sourceId: offline.sourceId,
        amount: 35,
        awardedAt: offline.awardedAt.add(const Duration(minutes: 1)),
      );
      await awards.insertOnce(offline);

      expect(
        (await awards.applyRemoteAward(authoritative)).failureOrNull,
        isNull,
      );
      expect(
        (await awards.applyRemoteAward(authoritative)).failureOrNull,
        isNull,
      );
      expect(
        await awards.watchAwards(kTasksTestAccountA).first,
        <TaskCompletionAward>[authoritative],
      );
      expect(
        (await awards.readAward(
          accountId: kTasksTestAccountA,
          source: kTaskDoneAwardSource,
          sourceId: kTasksTestTaskId,
        )).valueOrNull,
        authoritative,
      );
    },
  );

  test(
    'same Task ID has an independent award in each account partition',
    () async {
      await awards.insertOnce(
        _award(accountId: kTasksTestAccountA, taskId: kTasksTestTaskId),
      );
      await awards.insertOnce(
        _award(accountId: kTasksTestAccountB, taskId: kTasksTestTaskId),
      );

      final accountA = await awards.watchAwards(kTasksTestAccountA).first;
      final accountB = await awards.watchAwards(kTasksTestAccountB).first;

      expect(accountA, hasLength(1));
      expect(accountA.single.accountId, kTasksTestAccountA);
      expect(accountB, hasLength(1));
      expect(accountB.single.accountId, kTasksTestAccountB);
    },
  );

  test('ten complete and reopen cycles retain exactly one award', () async {
    var task = _task();
    await tasks.commitTask(_taskWrite(task, 'create-op', ChangeKind.create));

    for (var cycle = 0; cycle < 10; cycle += 1) {
      final completedAt = DateTime.utc(2026, 10, 11, 9, cycle * 2);
      task = task.complete(completedAt);
      final completed = await completionUnit.commit(
        TaskCompletionCommit(
          task: task,
          firstAward: _awardFromTask(task, completedAt),
          operationId: 'complete-$cycle',
          queuedAt: completedAt,
        ),
      );
      expect(completed.failureOrNull, isNull);

      final reopenedAt = completedAt.add(const Duration(minutes: 1));
      task = task.reopen(reopenedAt);
      final reopened = await completionUnit.commit(
        TaskCompletionCommit(
          task: task,
          operationId: 'reopen-$cycle',
          queuedAt: reopenedAt,
        ),
      );
      expect(reopened.failureOrNull, isNull);
    }

    final accountAwards = await awards.watchAwards(kTasksTestAccountA).first;
    expect(accountAwards, hasLength(1));
    expect(accountAwards.single.amount, _task().completionXp);
  });

  test(
    'Task, first award, and outbox all roll back on a failed commit',
    () async {
      final open = _task();
      await tasks.commitTask(
        _taskWrite(open, 'occupied-op', ChangeKind.create),
      );
      final completedAt = DateTime.utc(2026, 10, 11, 9);
      final completed = open.complete(completedAt);

      final result = await completionUnit.commit(
        TaskCompletionCommit(
          task: completed,
          firstAward: _awardFromTask(completed, completedAt),
          operationId: 'occupied-op',
          queuedAt: completedAt,
        ),
      );

      expect(result.failureOrNull, isNotNull);
      expect(
        (await tasks.readTask(
          accountId: kTasksTestAccountA,
          taskId: kTasksTestTaskId,
        )).valueOrNull?.completedAt,
        isNull,
      );
      expect(await awards.watchAwards(kTasksTestAccountA).first, isEmpty);
      expect(
        await database.rawScalar(
          "SELECT count(*) FROM pending_changes WHERE operation_id = 'occupied-op'",
        ),
        1,
      );
    },
  );

  test('deleting a rewarded Task never removes its award', () async {
    var task = _task();
    await tasks.commitTask(_taskWrite(task, 'create-op', ChangeKind.create));
    final completedAt = DateTime.utc(2026, 10, 11, 9);
    task = task.complete(completedAt);
    await completionUnit.commit(
      TaskCompletionCommit(
        task: task,
        firstAward: _awardFromTask(task, completedAt),
        operationId: 'complete-op',
        queuedAt: completedAt,
      ),
    );
    final deletedAt = completedAt.add(const Duration(hours: 1));
    await tasks.commitTask(
      _taskWrite(task.markDeleted(deletedAt), 'delete-op', ChangeKind.delete),
    );

    expect(await tasks.watchTasks(kTasksTestAccountA).first, isEmpty);
    expect(await awards.watchAwards(kTasksTestAccountA).first, hasLength(1));
  });
}

Task _task() => Task.create(
  id: kTasksTestTaskId,
  accountId: kTasksTestAccountA,
  title: 'Rewarded task',
  scheduledDate: DateTime(2026, 10, 11),
  completionXp: 35,
  createdAt: DateTime.utc(2026, 10, 11, 8),
);

TaskCompletionAward _award({
  required String accountId,
  required String taskId,
  int amount = 20,
}) => TaskCompletionAward(
  accountId: accountId,
  source: kTaskDoneAwardSource,
  sourceId: taskId,
  amount: amount,
  awardedAt: DateTime.utc(2026, 10, 11, 9),
);

TaskCompletionAward _awardFromTask(Task task, DateTime awardedAt) =>
    TaskCompletionAward(
      accountId: task.accountId,
      source: kTaskDoneAwardSource,
      sourceId: task.id,
      amount: task.completionXp,
      awardedAt: awardedAt,
    );

TaskWriteRequest _taskWrite(Task task, String operationId, ChangeKind kind) =>
    TaskWriteRequest(
      task: task,
      operationId: operationId,
      kind: kind,
      queuedAt: task.updatedAt,
    );
