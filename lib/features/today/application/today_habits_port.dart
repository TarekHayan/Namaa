/// Read-only Habit owner boundary for Today.
library;

import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/today_calendar.dart';
import '../domain/today_models.dart';

/// One confirmed pair of Habit and HabitDay owner emissions. Projection uses
/// HabitQueries for the sampled day and its authoritative streak.
abstract interface class TodayHabitReadSnapshot {
  String get ownerId;

  List<TodayHabitReference> project(TodayCalendar calendar);
}

abstract interface class TodayHabitsPort {
  /// Must not emit until both owner constituent streams have usable values.
  /// Either constituent error/closure invalidates this source; retry starts a
  /// fresh paired observation, never a mix of old/new unconfirmed rows.
  Stream<TodayHabitReadSnapshot> watchHabits(String ownerId);

  Future<AppResult<void>> setCompleted({
    required String ownerId,
    required String habitId,
    required TodayLocalDate expectedLocalDate,
    required bool completed,
  });
}
