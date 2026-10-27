import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_completion_unit_of_work.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/domain/checklist_item.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import '../../../../support/tasks_test_support.dart';

void main() {
  late TasksTestClock clock;
  late TasksTestIds ids;
  late _MemoryTaskRepository repository;
  late _MemoryCompletionUnitOfWork unitOfWork;
  late _Session session;
  late TaskCompletionService service;

  setUp(() {
    clock = TasksTestClock(initialUtc: DateTime.utc(2026, 10, 11, 9));
    ids = TasksTestIds();
    repository = _MemoryTaskRepository();
    unitOfWork = _MemoryCompletionUnitOfWork(repository);
    session = _Session(kTasksTestAccountA);
    service = TaskCompletionService(
      repository: repository,
      unitOfWork: unitOfWork,
      session: session,
      nowUtc: clock.utcNow,
      currentLocalDate: () => DateTime(2026, 10, 11),
      nextOperationId: ids.nextOperationId,
    );
  });

  test(
    'complete commits Task, first award, and one stable operation',
    () async {
      const checklist = <ChecklistItem>[
        ChecklistItem(
          id: 'step-1',
          text: 'Still open',
          completed: false,
          order: 0,
        ),
      ];
      repository.seed(_task(checklistItems: checklist));

      final result = await service.completeTask(kTasksTestTaskId);

      final completed = result.valueOrNull!;
      expect(completed.completedAt, clock.utcNow());
      expect(completed.checklistItems, checklist);
      expect(completed.checklistItems.single.completed, isFalse);
      expect(unitOfWork.commits, hasLength(1));
      final commit = unitOfWork.commits.single;
      expect(commit.task, completed);
      expect(commit.operationId, 'tasks-test-operation-0001');
      expect(commit.queuedAt, clock.utcNow());
      expect(commit.firstAward?.accountId, kTasksTestAccountA);
      expect(commit.firstAward?.source, 'task_done');
      expect(commit.firstAward?.sourceId, kTasksTestTaskId);
      expect(commit.firstAward?.amount, kTaskCompletionXp);
      expect(commit.firstAward?.awardedAt, clock.utcNow());
    },
  );

  test('complete on an already completed Task is a local no-op', () async {
    final completed = _task().complete(clock.utcNow());
    repository.seed(completed);
    clock.advance(const Duration(hours: 1));

    final result = await service.completeTask(kTasksTestTaskId);

    expect(result.valueOrNull, same(completed));
    expect(unitOfWork.commits, isEmpty);
  });

  test('reopen clears completion without creating an award', () async {
    final completed = _task().complete(clock.utcNow());
    repository.seed(completed);
    clock.advance(const Duration(hours: 1));

    final result = await service.reopenTask(kTasksTestTaskId);

    final reopened = result.valueOrNull!;
    expect(reopened.completedAt, isNull);
    expect(reopened.updatedAt, clock.utcNow());
    expect(unitOfWork.commits.single.firstAward, isNull);
    expect(unitOfWork.commits.single.operationId, 'tasks-test-operation-0001');
  });

  test(
    'missing, foreign, and deleted Tasks stay hidden and unwritten',
    () async {
      final missing = await service.completeTask(kTasksTestTaskId);
      repository.seed(_task(accountId: kTasksTestAccountB));
      final foreign = await service.completeTask(kTasksTestTaskId);
      repository.seed(_task().markDeleted(DateTime.utc(2026, 10, 11, 10)));
      clock.advance(const Duration(hours: 2));
      final deleted = await service.completeTask(kTasksTestTaskId);

      expect(missing.failureOrNull?.messageKey, 'tasks.error.not_found');
      expect(foreign.failureOrNull?.messageKey, 'tasks.error.not_found');
      expect(deleted.failureOrNull?.messageKey, 'tasks.error.not_found');
      expect(unitOfWork.commits, isEmpty);
    },
  );

  test('session change before commit prevents a cross-account write', () async {
    repository.seed(_task());
    repository.afterRead = () => session.accountId = kTasksTestAccountB;

    final result = await service.completeTask(kTasksTestTaskId);

    expect(result.failureOrNull?.messageKey, 'tasks.auth.sign_in_required');
    expect(unitOfWork.commits, isEmpty);
  });

  test(
    'session change before a no-op cannot expose the old account Task',
    () async {
      repository.seed(_task().complete(clock.utcNow()));
      repository.afterRead = () => session.accountId = kTasksTestAccountB;

      final result = await service.completeTask(kTasksTestTaskId);

      expect(result.failureOrNull?.messageKey, 'tasks.auth.sign_in_required');
      expect(result.valueOrNull, isNull);
      expect(unitOfWork.commits, isEmpty);
    },
  );

  test('signed-out completion fails before reading or writing', () async {
    session.accountId = null;

    final result = await service.completeTask(kTasksTestTaskId);

    expect(result.failureOrNull?.messageKey, 'tasks.auth.sign_in_required');
    expect(repository.reads, isEmpty);
    expect(unitOfWork.commits, isEmpty);
  });

  test(
    'Today rejects a displayed day after midnight without a write',
    () async {
      repository.seed(_task());
      service = TaskCompletionService(
        repository: repository,
        unitOfWork: unitOfWork,
        session: session,
        nowUtc: clock.utcNow,
        currentLocalDate: () => DateTime(2026, 10, 12),
        nextOperationId: ids.nextOperationId,
      );

      final result = await service.completeTask(
        kTasksTestTaskId,
        expectedAccountId: kTasksTestAccountA,
        expectedLocalDate: DateTime(2026, 10, 11),
      );

      expect(result.failureOrNull?.messageKey, 'tasks.validation.stale_day');
      expect(repository.reads, isEmpty);
      expect(unitOfWork.commits, isEmpty);
    },
  );

  test('Today rejects a freshly rescheduled Task before save', () async {
    repository.seed(_task().copyWith(scheduledDate: DateTime(2026, 10, 12)));
    service = TaskCompletionService(
      repository: repository,
      unitOfWork: unitOfWork,
      session: session,
      nowUtc: clock.utcNow,
      currentLocalDate: () => DateTime(2026, 10, 11),
      nextOperationId: ids.nextOperationId,
    );

    final result = await service.completeTask(
      kTasksTestTaskId,
      expectedAccountId: kTasksTestAccountA,
      expectedLocalDate: DateTime(2026, 10, 11),
    );

    expect(result.failureOrNull?.messageKey, 'tasks.validation.stale_day');
    expect(repository.reads, hasLength(1));
    expect(unitOfWork.commits, isEmpty);
  });

  test(
    'Today rejects midnight during a delayed read and validates no-ops',
    () async {
      repository.seed(_task().complete(clock.utcNow()));
      var localDay = DateTime(2026, 10, 11);
      repository.afterRead = () => localDay = DateTime(2026, 10, 12);
      service = TaskCompletionService(
        repository: repository,
        unitOfWork: unitOfWork,
        session: session,
        nowUtc: clock.utcNow,
        currentLocalDate: () => localDay,
        nextOperationId: ids.nextOperationId,
      );

      final result = await service.completeTask(
        kTasksTestTaskId,
        expectedAccountId: kTasksTestAccountA,
        expectedLocalDate: DateTime(2026, 10, 11),
      );
      expect(result.failureOrNull?.messageKey, 'tasks.validation.stale_day');
      expect(result.valueOrNull, isNull);
      expect(unitOfWork.commits, isEmpty);
    },
  );
}

Task _task({
  String accountId = kTasksTestAccountA,
  List<ChecklistItem> checklistItems = const <ChecklistItem>[],
}) => Task.create(
  id: kTasksTestTaskId,
  accountId: accountId,
  title: 'Completion service',
  scheduledDate: DateTime(2026, 10, 11),
  checklistItems: checklistItems,
  createdAt: DateTime.utc(2026, 10, 11, 8),
);

final class _Session implements CloudSessionPort {
  _Session(this.accountId);

  String? accountId;

  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async {
    final current = accountId;
    return current == null
        ? AppResult<CloudSyncContext>.failure(
            taskCommandFailure(
              messageKey: 'tasks.auth.sign_in_required',
              occurredAt: DateTime.utc(2026, 10, 11),
            ),
          )
        : AppResult<CloudSyncContext>.success(
            CloudSyncContext(accountId: current),
          );
  }

  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();
}

final class _MemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = <String, Task>{};
  final List<(String, String)> reads = <(String, String)>[];
  void Function()? afterRead;

  void seed(Task task) => _tasks['${task.accountId}/${task.id}'] = task;

  @override
  Future<AppResult<Task?>> readTask({
    required String accountId,
    required String taskId,
  }) async {
    reads.add((accountId, taskId));
    final task = _tasks['$accountId/$taskId'];
    afterRead?.call();
    return AppResult<Task?>.success(task);
  }

  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();

  @override
  Future<AppResult<void>> applyInboundTask(Task task) async {
    seed(task);
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> commitTask(TaskWriteRequest request) async {
    seed(request.task);
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<bool>> hasPendingChange({
    required String accountId,
    required String taskId,
  }) async => AppResult<bool>.success(false);

  @override
  Stream<List<Task>> watchTasks(String accountId) => const Stream.empty();

  @override
  Stream<List<TaskConflictRecord>> watchConflicts(String accountId) =>
      const Stream.empty();
}

final class _MemoryCompletionUnitOfWork implements TaskCompletionUnitOfWork {
  _MemoryCompletionUnitOfWork(this.repository);

  final _MemoryTaskRepository repository;
  final List<TaskCompletionCommit> commits = <TaskCompletionCommit>[];

  @override
  Future<AppResult<void>> commit(TaskCompletionCommit request) async {
    commits.add(request);
    repository.seed(request.task);
    return AppResult<void>.success(null);
  }
}
