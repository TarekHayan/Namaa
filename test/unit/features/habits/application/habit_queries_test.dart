import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/habits/application/habit_queries.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

import '../../../../support/habits_test_support.dart';

void main() {
  final monday = DateTime.utc(2026, 10, 12, 9);
  Habit habit({
    String id = kHabitsTestHabitId,
    String accountId = kHabitsTestAccountA,
    bool deleted = false,
  }) => Habit.restore(
    id: id,
    accountId: accountId,
    name: 'Read',
    scheduleRevisions: [
      HabitScheduleRevision(
        revisionId: kHabitsTestRevisionId,
        effectiveAt: monday,
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
        weekdays: {1, 3},
      ),
    ],
    createdAt: monday,
    updatedAt: monday,
    deletedAt: deleted ? monday.add(const Duration(hours: 1)) : null,
  );
  HabitDay day(
    String date, {
    String habitId = kHabitsTestHabitId,
    String accountId = kHabitsTestAccountA,
    bool complete = true,
  }) => HabitDay.restore(
    accountId: accountId,
    habitId: habitId,
    localDate: date,
    completedAt: complete ? DateTime.utc(2026, 10, 14, 9) : null,
    earnedWhileDue: complete,
    earnedAgainstRevisionId: complete ? kHabitsTestRevisionId : null,
    recordedUtcOffsetMinutes: 120,
    updatedAt: DateTime.utc(2026, 10, 14, 9),
  );

  test(
    'one habit history keeps only owner and completed dates, newest first',
    () {
      final history = HabitQueries.history(
        accountId: kHabitsTestAccountA,
        habitId: kHabitsTestHabitId,
        localDate: '2026-10-14',
        habits: [
          habit(),
          habit(id: kHabitsTestOtherHabitId),
        ],
        days: [
          day('2026-10-12'),
          day('2026-10-14'),
          day('2026-10-13', complete: false),
          day('2026-10-14', habitId: kHabitsTestOtherHabitId),
          day('2026-10-14', accountId: kHabitsTestAccountB),
        ],
      )!;
      expect(history.completedDates, ['2026-10-14', '2026-10-12']);
      expect(history.currentStreak, 2);
      expect(history.scheduleRevisions, hasLength(1));
      expect(history.isTodayPending, isFalse);
      expect(
        () => history.completedDates.add('2026-10-15'),
        throwsUnsupportedError,
      );
    },
  );

  test('incomplete due today is pending with previous streak intact', () {
    final history = HabitQueries.history(
      accountId: kHabitsTestAccountA,
      habitId: kHabitsTestHabitId,
      localDate: '2026-10-14',
      habits: [habit()],
      days: [day('2026-10-12')],
    )!;
    expect(history.isTodayPending, isTrue);
    expect(history.currentStreak, 1);
  });

  test('deleted and foreign parents have no active history', () {
    final allDays = [day('2026-10-12')];
    expect(
      HabitQueries.history(
        accountId: kHabitsTestAccountA,
        habitId: kHabitsTestHabitId,
        localDate: '2026-10-14',
        habits: [habit(deleted: true)],
        days: allDays,
      ),
      isNull,
    );
    expect(
      HabitQueries.history(
        accountId: kHabitsTestAccountA,
        habitId: kHabitsTestHabitId,
        localDate: '2026-10-14',
        habits: [habit(accountId: kHabitsTestAccountB)],
        days: allDays,
      ),
      isNull,
    );
    expect(
      HabitQueries.today(
        accountId: kHabitsTestAccountA,
        localDate: '2026-10-14',
        habits: [
          habit(deleted: true),
          habit(accountId: kHabitsTestAccountB),
        ],
        days: allDays,
      ),
      isEmpty,
    );
  });
}
