import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/domain/today_models.dart';
import 'package:namma_project/features/today/domain/today_projection.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';

void main() {
  final scope = TodayScope.account(accountId: 'owner', generation: 1);
  final day = TodayLocalDate(2026, 10, 12);
  final calendar = TodayCalendar(
    localDate: day,
    nowUtc: DateTime.utc(2026, 10, 12, 12),
    utcOffsetMinutes: 0,
    dayStartUtc: DateTime.utc(2026, 10, 12),
    nextDayStartUtc: DateTime.utc(2026, 10, 13),
    projectionRevision: 0,
  );

  TodayTaskReference task(
    int id, {
    bool completed = false,
    bool overdue = false,
    bool urgent = false,
    TodayLocalDate? date,
    String owner = 'owner',
  }) => TodayTaskReference(
    taskId: '$id',
    ownerId: owner,
    title: 'Task $id',
    scheduledLocalDate: date ?? day,
    scheduledMinuteOfDay: null,
    estimatedDurationMinutes: null,
    isCompleted: completed,
    isUrgentImportant: urgent,
    isOverdue: overdue,
    ownerOrder: id,
  );

  test(
    'Do First includes overdue work on other dates without changing today progress',
    () {
      final summary = TodayProjection.tasks(scope, calendar, [
        task(1, urgent: true),
        task(
          2,
          urgent: true,
          overdue: true,
          date: TodayLocalDate(2026, 10, 13),
        ),
        task(3, urgent: true, date: TodayLocalDate(2026, 10, 13)),
        task(4, overdue: true, date: TodayLocalDate(2026, 10, 11)),
      ]);
      expect(summary.totalCount, 1);
      expect(summary.doFirst.map((item) => item.taskId), ['1', '2']);
      expect(summary.overdueCount, 2);
    },
  );

  test(
    'completed scheduled tasks remain in denominator; priority and overdue stay independent',
    () {
      final rows = [
        for (var i = 0; i < 10; i++)
          task(i, completed: i < 4, urgent: i.isEven),
        task(
          10,
          overdue: true,
          urgent: true,
          date: TodayLocalDate(2026, 10, 11),
        ),
        task(11, urgent: true, date: TodayLocalDate(2026, 10, 13)),
        task(12, owner: 'foreign', completed: true),
      ];
      final result = TodayProjection.tasks(scope, calendar, rows);
      expect(result.totalCount, 10);
      expect(result.completedCount, 4);
      expect(result.percent, 40);
      expect(result.overdueCount, 1);
      expect(result.doFirst.map((e) => e.taskId), ['4', '6', '8']);
      expect(result.doFirst.any((e) => e.taskId == '11'), false);
    },
  );

  test(
    'eligible habits include retained earned completion; empty denominator is unknown',
    () {
      TodayHabitReference habit(
        int id, {
        bool due = true,
        bool complete = false,
        bool earned = false,
      }) => TodayHabitReference(
        habitId: '$id',
        ownerId: 'owner',
        name: 'Habit $id',
        localDate: day,
        isDue: due,
        isCompleted: complete,
        earnedWhileDue: earned,
        currentStreak: id,
        ownerOrder: id,
      );
      final result = TodayProjection.habits(scope, calendar, [
        habit(1, complete: true),
        habit(2),
        habit(3),
        habit(4),
        habit(5, due: false, complete: true, earned: true),
        habit(6, due: false),
      ]);
      expect(result.totalCount, 5);
      expect(result.completedCount, 2);
      expect(result.percent, 40);
      expect(TodayProjection.habits(scope, calendar, []).percent, isNull);
      expect(TodayProjection.percent(1, 3), 33);
      expect(TodayProjection.percent(2, 3), 67);
    },
  );

  test('actual award rows, not current task state, determine local-day XP', () {
    TodayAwardReference award(
      String id,
      DateTime at, {
      String owner = 'owner',
    }) => TodayAwardReference(
      ownerId: owner,
      source: 'task_done',
      sourceId: id,
      amount: 25,
      awardedAtUtc: at,
    );
    final result = TodayProjection.xp(scope, calendar, [
      award('reopened', DateTime.utc(2026, 10, 11, 23)),
      award('deleted', DateTime.utc(2026, 10, 12)),
      award('deleted', DateTime.utc(2026, 10, 12)),
      award('second', DateTime.utc(2026, 10, 12, 23, 59)),
      award('tomorrow', DateTime.utc(2026, 10, 13)),
      award('foreign', DateTime.utc(2026, 10, 12), owner: 'foreign'),
    ]);
    expect(result.amount, 50);
    expect(result.awards.map((a) => a.sourceId), ['deleted', 'second']);
  });
}
