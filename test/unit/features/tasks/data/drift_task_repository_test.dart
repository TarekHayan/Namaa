import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/data/task_reconciler.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/tasks_test_support.dart';

void main() {
  final encryptionKey = List<int>.generate(32, (index) => 0x70 + index);
  const codec = TaskPayloadCodec();
  late TemporaryDatabasePath temporaryPath;
  late String databasePath;
  late FoundationDatabase database;
  late DriftTaskRepository repository;

  setUp(() async {
    temporaryPath = TemporaryDatabasePath();
    databasePath = temporaryPath.allocate();
    database = await FoundationDatabase.openEncrypted(
      path: databasePath,
      key: encryptionKey,
    );
    repository = DriftTaskRepository(database: database, codec: codec);
  });

  tearDown(() async {
    await database.close();
    temporaryPath.dispose();
  });

  test('commits encrypted Task and PendingChange in one transaction', () async {
    const sentinel = 'private-task-sentinel-3a';
    final task = _task(title: sentinel);
    final write = _write(task: task, operationId: kTasksTestOperationId);

    final result = await repository.commitTask(write);

    expect(result.failureOrNull, isNull);
    expect(
      (await repository.readTask(
        accountId: kTasksTestAccountA,
        taskId: kTasksTestTaskId,
      )).valueOrNull?.title,
      sentinel,
    );
    expect(
      await database.rawScalar(
        'SELECT operation_id FROM pending_changes WHERE operation_id = '
        "'$kTasksTestOperationId'",
      ),
      kTasksTestOperationId,
    );
    expect(
      await database.rawScalar('SELECT count(*) FROM local_records'),
      0,
      reason: 'Task aggregates must not be hidden in Foundation LocalRecords',
    );

    await database.close();
    final raw = latin1.decode(
      await File(databasePath).readAsBytes(),
      allowInvalid: true,
    );
    expect(raw, isNot(contains(sentinel)));
    database = await FoundationDatabase.openEncrypted(
      path: databasePath,
      key: encryptionKey,
    );
    repository = DriftTaskRepository(database: database, codec: codec);
  });

  test('preserves stable operation ID on an idempotent local retry', () async {
    final task = _task();
    final write = _write(task: task, operationId: kTasksTestOperationId);

    expect((await repository.commitTask(write)).failureOrNull, isNull);
    expect((await repository.commitTask(write)).failureOrNull, isNull);

    expect(
      await database.rawScalar(
        'SELECT count(*) FROM pending_changes WHERE operation_id = '
        "'$kTasksTestOperationId'",
      ),
      1,
    );
  });

  test(
    'detects pending changes when a Task has multiple queued edits',
    () async {
      final first = _task();
      final second = first.copyWith(
        title: 'Edited once',
        updatedAt: first.updatedAt.add(const Duration(minutes: 1)),
      );
      final third = second.copyWith(
        title: 'Edited twice',
        updatedAt: second.updatedAt.add(const Duration(minutes: 1)),
      );
      await repository.commitTask(_write(task: first, operationId: 'op-first'));
      await repository.commitTask(
        _write(task: second, operationId: 'op-second', kind: ChangeKind.update),
      );
      await repository.commitTask(
        _write(task: third, operationId: 'op-third', kind: ChangeKind.update),
      );

      final pending = await repository.hasPendingChange(
        accountId: kTasksTestAccountA,
        taskId: kTasksTestTaskId,
      );

      expect(pending.failureOrNull, isNull);
      expect(pending.valueOrNull, isTrue);
    },
  );

  test('reads and watches only the requested account partition', () async {
    final accountATask = _task();
    final accountBTask = _task(accountId: kTasksTestAccountB, title: 'B task');
    await repository.commitTask(
      _write(task: accountATask, operationId: 'op-a'),
    );
    await repository.commitTask(
      _write(task: accountBTask, operationId: 'op-b'),
    );

    final visibleToA = await repository.watchTasks(kTasksTestAccountA).first;

    expect(visibleToA.map((task) => task.title), <String>['A task']);
    expect(
      (await repository.readTask(
        accountId: kTasksTestAccountA,
        taskId: kTasksTestTaskId,
      )).valueOrNull?.accountId,
      kTasksTestAccountA,
    );
    expect(
      (await repository.readTask(
        accountId: kTasksTestAccountB,
        taskId: kTasksTestTaskId,
      )).valueOrNull?.title,
      'B task',
    );
  });

  test('survives close and encrypted restart with the same identity', () async {
    final task = _task();
    await repository.commitTask(_write(task: task, operationId: 'restart-op'));
    await database.close();

    database = await FoundationDatabase.openEncrypted(
      path: databasePath,
      key: encryptionKey,
    );
    repository = DriftTaskRepository(database: database, codec: codec);

    final restored = (await repository.readTask(
      accountId: kTasksTestAccountA,
      taskId: kTasksTestTaskId,
    )).valueOrNull;
    expect(restored?.id, task.id);
    expect(restored?.title, task.title);
  });

  test('rolls Task back when its PendingChange cannot be inserted', () async {
    final first = _task();
    await repository.commitTask(
      _write(task: first, operationId: 'collision-op'),
    );
    final second = _task(id: 'task-2', title: 'Must roll back');

    final failed = await repository.commitTask(
      _write(task: second, operationId: 'collision-op'),
    );

    expect(failed.failureOrNull, isNotNull);
    expect(
      (await repository.readTask(
        accountId: kTasksTestAccountA,
        taskId: 'task-2',
      )).valueOrNull,
      isNull,
    );
  });

  test('persists deletion as a versioned tombstone across restart', () async {
    final active = _task();
    await repository.commitTask(_write(task: active, operationId: 'create-op'));
    final tombstone = active.markDeleted(
      active.updatedAt.add(const Duration(minutes: 1)),
    );
    await repository.commitTask(
      _write(
        task: tombstone,
        operationId: 'delete-op',
        kind: ChangeKind.delete,
      ),
    );

    expect(await repository.watchTasks(kTasksTestAccountA).first, isEmpty);
    expect(
      (await repository.readTask(
        accountId: kTasksTestAccountA,
        taskId: kTasksTestTaskId,
      )).valueOrNull?.deletedAt,
      tombstone.deletedAt,
    );
  });

  test(
    'inbound conflict is visible and repeated merge does not duplicate it',
    () async {
      final local = _task(title: 'Local draft');
      final remote = local.copyWith(
        title: 'Remote draft',
        updatedAt: local.updatedAt.add(const Duration(minutes: 1)),
      );
      await repository.commitTask(_write(task: local, operationId: 'local-op'));
      final reconciler = TaskReconciler(
        repository: repository,
        localStore: DriftLocalStore(database),
        codec: codec,
        detectedAt: () => DateTime.utc(2026, 10, 8, 11),
      );

      final first = await reconciler.reconcile(
        accountId: kTasksTestAccountA,
        remoteTasks: <Task>[remote],
      );
      final second = await reconciler.reconcile(
        accountId: kTasksTestAccountA,
        remoteTasks: <Task>[remote],
      );

      expect(first.failureOrNull, isNull);
      expect(second.failureOrNull, isNull);
      expect(
        await database.rawScalar('SELECT count(*) FROM conflict_records'),
        1,
      );
      final conflicts = await repository
          .watchConflicts(kTasksTestAccountA)
          .first;
      expect(conflicts, hasLength(1));
      expect(conflicts.single.activeTitle, 'Remote draft');
      expect(conflicts.single.retainedTitle, 'Local draft');
    },
  );

  test(
    'failed reconciliation transaction rolls back the inbound Task',
    () async {
      final task = _task(title: 'Must roll back');
      final result = await repository.runInTransaction<void>(() async {
        final applied = await repository.applyInboundTask(task);
        expect(applied.failureOrNull, isNull);
        return AppResult<void>.failure(
          AppFailure.recoverable(
            category: AppFailureCategory.persistence,
            messageKey: 'test.rollback',
            occurredAt: DateTime.utc(2026, 10, 8),
          ),
        );
      });

      expect(result.failureOrNull, isNotNull);
      expect(
        (await repository.readTask(
          accountId: kTasksTestAccountA,
          taskId: task.id,
        )).valueOrNull,
        isNull,
      );
    },
  );
}

Task _task({
  String id = kTasksTestTaskId,
  String accountId = kTasksTestAccountA,
  String title = 'A task',
}) => Task.create(
  id: id,
  accountId: accountId,
  title: title,
  scheduledDate: DateTime(2026, 10, 8),
  createdAt: DateTime.utc(2026, 10, 8, 9),
);

TaskWriteRequest _write({
  required Task task,
  required String operationId,
  ChangeKind kind = ChangeKind.create,
}) => TaskWriteRequest(
  task: task,
  operationId: operationId,
  kind: kind,
  queuedAt: task.updatedAt,
);
