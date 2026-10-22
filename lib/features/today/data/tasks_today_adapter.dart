library;

import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/application/task_review_queries.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

import '../application/today_tasks_port.dart';
import '../domain/today_calendar.dart';
import '../domain/today_models.dart';

final class TasksTodayAdapter implements TodayTasksPort {
  const TasksTodayAdapter(this._repository);
  final TaskRepository _repository;

  @override
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId) =>
      _repository.watchTasks(ownerId).map((tasks) => _Snapshot(ownerId, tasks));
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
