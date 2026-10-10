import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/application/task_sync_service.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/tasks/domain/task_rules.dart';
import 'package:namma_project/features/tasks/presentation/tasks_state.dart';

/// Presentation controller over the single repository-owned Task stream.
final class TasksCubit extends Cubit<TasksState> {
  TasksCubit({
    required TaskRepository repository,
    required TaskCommands commands,
    required DateTime Function() localDate,
    TaskSyncService? syncService,
  }) : _repository = repository,
       _commands = commands,
       _localDate = localDate,
       _syncService = syncService,
       super(const TasksInitial()) {
    _syncSubscription = syncService?.snapshots.listen(_onSyncSnapshot);
  }

  final TaskRepository _repository;
  final TaskCommands _commands;
  final DateTime Function() _localDate;
  final TaskSyncService? _syncService;

  StreamSubscription<List<Task>>? _tasksSubscription;
  StreamSubscription<List<TaskConflictRecord>>? _conflictsSubscription;
  StreamSubscription<TaskSyncSnapshot>? _syncSubscription;
  Timer? _dayChangeTimer;
  List<TaskConflictView> _latestConflicts = const [];
  String? _accountId;

  Future<void> load(String accountId) async {
    if (_accountId == accountId &&
        _tasksSubscription != null &&
        state is! TasksFailure) {
      if (_dayChangeTimer == null) _scheduleDayChange();
      return;
    }
    _accountId = accountId;
    await _tasksSubscription?.cancel();
    await _conflictsSubscription?.cancel();
    _dayChangeTimer?.cancel();
    _latestConflicts = const [];
    emit(const TasksLoading());
    _conflictsSubscription = _repository
        .watchConflicts(accountId)
        .listen(
          _onConflicts,
          onError: (Object error, StackTrace stackTrace) {
            final current = state;
            if (current is TasksReady) {
              emit(
                current.copyWith(
                  syncStatus: TasksSyncStatus.recoverableFailure,
                ),
              );
            }
          },
        );
    _tasksSubscription = _repository
        .watchTasks(accountId)
        .listen(
          _onTasks,
          onError: (Object error, StackTrace stackTrace) {
            final current = state;
            if (current is TasksReady) {
              emit(
                current.copyWith(
                  syncStatus: TasksSyncStatus.recoverableFailure,
                ),
              );
            } else {
              emit(
                TasksFailure(
                  error is AppFailure
                      ? error
                      : AppFailure.recoverable(
                          category: AppFailureCategory.persistence,
                          messageKey: 'foundation.database.unreadable',
                          occurredAt: DateTime.now().toUtc(),
                        ),
                ),
              );
            }
          },
        );
    _scheduleDayChange();
    await _syncService?.synchronizeOnTasksEntry();
  }

  Future<AppResult<Task>> createTask(CreateTaskInput input) =>
      _saveAndSync(_commands.createTask(input, expectedAccountId: _accountId));

  Future<AppResult<Task>> editTask(EditTaskInput input) =>
      _saveAndSync(_commands.editTask(input, expectedAccountId: _accountId));

  Future<AppResult<Task>> moveTask({
    required String taskId,
    required EisenhowerQuadrant quadrant,
  }) => _saveAndSync(
    _commands.moveTask(
      taskId: taskId,
      quadrant: quadrant,
      expectedAccountId: _accountId,
    ),
  );

  Future<AppResult<void>> deleteTask(String taskId) =>
      _saveAndSync(_commands.deleteTask(taskId, expectedAccountId: _accountId));

  Future<AppResult<T>> _saveAndSync<T>(Future<AppResult<T>> write) async {
    final result = await write;
    final service = _syncService;
    if (result.failureOrNull == null && service != null) {
      unawaited(service.synchronize());
    }
    return result;
  }

  void resume() {
    if (_accountId != null && _dayChangeTimer == null) {
      _scheduleDayChange();
    }
    final current = state;
    if (current is TasksReady) {
      _emitProjection(current);
    }
    final service = _syncService;
    if (service != null) {
      unawaited(service.synchronize());
    }
  }

  void _scheduleDayChange() {
    _dayChangeTimer?.cancel();
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _dayChangeTimer = Timer(nextDay.difference(now), () {
      final current = state;
      if (!isClosed && current is TasksReady) {
        _emitProjection(current);
      }
      if (!isClosed) _scheduleDayChange();
    });
  }

  void pause() {
    _dayChangeTimer?.cancel();
    _dayChangeTimer = null;
  }

  void _onConflicts(List<TaskConflictRecord> conflicts) {
    _latestConflicts = [
      for (final conflict in conflicts)
        TaskConflictView(
          conflictId: conflict.id,
          taskId: conflict.taskId,
          activeTitle: conflict.activeTitle,
          retainedTitle: conflict.retainedTitle,
        ),
    ];
    final current = state;
    if (current is TasksReady) {
      emit(current.copyWith(conflicts: _latestConflicts));
    }
  }

  void selectFilter(TaskListFilter filter) {
    final current = state;
    if (current is! TasksReady) {
      return;
    }
    _emitProjection(current.copyWith(filter: filter));
  }

  void selectCategory(TaskCategory? category) {
    final current = state;
    if (current is! TasksReady) {
      return;
    }
    _emitProjection(current.copyWith(selectedCategory: category));
  }

  void showList() {
    final current = state;
    if (current is TasksReady) {
      emit(current.copyWith(viewMode: TasksViewMode.list));
    }
  }

  void showMatrix() {
    final current = state;
    if (current is TasksReady) {
      emit(current.copyWith(viewMode: TasksViewMode.matrix));
    }
  }

  void reportSynchronization({
    required TasksSyncStatus status,
    List<TaskConflictView> conflicts = const <TaskConflictView>[],
  }) {
    final current = state;
    if (current is TasksReady) {
      emit(current.copyWith(syncStatus: status, conflicts: conflicts));
    }
  }

  void _onTasks(List<Task> tasks) {
    final current = state;
    final ready = current is TasksReady
        ? current.copyWith(allTasks: tasks)
        : TasksReady(
            allTasks: tasks,
            visibleTasks: const <Task>[],
            matrix: const <EisenhowerQuadrant, List<Task>>{},
            filter: TaskListFilter.today,
            viewMode: TasksViewMode.list,
            syncStatus: _syncStatus(_syncService?.snapshot),
            conflicts: _latestConflicts,
          );
    _emitProjection(ready);
  }

  void _emitProjection(TasksReady base) {
    Iterable<Task> visible = switch (base.filter) {
      TaskListFilter.today => TaskRules.today(base.allTasks, _localDate()),
      TaskListFilter.urgent => TaskRules.urgent(base.allTasks),
      TaskListFilter.all => TaskRules.all(base.allTasks),
      TaskListFilter.completed => TaskRules.completed(base.allTasks),
    };
    final category = base.selectedCategory;
    if (category != null) {
      visible = visible.where((task) => task.category == category);
    }
    emit(
      base.copyWith(
        visibleTasks: List<Task>.unmodifiable(visible),
        matrix: TaskRules.matrix(
          category == null
              ? base.allTasks
              : base.allTasks.where((task) => task.category == category),
        ),
      ),
    );
  }

  void _onSyncSnapshot(TaskSyncSnapshot snapshot) {
    final current = state;
    if (current is! TasksReady) {
      return;
    }
    emit(
      current.copyWith(
        syncStatus: _syncStatus(snapshot),
        lastFailure: snapshot.lastFailure,
      ),
    );
  }

  static TasksSyncStatus _syncStatus(TaskSyncSnapshot? snapshot) =>
      switch (snapshot?.status) {
        TaskInitialSyncStatus.synchronizing => TasksSyncStatus.synchronizing,
        TaskInitialSyncStatus.ready =>
          snapshot?.lastFailure == null
              ? TasksSyncStatus.ready
              : TasksSyncStatus.recoverableFailure,
        TaskInitialSyncStatus.failed => TasksSyncStatus.recoverableFailure,
        _ => TasksSyncStatus.idle,
      };

  @override
  Future<void> close() async {
    pause();
    await _tasksSubscription?.cancel();
    await _conflictsSubscription?.cancel();
    await _syncSubscription?.cancel();
    return super.close();
  }
}
