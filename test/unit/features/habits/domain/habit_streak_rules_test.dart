import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/habits/domain/habit_streak_rules.dart';

import '../../../../support/habits_test_support.dart';

void main() {
  const today = '2026-10-14'; // Wednesday.
  final created = DateTime.utc(2026, 10, 5, 9);

  Habit habit({
    String id = kHabitsTestHabitId,
    String accountId = kHabitsTestAccountA,
    required Set<int> weekdays,
    List<HabitScheduleRevision>? revisions,
  }) => Habit.restore(
    id: id,
    accountId: accountId,
    name: 'Reading',
    scheduleRevisions:
        revisions ??
        [
          HabitScheduleRevision(
            revisionId: kHabitsTestRevisionId,
            effectiveAt: created,
            effectiveLocalDate: '2026-10-05',
            utcOffsetMinutes: 120,
            weekdays: weekdays,
          ),
        ],
    createdAt: created,
    updatedAt: created,
  );

  HabitDay day(
    String date, {
    String accountId = kHabitsTestAccountA,
    String habitId = kHabitsTestHabitId,
    DateTime? updatedAt,
    bool completed = true,
  }) {
    final action =
        updatedAt ?? DateTime.utc(2026, 10, int.parse(date.substring(8)), 10);
    return HabitDay.restore(
      accountId: accountId,
      habitId: habitId,
      localDate: date,
      completedAt: completed ? action : null,
      earnedWhileDue: completed,
      earnedAgainstRevisionId: completed ? kHabitsTestRevisionId : null,
      recordedUtcOffsetMinutes: 120,
      updatedAt: action,
    );
  }

  final cases =
      <({String name, Set<int> schedule, List<String> dates, int expected})>[
        (name: 'zero history', schedule: {1, 3}, dates: [], expected: 0),
        (name: 'today alone', schedule: {1, 3}, dates: [today], expected: 1),
        (
          name: 'Monday and Wednesday',
          schedule: {1, 3},
          dates: ['2026-10-12', today],
          expected: 2,
        ),
        (
          name: 'Tuesday is neutral',
          schedule: {1, 3},
          dates: ['2026-10-12'],
          expected: 1,
        ),
        (
          name: 'pending Wednesday retains Monday',
          schedule: {1, 3},
          dates: ['2026-10-12'],
          expected: 1,
        ),
        (
          name: 'missed Monday ends prior streak',
          schedule: {1, 3},
          dates: ['2026-10-07'],
          expected: 0,
        ),
        (
          name: 'new streak after missed Monday',
          schedule: {1, 3},
          dates: [today],
          expected: 1,
        ),
        (
          name: 'daily three days',
          schedule: {1, 2, 3, 4, 5, 6, 7},
          dates: ['2026-10-12', '2026-10-13', today],
          expected: 3,
        ),
        (
          name: 'daily closed miss',
          schedule: {1, 2, 3, 4, 5, 6, 7},
          dates: ['2026-10-12', today],
          expected: 1,
        ),
        (
          name: 'weekly gap is neutral',
          schedule: {3},
          dates: ['2026-10-07', today],
          expected: 2,
        ),
      ];

  for (final scenario in cases) {
    test('schedule case: ${scenario.name}', () {
      expect(
        HabitStreakRules.currentStreak(
          habit: habit(weekdays: scenario.schedule),
          days: scenario.dates.map(day),
          todayLocalDate: today,
        ),
        scenario.expected,
      );
    });
  }

  test('duplicate day and foreign account or habit never inflate a streak', () {
    final monday = day('2026-10-12');
    expect(
      HabitStreakRules.currentStreak(
        habit: habit(weekdays: {1, 3}),
        days: [
          monday,
          monday,
          day(today),
          day(today, accountId: kHabitsTestAccountB),
          day(today, habitId: kHabitsTestOtherHabitId),
        ],
        todayLocalDate: today,
      ),
      2,
    );
    expect(
      HabitStreakRules.currentStreak(
        habit: habit(id: kHabitsTestOtherHabitId, weekdays: {1, 3}),
        days: [monday, day(today)],
        todayLocalDate: today,
      ),
      0,
    );
  });

  test('latest undo wins a duplicate date and restores the prior streak', () {
    expect(
      HabitStreakRules.currentStreak(
        habit: habit(weekdays: {1, 3}),
        days: [
          day('2026-10-12'),
          day(today, updatedAt: DateTime.utc(2026, 10, 14, 10)),
          day(
            today,
            updatedAt: DateTime.utc(2026, 10, 14, 11),
            completed: false,
          ),
        ],
        todayLocalDate: today,
      ),
      1,
    );
  });

  test('a completion earned before same-day removal still counts', () {
    final revised = habit(
      weekdays: {1, 3},
      revisions: [
        HabitScheduleRevision(
          revisionId: kHabitsTestRevisionId,
          effectiveAt: created,
          effectiveLocalDate: '2026-10-05',
          utcOffsetMinutes: 120,
          weekdays: {1, 3},
        ),
        HabitScheduleRevision(
          revisionId: 'new-revision',
          effectiveAt: DateTime.utc(2026, 10, 14, 12),
          effectiveLocalDate: today,
          utcOffsetMinutes: 120,
          weekdays: {1},
        ),
      ],
    );
    expect(revised.isDueOn(today), isFalse);
    expect(
      HabitStreakRules.currentStreak(
        habit: revised,
        days: [day('2026-10-12'), day(today)],
        todayLocalDate: today,
      ),
      2,
    );
  });

  test(
    'a historical edit uses its former schedule and no precreation misses',
    () {
      final revised = habit(
        weekdays: {1},
        revisions: [
          HabitScheduleRevision(
            revisionId: kHabitsTestRevisionId,
            effectiveAt: created,
            effectiveLocalDate: '2026-10-05',
            utcOffsetMinutes: 120,
            weekdays: {1},
          ),
          HabitScheduleRevision(
            revisionId: 'new-revision',
            effectiveAt: DateTime.utc(2026, 10, 13, 12),
            effectiveLocalDate: '2026-10-13',
            utcOffsetMinutes: 120,
            weekdays: {3},
          ),
        ],
      );
      expect(
        HabitStreakRules.currentStreak(
          habit: revised,
          days: [day('2026-10-12'), day(today)],
          todayLocalDate: today,
        ),
        2,
      );
    },
  );
}
