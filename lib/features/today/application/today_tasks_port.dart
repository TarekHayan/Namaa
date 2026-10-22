/// Read-only Task owner boundary for Today.
library;

import '../domain/today_calendar.dart';
import '../domain/today_models.dart';

/// An immutable owner emission. The adapter retains enough canonical owner
/// data to re-run overdue membership when the clock changes without a Task
/// write or a second Today store.
abstract interface class TodayTaskReadSnapshot {
  String get ownerId;

  List<TodayTaskReference> project(TodayCalendar calendar);
}

abstract interface class TodayTasksPort {
  /// Emits the full owner collection, including completed Tasks. The adapter
  /// excludes foreign/deleted rows and preserves Task repository order.
  /// Errors and unexpected closure are surfaced to the independent section.
  Stream<TodayTaskReadSnapshot> watchTasks(String ownerId);
}
