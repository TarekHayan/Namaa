/// Scheduled work is a view of the owner's saved calendar values.
library;

import 'today_calendar.dart';
import 'today_models.dart';

final class TodayAgenda {
  const TodayAgenda({required this.timed, required this.untimed});

  final List<TodayTaskReference> timed;
  final List<TodayTaskReference> untimed;

  static TodayAgenda project(
    TodayLocalDate date,
    Iterable<TodayTaskReference> source, {
    required String ownerId,
  }) {
    final seen = <String>{};
    final items = source
        .where(
          (task) =>
              task.ownerId == ownerId &&
              task.scheduledLocalDate == date &&
              seen.add(task.taskId),
        )
        .toList();
    final timed =
        items.where((task) => task.scheduledMinuteOfDay != null).toList()
          ..sort((a, b) {
            final time = a.scheduledMinuteOfDay!.compareTo(
              b.scheduledMinuteOfDay!,
            );
            return time != 0 ? time : a.ownerOrder.compareTo(b.ownerOrder);
          });
    final untimed =
        items.where((task) => task.scheduledMinuteOfDay == null).toList()
          ..sort((a, b) => a.ownerOrder.compareTo(b.ownerOrder));
    return TodayAgenda(
      timed: List.unmodifiable(timed),
      untimed: List.unmodifiable(untimed),
    );
  }
}
