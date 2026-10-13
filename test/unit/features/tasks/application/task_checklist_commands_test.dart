import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/tasks_test_support.dart';

void main() {
  late TasksTestClock clock;
  late TasksTestIds ids;
  late _MemoryTaskRepository repository;
  late _MutableSession session;
  late TaskCommands commands;
  late int checklistId;

  setUp(() {
    clock = TasksTestClock();
    ids = TasksTestIds();
    checklistId = 0;
    repository = _MemoryTaskRepository();
    session = _MutableSession(kTasksTestAccountA);
    commands = TaskCommands(
      repository: repository,
      session: session,
      nowUtc: clock.utcNow,
      localDate: clock.localDate,
      nextTaskId: ids.nextTaskId,
      nextOperationId: ids.nextOperationId,
      nextChecklistItemId: () => 'check-${++checklistId}',
    );
    repository.seed(_task());
  });

  test(
    'add/edit/check/uncheck/remove each queue one parent Task update',
    () async {
      final added = await commands.addChecklistItem(
        taskId: kTasksTestTaskId,
        text: '  First step  ',
      );
      expect(added.valueOrNull!.checklistItems.single.id, 'check-1');
      expect(added.valueOrNull!.checklistItems.single.text, 'First step');
      expect(repository.commits, hasLength(1));
      expect(repository.commits.single.kind, ChangeKind.update);
      expect(repository.commits.single.task.id, kTasksTestTaskId);

      clock.advance(const Duration(minutes: 1));
      final edited = await commands.editChecklistItem(
        taskId: kTasksTestTaskId,
        itemId: 'check-1',
        text: 'Edited step',
      );
      expect(edited.valueOrNull!.checklistItems.single.text, 'Edited step');
      expect(repository.commits, hasLength(2));

      clock.advance(const Duration(minutes: 1));
      final checked = await commands.setChecklistItemCompleted(
        taskId: kTasksTestTaskId,
        itemId: 'check-1',
        completed: true,
      );
      expect(checked.valueOrNull!.checklistItems.single.completed, isTrue);
      expect(checked.valueOrNull!.isCompleted, isFalse);
      expect(repository.commits, hasLength(3));

      clock.advance(const Duration(minutes: 1));
      final unchecked = await commands.setChecklistItemCompleted(
        taskId: kTasksTestTaskId,
        itemId: 'check-1',
        completed: false,
      );
      expect(unchecked.valueOrNull!.checklistItems.single.completed, isFalse);
      expect(repository.commits, hasLength(4));

      clock.advance(const Duration(minutes: 1));
      final removed = await commands.removeChecklistItem(
        taskId: kTasksTestTaskId,
        itemId: 'check-1',
      );
      expect(removed.valueOrNull!.checklistItems, isEmpty);
      expect(repository.commits, hasLength(5));
      expect(
        repository.commits.map((write) => write.operationId).toSet(),
        hasLength(5),
      );
    },
  );

  test('blank text and missing items fail without an outbox write', () async {
    final blank = await commands.addChecklistItem(
      taskId: kTasksTestTaskId,
      text: ' \n ',
    );
    expect(
      blank.failureOrNull?.messageKey,
      'tasks.validation.checklist_text_required',
    );
    expect(repository.commits, isEmpty);

    final missing = await commands.removeChecklistItem(
      taskId: kTasksTestTaskId,
      itemId: 'missing-step',
    );
    expect(
      missing.failureOrNull?.messageKey,
      'tasks.error.checklist_not_found',
    );
    expect(repository.commits, isEmpty);
  });

  test('active account cannot mutate another account Task checklist', () async {
    repository.clear();
    repository.seed(_task(accountId: kTasksTestAccountB));

    final result = await commands.addChecklistItem(
      taskId: kTasksTestTaskId,
      text: 'Must stay isolated',
    );

    expect(result.failureOrNull?.messageKey, 'tasks.error.not_found');
    expect(repository.commits, isEmpty);
    expect(
      (await repository.readTask(
        accountId: kTasksTestAccountB,
        taskId: kTasksTestTaskId,
      )).valueOrNull!.checklistItems,
      isEmpty,
    );
  });

  test('account change after read prevents checklist persistence', () async {
    repository.afterRead = () => session.accountId = kTasksTestAccountB;

    final result = await commands.addChecklistItem(
      taskId: kTasksTestTaskId,
      text: 'Must not save',
      expectedAccountId: kTasksTestAccountA,
    );

    expect(result.failureOrNull?.messageKey, 'tasks.auth.sign_in_required');
    expect(repository.commits, isEmpty);
  });

  test('checklist round-trips through encrypted Drift after restart', () async {
    final temp = TemporaryDatabasePath();
    addTearDown(temp.dispose);
    final path = temp.allocate();
    final key = List<int>.generate(32, (index) => 0x35 + index);
    const codec = TaskPayloadCodec();
    var database = await FoundationDatabase.openEncrypted(path: path, key: key);
    var driftRepository = DriftTaskRepository(database: database, codec: codec);
    await driftRepository.commitTask(
      TaskWriteRequest(
        task: _task(),
        operationId: 'seed-operation',
        kind: ChangeKind.create,
        queuedAt: clock.utcNow(),
      ),
    );
    final driftCommands = TaskCommands(
      repository: driftRepository,
      session: session,
      nowUtc: () => clock.utcNow().add(const Duration(minutes: 1)),
      localDate: clock.localDate,
      nextTaskId: ids.nextTaskId,
      nextOperationId: ids.nextOperationId,
      nextChecklistItemId: () => 'persisted-step',
    );

    final result = await driftCommands.addChecklistItem(
      taskId: kTasksTestTaskId,
      text: 'Survive restart',
    );
    expect(result.failureOrNull, isNull);
    await database.close();

    database = await FoundationDatabase.openEncrypted(path: path, key: key);
    addTearDown(database.close);
    driftRepository = DriftTaskRepository(database: database, codec: codec);
    final restored = (await driftRepository.readTask(
      accountId: kTasksTestAccountA,
      taskId: kTasksTestTaskId,
    )).valueOrNull!;

    expect(restored.checklistItems.single.id, 'persisted-step');
    expect(restored.checklistItems.single.text, 'Survive restart');
  });

  test(
    'simultaneous checklist adds retain both steps in encrypted Drift',
    () async {
      final temp = TemporaryDatabasePath();
      addTearDown(temp.dispose);
      final database = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (index) => 0x45 + index),
      );
      addTearDown(database.close);
      final driftRepository = DriftTaskRepository(
        database: database,
        codec: const TaskPayloadCodec(),
      );
      expect(
        (await driftRepository.commitTask(
          TaskWriteRequest(
            task: _task(),
            operationId: 'seed-operation',
            kind: ChangeKind.create,
            queuedAt: clock.utcNow(),
          ),
        )).failureOrNull,
        isNull,
      );
      final concurrentCommands = TaskCommands(
        repository: driftRepository,
        session: session,
        nowUtc: clock.utcNow,
        localDate: clock.localDate,
        nextTaskId: ids.nextTaskId,
        nextOperationId: ids.nextOperationId,
        nextChecklistItemId: () => 'check-${++checklistId}',
      );

      final results = await Future.wait(<Future<AppResult<Task>>>[
        concurrentCommands.addChecklistItem(
          taskId: kTasksTestTaskId,
          text: 'First',
        ),
        concurrentCommands.addChecklistItem(
          taskId: kTasksTestTaskId,
          text: 'Second',
        ),
      ]);
      expect(results.every((result) => result.failureOrNull == null), isTrue);
      final saved = (await driftRepository.readTask(
        accountId: kTasksTestAccountA,
        taskId: kTasksTestTaskId,
      )).valueOrNull!;
      expect(saved.checklistItems.map((item) => item.text).toSet(), <String>{
        'First',
        'Second',
      });
    },
  );

  test(
    'parent deletion keeps one Task tombstone with owned checklist payload',
    () async {
      await commands.addChecklistItem(
        taskId: kTasksTestTaskId,
        text: 'Owned step',
      );
      clock.advance(const Duration(minutes: 1));

      final deleted = await commands.deleteTask(kTasksTestTaskId);

      expect(deleted.failureOrNull, isNull);
      expect(repository.commits, hasLength(2));
      final tombstone = repository.commits.last.task;
      expect(tombstone.isDeleted, isTrue);
      expect(tombstone.checklistItems.single.text, 'Owned step');
      expect(repository.commits.last.kind, ChangeKind.delete);
    },
  );
}

Task _task({String accountId = kTasksTestAccountA}) => Task.create(
  id: kTasksTestTaskId,
  accountId: accountId,
  title: 'Parent task',
  scheduledDate: DateTime(2026, 10, 8),
  createdAt: DateTime.utc(2026, 10, 8, 9),
);

final class _MutableSession implements CloudSessionPort {
  _MutableSession(this.accountId);

  String? accountId;

  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async {
    final current = accountId;
    if (current == null) {
      return AppResult<CloudSyncContext>.failure(
        taskCommandFailure(
          messageKey: 'tasks.auth.sign_in_required',
          occurredAt: DateTime.utc(2026, 10, 8),
        ),
      );
    }
    return AppResult<CloudSyncContext>.success(
      CloudSyncContext(accountId: current),
    );
  }

  @override
  Stream<CloudSessionSnapshot> observeSession() =>
      Stream<CloudSessionSnapshot>.value(
        CloudSessionSnapshot(
          status: accountId == null
              ? CloudSessionStatus.signedOut
              : CloudSessionStatus.signedIn,
          accountId: accountId,
        ),
      );
}

final class _MemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = <String, Task>{};
  final List<TaskWriteRequest> commits = <TaskWriteRequest>[];
  void Function()? afterRead;

  void seed(Task task) => _tasks['${task.accountId}/${task.id}'] = task;

  void clear() => _tasks.clear();

  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();

  @override
  Future<AppResult<Task?>> readTask({
    required String accountId,
    required String taskId,
  }) async {
    final task = _tasks['$accountId/$taskId'];
    afterRead?.call();
    return AppResult<Task?>.success(task);
  }

  @override
  Future<AppResult<void>> commitTask(TaskWriteRequest request) async {
    commits.add(request);
    seed(request.task);
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> applyInboundTask(Task task) async {
    seed(task);
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<bool>> hasPendingChange({
    required String accountId,
    required String taskId,
  }) async => AppResult<bool>.success(false);

  @override
  Stream<List<Task>> watchTasks(String accountId) => Stream<List<Task>>.value(
    _tasks.values.where((task) => task.accountId == accountId).toList(),
  );

  @override
  Stream<List<TaskConflictRecord>> watchConflicts(String accountId) =>
      Stream<List<TaskConflictRecord>>.value(const <TaskConflictRecord>[]);
}
