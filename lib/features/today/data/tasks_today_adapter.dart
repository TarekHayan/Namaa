library;

import 'dart:async';

import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/application/task_review_queries.dart';
import 'package:namma_project/features/tasks/application/task_sync_service.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

import '../application/today_tasks_port.dart';
import '../domain/today_calendar.dart';
import '../domain/today_models.dart';

final class TasksTodayAdapter implements TodayTasksPort {
  const TasksTodayAdapter(
    this._repository, {
    TaskCompletionService? completionService,
    TaskSyncService? syncService,
  }) : _completionService = completionService,
       _syncService = syncService;
  final TaskRepository _repository;
  final TaskCompletionService? _completionService;
  final TaskSyncService? _syncService;

  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) =>
      _repository.watchTasks(ownerId).map((tasks) => _Snapshot(ownerId, tasks));

  @override
  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String taskId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  }) async {
    final service = _completionService;
    if (service == null) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'today.action.unavailable',
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    }
    final day = DateTime(
      expectedLocalDate.year,
      expectedLocalDate.month,
      expectedLocalDate.day,
    );
    final result = completed
        ? await service.completeTask(
            taskId,
            expectedAccountId: ownerId,
            expectedLocalDate: day,
          )
        : await service.reopenTask(
            taskId,
            expectedAccountId: ownerId,
            expectedLocalDate: day,
          );
    if (result.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    if (_syncService != null) unawaited(_syncService.synchronize());
    return const AppResult.success(null);
  }
}

final class _Snapshot implements TodayTaskReadSnapshot {
  _Snapshot(this.ownerId, Iterable<Task> tasks)
    : _tasks = List.unmodifiable(
        tasks.where((task) => task.accountId == ownerId && !task.isDeleted),
      );

  @override
  final String ownerId;
  final List<Task> _tasks;

  @override
  List<TodayTaskReference> project(TodayCalendar calendar) {
    final overdue = TaskReviewQueries.overdue(
      _tasks,
      localDate: DateTime(
        calendar.localDate.year,
        calendar.localDate.month,
        calendar.localDate.day,
      ),
      nowUtc: calendar.nowUtc,
    ).map((task) => task.id).toSet();
    return List.unmodifiable([
      for (var index = 0; index < _tasks.length; index++)
        TodayTaskReference(
          taskId: _tasks[index].id,
          ownerId: ownerId,
          title: _tasks[index].title,
          scheduledLocalDate: TodayLocalDate.fromCivil(
            _tasks[index].scheduledDate,
          ),
          scheduledMinuteOfDay: _tasks[index].scheduledTime == null
              ? null
              : _tasks[index].scheduledTime!.hour * 60 +
                    _tasks[index].scheduledTime!.minute,
          estimatedDurationMinutes: _tasks[index].estimatedDurationMinutes,
          isCompleted: _tasks[index].isCompleted,
          isUrgentImportant:
              _tasks[index].quadrant == EisenhowerQuadrant.urgentImportant,
          isOverdue: overdue.contains(_tasks[index].id),
          ownerOrder: index,
        ),
    ]);
  }
}
