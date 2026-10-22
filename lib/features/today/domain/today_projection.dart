/// Pure, read-only daily projections over owner-provided references.
library;

import 'today_calendar.dart';
import 'today_models.dart';
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
    final seenPriority = <String>{};
    final pending = rows
        .where(
          (task) =>
              task.ownerId == scope.taskOwnerId &&
              !task.isCompleted &&
              task.isUrgentImportant &&
              (task.scheduledLocalDate == calendar.localDate ||
                  task.isOverdue) &&
              seenPriority.add(task.taskId),
        )
        .toList();
    // The owner's canonical order is retained when priorities tie.
    pending.sort((a, b) => a.ownerOrder.compareTo(b.ownerOrder));
    return TodayTaskSummary(
      items: items,
      completedCount: items.where((task) => task.isCompleted).length,
      overdueCount: rows
          .where(
            (task) =>
                task.ownerId == scope.taskOwnerId &&
                task.isOverdue &&
                !task.isCompleted,
          )
          .map((task) => task.taskId)
          .toSet()
          .length,
      doFirst: List.unmodifiable(pending.take(3)),
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
