import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/today/domain/today_agenda.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';

void main() {
  final today = TodayLocalDate(2026, 10, 23);

  TodayTaskReference task(
    String id,
    int order, {
    int? minute,
    int? duration,
    bool completed = false,
    TodayLocalDate? date,
    String owner = 'owner',
  }) => TodayTaskReference(
    taskId: id,
    ownerId: owner,
    title: 'Task $id',
    scheduledLocalDate: date ?? today,
    scheduledMinuteOfDay: minute,
    estimatedDurationMinutes: duration,
    isCompleted: completed,
    isUrgentImportant: false,
    isOverdue: false,
    ownerOrder: order,
  );

  test('timed and untimed groups retain owner tie order and saved values', () {
    final agenda = TodayAgenda.project(today, [
      task('late', 0, minute: 600, duration: 90),
      task('untimed-b', 4, completed: true),
      task('tie-b', 3, minute: 540, duration: 120),
      task('tie-a', 1, minute: 540, duration: 30),
      task('untimed-a', 2),
      task('late', 0, minute: 600), // Same Task linked from another map.
      task('tomorrow', 5, minute: 500, date: today.next),
      task('foreign', 6, owner: 'foreign'),
    ], ownerId: 'owner');

    expect(agenda.timed.map((e) => e.taskId), ['tie-a', 'tie-b', 'late']);
    expect(agenda.untimed.map((e) => e.taskId), ['untimed-a', 'untimed-b']);
    expect(agenda.timed.first.estimatedDurationMinutes, 30);
    expect(agenda.timed[1].estimatedDurationMinutes, 120);
    expect(agenda.untimed.last.isCompleted, isTrue);
    expect(agenda.untimed.first.scheduledMinuteOfDay, isNull);
  });
}
