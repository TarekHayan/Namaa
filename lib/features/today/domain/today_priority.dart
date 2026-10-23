/// Bounded references to the owner's urgent-important and overdue work.
library;

import 'today_calendar.dart';
import 'today_models.dart';

final class TodayPriority {
  const TodayPriority({required this.doFirst, required this.overdueCount});

  final List<TodayTaskReference> doFirst;
  final int overdueCount;

  static TodayPriority project(
    String ownerId,
    TodayLocalDate date,
    Iterable<TodayTaskReference> source,
  ) {
    final seen = <String>{};
    final rows = source
        .where((task) => task.ownerId == ownerId && seen.add(task.taskId))
        .toList();
    final pending =
        rows
            .where(
              (task) =>
                  !task.isCompleted &&
                  task.isUrgentImportant &&
                  (task.scheduledLocalDate == date || task.isOverdue),
            )
            .toList()
          ..sort((a, b) => a.ownerOrder.compareTo(b.ownerOrder));
    return TodayPriority(
      doFirst: List.unmodifiable(pending.take(3)),
      overdueCount: rows
          .where((task) => task.isOverdue && !task.isCompleted)
          .length,
    );
  }
}
