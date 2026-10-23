import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_priority.dart';

void main() {
  final today = TodayLocalDate(2026, 10, 23);
  final tomorrow = today.next;
  final yesterday = TodayLocalDate(2026, 10, 22);

  TodayTaskReference task(
    String id,
    int order, {
    TodayLocalDate? date,
    bool urgent = true,
    bool overdue = false,
    bool completed = false,
    int? minute,
    String owner = 'owner',
  }) => TodayTaskReference(
    taskId: id,
    ownerId: owner,
    title: id,
    scheduledLocalDate: date ?? today,
    scheduledMinuteOfDay: minute,
    estimatedDurationMinutes: null,
    isCompleted: completed,
    isUrgentImportant: urgent,
    isOverdue: overdue,
    ownerOrder: order,
  );

  test(
    'Do First is owner ordered, bounded, deduplicated and excludes future only',
    () {
      final result = TodayPriority.project('owner', today, [
        task('third', 3),
        task('future', 1, date: tomorrow),
        task('deadline', 2, date: tomorrow, overdue: true),
        task('second', 1),
        task('first', 0),
        task('first', 0), // Map-linked duplicate.
        task('fourth', 4),
        task('done', 5, overdue: true, completed: true),
        task('not-urgent', 6, overdue: true, urgent: false),
        task('foreign', 7, overdue: true, owner: 'other'),
      ]);
      expect(result.doFirst.map((e) => e.taskId), [
        'first',
        'second',
        'deadline',
      ]);
      expect(result.overdueCount, 2);
    },
  );

  test(
    'overdue includes past dates and deadlines, independent of priority',
    () {
      final result = TodayPriority.project('owner', today, [
        task('past', 0, date: yesterday, overdue: true, urgent: false),
        task('today-deadline', 1, overdue: true),
        task('future-deadline', 2, date: tomorrow, overdue: true),
        task('today-time-passed', 3, minute: 480),
      ]);
      expect(result.overdueCount, 3);
      expect(result.doFirst.map((e) => e.taskId), [
        'today-deadline',
        'future-deadline',
        'today-time-passed',
      ]);
    },
  );
}
