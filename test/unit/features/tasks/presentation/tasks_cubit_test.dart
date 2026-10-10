import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/tasks/presentation/tasks_cubit.dart';
import 'package:namma_project/features/tasks/presentation/tasks_state.dart';

import '../../../../support/tasks_test_support.dart';

void main() {
  late TasksTestClock clock;
  late _WatchTaskRepository repository;
  late TasksCubit cubit;

  setUp(() {
    clock = TasksTestClock();
    repository = _WatchTaskRepository();
    final ids = TasksTestIds();
    final commands = TaskCommands(
      repository: repository,
      session: const _Session(kTasksTestAccountA),
      nowUtc: clock.utcNow,
      localDate: clock.localDate,
      nextTaskId: ids.nextTaskId,
      nextOperationId: ids.nextOperationId,
    );
    cubit = TasksCubit(
      repository: repository,
      commands: commands,
      localDate: clock.localDate,
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.close();
  });

  test(
    'repository observation is the single source for local updates',
    () async {
      await cubit.load(kTasksTestAccountA);
      final first = _task(id: 'task-1', title: 'First');
      repository.replace(<Task>[first]);
      await _nextEvent();

      expect((cubit.state as TasksReady).allTasks, <Task>[first]);

      final second = _task(id: 'task-2', title: 'Second');
      repository.replace(<Task>[first, second]);
      await _nextEvent();

      final state = cubit.state as TasksReady;
      expect(state.allTasks.map((task) => task.id), <String>[
        'task-1',
        'task-2',
      ]);
      expect(state.visibleTasks.map((task) => task.id).toSet(), hasLength(2));
    },
  );

  test(
    'Cubit create command becomes visible through repository observation',
    () async {
      await cubit.load(kTasksTestAccountA);

      await cubit.createTask(const CreateTaskInput(title: 'Created offline'));
      await _nextEvent();

      final state = cubit.state as TasksReady;
      expect(state.visibleTasks.single.title, 'Created offline');
      expect(repository.lastPending?.kind, ChangeKind.create);
    },
  );

  test(
    'Today, Urgent, All and Completed are pure projections of one list',
    () async {
      final today = clock.localDate();
      final tasks = <Task>[
        _task(id: 'today', title: 'Today', scheduledDate: today),
        _task(
          id: 'urgent',
          title: 'Urgent future',
          scheduledDate: today.add(const Duration(days: 1)),
          quadrant: EisenhowerQuadrant.urgentNotImportant,
        ),
        _task(
          id: 'completed',
          title: 'Completed',
          scheduledDate: today,
          completedAt: clock.utcNow(),
        ),
      ];
      await cubit.load(kTasksTestAccountA);
      repository.replace(tasks);
      await _nextEvent();

      cubit.selectFilter(TaskListFilter.today);
      expect(_visibleIds(cubit), <String>{'today'});

      cubit.selectFilter(TaskListFilter.urgent);
      expect(_visibleIds(cubit), <String>{'today', 'urgent'});

      cubit.selectFilter(TaskListFilter.all);
      expect(_visibleIds(cubit), <String>{'today', 'urgent', 'completed'});

      cubit.selectFilter(TaskListFilter.completed);
      expect(_visibleIds(cubit), <String>{'completed'});
    },
  );

  test('category filter narrows the same canonical identities', () async {
    await cubit.load(kTasksTestAccountA);
    repository.replace(<Task>[
      _task(id: 'work', title: 'Work'),
      _task(id: 'study', title: 'Study', category: TaskCategory.study),
    ]);
    await _nextEvent();

    cubit
      ..selectFilter(TaskListFilter.all)
      ..selectCategory(TaskCategory.study);

    expect(_visibleIds(cubit), <String>{'study'});
    expect((cubit.state as TasksReady).allTasks, hasLength(2));
  });

  test(
    'repository read error exposes retry and a later load can recover',
    () async {
      repository.failNextWatch = true;

      await cubit.load(kTasksTestAccountA);
      await _nextEvent();
      expect(cubit.state, isA<TasksFailure>());

      await cubit.load(kTasksTestAccountA);
      repository.replace(<Task>[_task(id: 'recovered', title: 'Recovered')]);
      await _nextEvent();
      expect(_visibleIds(cubit), <String>{'recovered'});
    },
  );

  test('stored conflict stream updates the ready projection', () async {
    await cubit.load(kTasksTestAccountA);
    repository.replace(<Task>[_task(id: 'task-1', title: 'Active')]);
    await _nextEvent();

    repository.replaceConflicts(const <TaskConflictRecord>[
      TaskConflictRecord(
        id: 'conflict-1',
        taskId: 'task-1',
        activeTitle: 'Active',
        retainedTitle: 'Older',
      ),
    ]);
    await _nextEvent();

    expect((cubit.state as TasksReady).conflicts.single.retainedTitle, 'Older');
  });

  test('matrix groups open Tasks once under their current quadrant', () async {
    await cubit.load(kTasksTestAccountA);
    repository.replace(<Task>[
      _task(id: 'one', title: 'One'),
      _task(
        id: 'two',
        title: 'Two',
        quadrant: EisenhowerQuadrant.notUrgentImportant,
      ),
      _task(id: 'done', title: 'Done', completedAt: clock.utcNow()),
    ]);
    await _nextEvent();

    cubit.showMatrix();

    final state = cubit.state as TasksReady;
    final matrixIds = state.matrix.values
        .expand((tasks) => tasks)
        .map((task) => task.id);
    expect(state.viewMode, TasksViewMode.matrix);
    expect(matrixIds.toSet(), <String>{'one', 'two'});
    expect(matrixIds.length, matrixIds.toSet().length);
  });

  test('sync failure and visible conflict do not replace local Tasks', () {
    final task = _task(id: 'local', title: 'Local remains available');
    final ready = TasksReady(
      allTasks: <Task>[task],
      visibleTasks: <Task>[task],
      matrix: <EisenhowerQuadrant, List<Task>>{
        task.quadrant: <Task>[task],
      },
      filter: TaskListFilter.all,
      viewMode: TasksViewMode.list,
    );

    final degraded = ready.copyWith(
      syncStatus: TasksSyncStatus.recoverableFailure,
      conflicts: const <TaskConflictView>[
        TaskConflictView(
          conflictId: 'conflict-1',
          taskId: 'local',
          activeTitle: 'Local remains available',
          retainedTitle: 'Remote candidate',
        ),
      ],
    );

    expect(degraded.visibleTasks, <Task>[task]);
    expect(degraded.syncStatus, TasksSyncStatus.recoverableFailure);
    expect(degraded.conflicts.single.taskId, 'local');
  });
}

Set<String> _visibleIds(TasksCubit cubit) =>
    (cubit.state as TasksReady).visibleTasks.map((task) => task.id).toSet();

Future<void> _nextEvent() => Future<void>.delayed(Duration.zero);

Task _task({
  required String id,
  required String title,
  DateTime? scheduledDate,
  TaskCategory category = TaskCategory.work,
  EisenhowerQuadrant quadrant = EisenhowerQuadrant.urgentImportant,
  DateTime? completedAt,
}) => Task.create(
  id: id,
  accountId: kTasksTestAccountA,
  title: title,
  scheduledDate: scheduledDate ?? DateTime(2026, 10, 8),
  category: category,
  quadrant: quadrant,
  completedAt: completedAt,
  createdAt: DateTime.utc(2026, 10, 8, 9),
);

final class _Session implements CloudSessionPort {
  const _Session(this.accountId);

  final String accountId;

  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.success(
        CloudSyncContext(accountId: accountId),
      );

  @override
  Stream<CloudSessionSnapshot> observeSession() =>
      Stream<CloudSessionSnapshot>.value(
        CloudSessionSnapshot(
          status: CloudSessionStatus.signedIn,
          accountId: accountId,
        ),
      );
}

final class _WatchTaskRepository implements TaskRepository {
  @override
  Stream<List<TaskConflictRecord>> watchConflicts(String accountId) =>
      _conflictController.stream;
  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();
  final StreamController<List<Task>> _controller =
      StreamController<List<Task>>.broadcast(sync: true);
  final StreamController<List<TaskConflictRecord>> _conflictController =
      StreamController<List<TaskConflictRecord>>.broadcast(sync: true);
  final Map<String, Task> _tasks = <String, Task>{};
  TaskWriteRequest? lastPending;
  bool failNextWatch = false;

  void replaceConflicts(List<TaskConflictRecord> conflicts) =>
      _conflictController.add(conflicts);

  void replace(List<Task> tasks) {
    _tasks
      ..clear()
      ..addEntries(
        tasks.map((task) => MapEntry('${task.accountId}/${task.id}', task)),
      );
    _controller.add(List<Task>.unmodifiable(tasks));
  }

  Future<void> close() async {
    await _controller.close();
    await _conflictController.close();
  }

  @override
  Future<AppResult<void>> applyInboundTask(Task task) async {
    _tasks['${task.accountId}/${task.id}'] = task;
    replace(_tasks.values.toList());
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> commitTask(TaskWriteRequest request) async {
    final task = request.task;
    lastPending = request;
    _tasks['${task.accountId}/${task.id}'] = task;
    _controller.add(
      _tasks.values.where((item) => item.accountId == task.accountId).toList(),
    );
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
  }) async => AppResult<Task?>.success(_tasks['$accountId/$taskId']);

  @override
  Stream<List<Task>> watchTasks(String accountId) {
    if (failNextWatch) {
      failNextWatch = false;
      return Stream<List<Task>>.error(StateError('read failed'));
    }
    return _controller.stream;
  }
}
