import 'package:namma_project/features/tasks/domain/task.dart';

/// Pure projections over canonical Task aggregate instances.
abstract final class TaskRules {
  static List<Task> all(Iterable<Task> source) =>
      List<Task>.unmodifiable(source.where((task) => !task.isDeleted));

  static List<Task> today(Iterable<Task> source, DateTime localDate) =>
      List<Task>.unmodifiable(
        source.where(
          (task) => _isOpen(task) && _sameDate(task.scheduledDate, localDate),
        ),
      );

  static List<Task> urgent(Iterable<Task> source) => List<Task>.unmodifiable(
    source.where(
      (task) =>
          _isOpen(task) &&
          (task.quadrant == EisenhowerQuadrant.urgentImportant ||
              task.quadrant == EisenhowerQuadrant.urgentNotImportant),
    ),
  );

  static List<Task> completed(Iterable<Task> source) => List<Task>.unmodifiable(
    source.where((task) => !task.isDeleted && task.isCompleted),
  );

  static List<Task> byCategory(Iterable<Task> source, TaskCategory category) =>
      List<Task>.unmodifiable(
        source.where((task) => !task.isDeleted && task.category == category),
      );

  static Map<EisenhowerQuadrant, List<Task>> matrix(Iterable<Task> source) {
    final result = <EisenhowerQuadrant, List<Task>>{
      for (final quadrant in EisenhowerQuadrant.values) quadrant: <Task>[],
    };
    for (final task in source) {
      if (_isOpen(task)) {
        result[task.quadrant]!.add(task);
      }
    }
    return Map<EisenhowerQuadrant, List<Task>>.unmodifiable({
      for (final entry in result.entries)
        entry.key: List<Task>.unmodifiable(entry.value),
    });
  }

  static bool _isOpen(Task task) => !task.isDeleted && !task.isCompleted;

  static bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
