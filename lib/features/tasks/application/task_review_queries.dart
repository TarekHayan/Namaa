import 'package:namma_project/features/tasks/domain/task.dart';

/// Pure review projections over the canonical Task aggregate source.
abstract final class TaskReviewQueries {
  static List<Task> completedHistory(Iterable<Task> source) =>
      List<Task>.unmodifiable(
        source.where((task) => !task.isDeleted && task.isCompleted),
      );

  static List<Task> overdue(
    Iterable<Task> source, {
    required DateTime localDate,
    required DateTime nowUtc,
  }) {
    if (!nowUtc.isUtc) {
      throw ArgumentError.value(nowUtc, 'nowUtc', 'must be UTC');
    }
    final today = DateTime(localDate.year, localDate.month, localDate.day);
    return List<Task>.unmodifiable(
      source.where((task) {
        if (task.isDeleted || task.isCompleted) {
          return false;
        }
        final scheduledDate = DateTime(
          task.scheduledDate.year,
          task.scheduledDate.month,
          task.scheduledDate.day,
        );
        final scheduledDatePassed = scheduledDate.isBefore(today);
        final deadlinePassed =
            task.targetDeadline?.toUtc().isBefore(nowUtc) ?? false;
        return scheduledDatePassed || deadlinePassed;
      }),
    );
  }
}
