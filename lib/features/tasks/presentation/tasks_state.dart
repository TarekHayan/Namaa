import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

enum TaskListFilter { today, urgent, all, completed }

enum TasksViewMode { list, matrix }

enum TasksSyncStatus { idle, synchronizing, ready, recoverableFailure }

final class TaskConflictView {
  const TaskConflictView({
    required this.conflictId,
    required this.taskId,
    required this.activeTitle,
    required this.retainedTitle,
  });

  final String conflictId;
  final String taskId;
  final String activeTitle;
  final String retainedTitle;
}

sealed class TasksState {
  const TasksState();
}

final class TasksInitial extends TasksState {
  const TasksInitial();
}

final class TasksLoading extends TasksState {
  const TasksLoading();
}

final class TasksFailure extends TasksState {
  const TasksFailure(this.failure);

  final AppFailure failure;
}

final class TasksReady extends TasksState {
  TasksReady({
    required List<Task> allTasks,
    required List<Task> visibleTasks,
    required Map<EisenhowerQuadrant, List<Task>> matrix,
    required this.filter,
    required this.viewMode,
    this.selectedCategory,
    this.syncStatus = TasksSyncStatus.idle,
    List<TaskConflictView> conflicts = const <TaskConflictView>[],
    this.lastFailure,
  }) : allTasks = List<Task>.unmodifiable(allTasks),
       visibleTasks = List<Task>.unmodifiable(visibleTasks),
       matrix = Map<EisenhowerQuadrant, List<Task>>.unmodifiable({
         for (final entry in matrix.entries)
           entry.key: List<Task>.unmodifiable(entry.value),
       }),
       conflicts = List<TaskConflictView>.unmodifiable(conflicts);

  static const Object _unchanged = Object();

  final List<Task> allTasks;
  final List<Task> visibleTasks;
  final Map<EisenhowerQuadrant, List<Task>> matrix;
  final TaskListFilter filter;
  final TasksViewMode viewMode;
  final TaskCategory? selectedCategory;
  final TasksSyncStatus syncStatus;
  final List<TaskConflictView> conflicts;
  final AppFailure? lastFailure;

  TasksReady copyWith({
    List<Task>? allTasks,
    List<Task>? visibleTasks,
    Map<EisenhowerQuadrant, List<Task>>? matrix,
    TaskListFilter? filter,
    TasksViewMode? viewMode,
    Object? selectedCategory = _unchanged,
    TasksSyncStatus? syncStatus,
    List<TaskConflictView>? conflicts,
    Object? lastFailure = _unchanged,
  }) => TasksReady(
    allTasks: allTasks ?? this.allTasks,
    visibleTasks: visibleTasks ?? this.visibleTasks,
    matrix: matrix ?? this.matrix,
    filter: filter ?? this.filter,
    viewMode: viewMode ?? this.viewMode,
    selectedCategory: identical(selectedCategory, _unchanged)
        ? this.selectedCategory
        : selectedCategory as TaskCategory?,
    syncStatus: syncStatus ?? this.syncStatus,
    conflicts: conflicts ?? this.conflicts,
    lastFailure: identical(lastFailure, _unchanged)
        ? this.lastFailure
        : lastFailure as AppFailure?,
  );
}
