import 'dart:async';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/application/task_sync_service.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

import '../application/map_task_link_port.dart';

final class TasksMapLinkAdapter implements MapTaskLinkPort {
  const TasksMapLinkAdapter({
    required TaskRepository repository,
    required TaskCompletionService completionService,
    required CloudSessionPort session,
    TaskSyncService? syncService,
  }) : _repository = repository,
       _completionService = completionService,
       _session = session,
       _syncService = syncService;

  final TaskRepository _repository;
  final TaskCompletionService _completionService;
  final CloudSessionPort _session;
  final TaskSyncService? _syncService;

  Future<bool> _current(String owner) async =>
      (await _session.obtainSyncContext()).valueOrNull?.accountId == owner;

  AppFailure _accountFailure() => AppFailure.recoverable(
    category: AppFailureCategory.authorization,
    messageKey: 'mind_maps.error.account',
    occurredAt: DateTime.now().toUtc(),
  );

  @override
  Future<AppResult<void>> ensurePickerReady(String expectedOwner) async {
    if (!await _current(expectedOwner)) {
      return AppResult.failure(_accountFailure());
    }
    final sync = _syncService;
    if (sync != null && !sync.isReadyForAccount(expectedOwner)) {
      final result = await sync.synchronizeOnTasksEntry();
      if (result.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
    }
    if (!await _current(expectedOwner)) {
      return AppResult.failure(_accountFailure());
    }
    return AppResult.success(null);
  }

  @override
  Stream<List<MapLinkedTask>> watchAccessibleTasks(String expectedOwner) {
    late StreamController<List<MapLinkedTask>> controller;
    StreamSubscription<List<Task>>? tasksSubscription;
    StreamSubscription<CloudSessionSnapshot>? sessionSubscription;
    var active = true;
    // Each Task list waits on a session check before it is published. A newer
    // list can finish that check first, so only the newest list may publish.
    var latestEmission = 0;
    controller = StreamController<List<MapLinkedTask>>(
      onListen: () async {
        if (!await _current(expectedOwner) || !active) {
          controller.add(const []);
          return;
        }
        sessionSubscription = _session.observeSession().listen((snapshot) {
          if (snapshot.accountId != expectedOwner ||
              snapshot.status != CloudSessionStatus.signedIn) {
            controller.add(const []);
            unawaited(tasksSubscription?.cancel());
            tasksSubscription = null;
          }
        });
        tasksSubscription = _repository.watchTasks(expectedOwner).listen((
          tasks,
        ) async {
          final emission = ++latestEmission;
          if (!active) return;
          final current = await _current(expectedOwner);
          if (!active || emission != latestEmission) return;
          if (!current) {
            controller.add(const []);
            return;
          }
          controller.add(
            List.unmodifiable(
              tasks
                  .where(
                    (task) =>
                        task.accountId == expectedOwner && !task.isDeleted,
                  )
                  .map(_project),
            ),
          );
        }, onError: controller.addError);
      },
      onCancel: () async {
        active = false;
        await tasksSubscription?.cancel();
        await sessionSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<AppResult<MapLinkedTask>> readLinkedTask(
    String expectedOwner,
    String taskId,
  ) async {
    if (!await _current(expectedOwner)) {
      return AppResult.failure(_accountFailure());
    }
    final result = await _repository.readTask(
      accountId: expectedOwner,
      taskId: taskId,
    );
    if (result.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    if (!await _current(expectedOwner)) {
      return AppResult.failure(_accountFailure());
    }
    final task = result.valueOrNull;
    return AppResult.success(
      task == null || task.accountId != expectedOwner || task.isDeleted
          ? MapLinkedTask.unavailable(taskId)
          : _project(task),
    );
  }

  @override
  Future<AppResult<void>> complete(String expectedOwner, String taskId) =>
      _change(expectedOwner, taskId, true);

  @override
  Future<AppResult<void>> reopen(String expectedOwner, String taskId) =>
      _change(expectedOwner, taskId, false);

  Future<AppResult<void>> _change(
    String owner,
    String taskId,
    bool complete,
  ) async {
    if (!await _current(owner)) return AppResult.failure(_accountFailure());
    final result = complete
        ? await _completionService.completeTask(
            taskId,
            expectedAccountId: owner,
          )
        : await _completionService.reopenTask(taskId, expectedAccountId: owner);
    if (result.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    if (!await _current(owner)) return AppResult.failure(_accountFailure());
    if (_syncService != null) unawaited(_syncService.synchronize());
    return AppResult.success(null);
  }

  static MapLinkedTask _project(Task task) => MapLinkedTask.available(
    id: task.id,
    title: task.title,
    completed: task.isCompleted,
    completionChangedAt: task.completionChangedAt,
  );
}
