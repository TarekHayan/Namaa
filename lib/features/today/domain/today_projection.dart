/// Pure, read-only daily projections over owner-provided references.
library;

import 'today_calendar.dart';
import 'today_models.dart';
import 'today_priority.dart';
import 'today_scope.dart';

final class TodayTaskSummary {
  const TodayTaskSummary({
    required this.items,
    required this.completedCount,
    required this.overdueCount,
    required this.doFirst,
  });
  final List<TodayTaskReference> items;
  final int completedCount;
  final int overdueCount;
  final List<TodayTaskReference> doFirst;
  int get totalCount => items.length;
  int get openCount => totalCount - completedCount;
  int? get percent => TodayProjection.percent(completedCount, totalCount);
}

final class TodayHabitSummary {
  const TodayHabitSummary({required this.items, required this.completedCount});
  final List<TodayHabitReference> items;
  final int completedCount;
  int get totalCount => items.length;
  int? get percent => TodayProjection.percent(completedCount, totalCount);
}

final class TodayXpSummary {
  const TodayXpSummary({required this.awards, required this.amount});
  final List<TodayAwardReference> awards;
  final int amount;
}

abstract final class TodayProjection {
  static int? percent(int completed, int total) =>
      total == 0 ? null : ((completed * 100) / total).round();

  static TodayTaskSummary tasks(
    TodayScope scope,
    TodayCalendar calendar,
    Iterable<TodayTaskReference> source,
  ) {
    final rows = source.toList(growable: false);
    final seen = <String>{};
    final items = List<TodayTaskReference>.unmodifiable(
      rows.where(
        (task) =>
            task.ownerId == scope.taskOwnerId &&
            task.scheduledLocalDate == calendar.localDate &&
            seen.add(task.taskId),
      ),
    );
    final priority = TodayPriority.project(
      scope.taskOwnerId,
      calendar.localDate,
      rows,
    );
    return TodayTaskSummary(
      items: items,
      completedCount: items.where((task) => task.isCompleted).length,
      overdueCount: priority.overdueCount,
      doFirst: priority.doFirst,
    );
  }

  static TodayHabitSummary habits(
    TodayScope scope,
    TodayCalendar calendar,
    Iterable<TodayHabitReference> source,
  ) {
    final seen = <String>{};
    final items = List<TodayHabitReference>.unmodifiable(
      source.where(
        (habit) =>
            habit.ownerId == scope.habitOwnerId &&
            habit.localDate == calendar.localDate &&
            habit.isEligible &&
            seen.add(habit.habitId),
      ),
    );
    return TodayHabitSummary(
      items: items,
      completedCount: items.where((habit) => habit.isCompleted).length,
    );
  }

  static TodayXpSummary xp(
    TodayScope scope,
    TodayCalendar calendar,
    Iterable<TodayAwardReference> source,
  ) {
    final seen = <String>{};
    final awards = List<TodayAwardReference>.unmodifiable(
      source.where(
        (award) =>
            award.ownerId == scope.xpOwnerId &&
            calendar.containsAwardAt(award.awardedAtUtc) &&
            seen.add(award.uniqueKey),
      ),
    );
    return TodayXpSummary(
      awards: awards,
      amount: awards.fold(0, (sum, award) => sum + award.amount),
    );
  }
}
