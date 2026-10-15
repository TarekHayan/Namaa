import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

import '../../../../support/tasks_test_support.dart';

void main() {
  late TasksTestClock clock;
  late TasksTestIds ids;
  late _MemoryTaskRepository repository;
  late _SignedInSession session;
  late TaskCommands commands;

  setUp(() {
    clock = TasksTestClock();
    ids = TasksTestIds();
    repository = _MemoryTaskRepository();
    session = _SignedInSession(kTasksTestAccountA);
    commands = TaskCommands(
      repository: repository,
      session: session,
      nowUtc: clock.utcNow,
      localDate: clock.localDate,
      nextTaskId: ids.nextTaskId,
      nextOperationId: ids.nextOperationId,
    );
  });

  group('account-scoped Task commands', () {
    test(
      'create applies defaults locally and queues one account change',
      () async {
        final result = await commands.createTask(
          const CreateTaskInput(title: '  Review architecture  '),
        );

        final task = result.valueOrNull!;
        expect(task.accountId, kTasksTestAccountA);
        expect(task.id, '00000000-0000-4000-8000-000000000001');
        expect(task.title, 'Review architecture');
        expect(task.scheduledDate, clock.localDate());
        expect(repository.commits, hasLength(1));
        expect(repository.commits.single.task, same(task));
        expect(repository.commits.single.task.accountId, kTasksTestAccountA);
        expect(
          repository.commits.single.operationId,
          'tasks-test-operation-0001',
        );
        expect(repository.commits.single.kind, ChangeKind.create);
      },
    );

    test('edit preserves identity and queues an update', () async {
      final original = _task(
        id: kTasksTestTaskId,
        accountId: kTasksTestAccountA,
      );
      repository.seed(original);
      clock.advance(const Duration(minutes: 5));

      final result = await commands.editTask(
        const EditTaskInput(
          taskId: kTasksTestTaskId,
          title: 'Updated task',
          description: 'Same aggregate identity',
        ),
      );

      final edited = result.valueOrNull!;
      expect(edited.id, original.id);
      expect(edited.accountId, original.accountId);
      expect(edited.title, 'Updated task');
      expect(edited.description, 'Same aggregate identity');
      expect(edited.updatedAt, clock.utcNow());
      expect(repository.commits.single.kind, ChangeKind.update);
    });

    test('move changes the same Task quadrant in one update', () async {
      repository.seed(
        _task(id: kTasksTestTaskId, accountId: kTasksTestAccountA),
      );

      final result = await commands.moveTask(
        taskId: kTasksTestTaskId,
        quadrant: EisenhowerQuadrant.notUrgentImportant,
      );

      expect(result.valueOrNull!.id, kTasksTestTaskId);
      expect(
        result.valueOrNull!.quadrant,
        EisenhowerQuadrant.notUrgentImportant,
      );
      expect(repository.commits.single.kind, ChangeKind.update);
    });

    test(
      'delete writes a versioned tombstone rather than removing identity',
      () async {
        repository.seed(
          _task(id: kTasksTestTaskId, accountId: kTasksTestAccountA),
        );
        clock.advance(const Duration(minutes: 10));

        final result = await commands.deleteTask(kTasksTestTaskId);

        expect(result.failureOrNull, isNull);
        expect(repository.commits.single.task.id, kTasksTestTaskId);
        expect(repository.commits.single.task.deletedAt, clock.utcNow());
        expect(repository.commits.single.kind, ChangeKind.delete);
      },
    );
  });

  group('validation and ownership failures', () {
    test(
      'blank title returns a localized validation key and writes nothing',
      () async {
        final result = await commands.createTask(
          const CreateTaskInput(title: '  \n '),
        );

        expect(
          result.failureOrNull?.messageKey,
          'tasks.validation.title_required',
        );
        expect(repository.commits, isEmpty);
      },
    );

    test(
      'missing Task returns a localized failure and writes nothing',
      () async {
        final result = await commands.editTask(
          const EditTaskInput(taskId: 'missing-task', title: 'No task'),
        );

        expect(result.failureOrNull?.messageKey, 'tasks.error.not_found');
        expect(repository.commits, isEmpty);
      },
    );

    test('foreign-account Task is not exposed or written', () async {
      repository.seed(
        _task(id: kTasksTestTaskId, accountId: kTasksTestAccountB),
      );

      final result = await commands.deleteTask(kTasksTestTaskId);

      expect(result.failureOrNull?.messageKey, 'tasks.error.not_found');
      expect(repository.commits, isEmpty);
    });

    test('deleted Task cannot be edited or queued again', () async {
      repository.seed(
        _task(
          id: kTasksTestTaskId,
          accountId: kTasksTestAccountA,
        ).markDeleted(clock.utcNow()),
      );

      final result = await commands.moveTask(
        taskId: kTasksTestTaskId,
        quadrant: EisenhowerQuadrant.urgentNotImportant,
      );

      expect(result.failureOrNull?.messageKey, 'tasks.error.not_found');
      expect(repository.commits, isEmpty);
    });

    test(
      'signed-out command fails before reading or writing Task data',
      () async {
        session.accountId = null;

        final result = await commands.createTask(
          const CreateTaskInput(title: 'Must not persist'),
        );

        expect(result.failureOrNull?.messageKey, 'tasks.auth.sign_in_required');
        expect(repository.reads, isEmpty);
        expect(repository.commits, isEmpty);
      },
    );

    test(
      'stale editor account cannot create under a newly active account',
      () async {
        session.accountId = kTasksTestAccountB;

        final result = await commands.createTask(
          const CreateTaskInput(title: 'Wrong owner'),
          expectedAccountId: kTasksTestAccountA,
        );

        expect(result.failureOrNull?.messageKey, 'tasks.auth.sign_in_required');
        expect(repository.commits, isEmpty);
      },
    );

    test(
      'account switch after Task read blocks the pending edit write',
      () async {
        repository.seed(
          _task(id: kTasksTestTaskId, accountId: kTasksTestAccountA),
        );
        repository.afterRead = () => session.accountId = kTasksTestAccountB;

        final result = await commands.editTask(
          const EditTaskInput(taskId: kTasksTestTaskId, title: 'Must not save'),
          expectedAccountId: kTasksTestAccountA,
        );

        expect(result.failureOrNull?.messageKey, 'tasks.auth.sign_in_required');
        expect(repository.commits, isEmpty);
      },
    );
  });
}

Task _task({required String id, required String accountId}) => Task.create(
  id: id,
  accountId: accountId,
  title: 'Original task',
  scheduledDate: DateTime(2026, 10, 8),
  createdAt: DateTime.utc(2026, 10, 8, 9),
);

final class _SignedInSession implements CloudSessionPort {
  _SignedInSession(this.accountId);

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
  @override
  Stream<List<TaskConflictRecord>> watchConflicts(String accountId) =>
      Stream<List<TaskConflictRecord>>.value(const []);
  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();
  final Map<String, Task> _tasks = <String, Task>{};
  final List<TaskWriteRequest> commits = <TaskWriteRequest>[];
  final List<(String, String)> reads = <(String, String)>[];
  void Function()? afterRead;

  void seed(Task task) => _tasks['${task.accountId}/${task.id}'] = task;

  @override
  Future<AppResult<void>> applyInboundTask(Task task) async {
    seed(task);
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> commitTask(TaskWriteRequest request) async {
    commits.add(request);
    seed(request.task);
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<bool>> hasPendingChange({
    required String accountId,
    required String taskId,
  }) async => AppResult<bool>.success(false);

  @override
  Future<AppResult<Task?>> readTask({
    required String accountId,
    required String taskId,
  }) async {
    reads.add((accountId, taskId));
    afterRead?.call();
    return AppResult<Task?>.success(_tasks['$accountId/$taskId']);
  }

  @override
  Stream<List<Task>> watchTasks(String accountId) => Stream<List<Task>>.value(
    _tasks.values.where((task) => task.accountId == accountId).toList(),
  );
}
