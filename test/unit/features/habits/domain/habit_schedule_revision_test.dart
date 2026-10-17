import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';
import 'package:namma_project/features/habits/domain/habit_streak_rules.dart';

import '../../../../support/habits_test_support.dart';

void main() {
  test(
    'same-day revisions use the last schedule and preserve earned completion',
    () {
      final monday = DateTime.utc(2026, 10, 12, 8);
      final habit = Habit.create(
        id: kHabitsTestHabitId,
        accountId: kHabitsTestAccountA,
        name: 'Read',
        weekdays: {DateTime.monday, DateTime.wednesday},
        revisionId: 'revision-1',
        createdAt: monday,
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 120,
      );
      final completed = HabitDay.completed(
        accountId: habit.accountId,
        habitId: habit.id,
        localDate: '2026-10-12',
        completedAt: monday.add(const Duration(minutes: 10)),
        earnedAgainstRevisionId: 'revision-1',
        recordedUtcOffsetMinutes: 120,
      );
      final removed = habit.edit(
        name: 'Read more',
        weekdays: {DateTime.wednesday},
        reminderMinuteOfDay: 540,
        revisionId: 'revision-2',
        editedAt: monday.add(const Duration(minutes: 20)),
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 180,
      );
      final restored = removed.edit(
        name: 'Read more',
        weekdays: {DateTime.monday, DateTime.wednesday},
        reminderMinuteOfDay: 540,
        revisionId: 'revision-3',
        editedAt: monday.add(const Duration(minutes: 30)),
        effectiveLocalDate: '2026-10-12',
        utcOffsetMinutes: 180,
      );
      expect(removed.isDueOn('2026-10-12'), isFalse);
      expect(removed.scheduleRevisions.map((r) => r.revisionId), [
        'revision-1',
        'revision-2',
      ]);
      expect(removed.currentRevision.utcOffsetMinutes, 180);
      expect(completed.localDate, '2026-10-12');
      expect(completed.recordedUtcOffsetMinutes, 120);
      expect(
        HabitStreakRules.currentStreak(
          habit: removed,
          days: [completed],
          todayLocalDate: '2026-10-12',
        ),
        1,
      );
      expect(restored.revisionOn('2026-10-12')?.revisionId, 'revision-3');
      expect(restored.isDueOn('2026-10-12'), isTrue);
    },
  );

  test('a later edit retains the schedule effective at each closed date', () {
    final start = DateTime.utc(2026, 10, 12, 8);
    final habit =
        Habit.create(
          id: kHabitsTestHabitId,
          accountId: kHabitsTestAccountA,
          name: 'Read',
          weekdays: {DateTime.monday},
          revisionId: 'revision-1',
          createdAt: start,
          effectiveLocalDate: '2026-10-12',
          utcOffsetMinutes: 120,
        ).edit(
          name: 'Read',
          weekdays: {DateTime.wednesday},
          reminderMinuteOfDay: null,
          revisionId: 'revision-2',
          editedAt: start.add(const Duration(days: 1)),
          effectiveLocalDate: '2026-10-13',
          utcOffsetMinutes: 60,
        );
    expect(habit.isDueOn('2026-10-12'), isTrue);
    expect(habit.isDueOn('2026-10-13'), isFalse);
    expect(habit.isDueOn('2026-10-14'), isTrue);
    expect(habit.revisionOn('2026-10-12')?.revisionId, 'revision-1');
  });
}
