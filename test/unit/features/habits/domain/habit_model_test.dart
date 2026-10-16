import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

import '../../../../support/habits_test_support.dart';

void main() {
  final instant = DateTime.utc(2026, 10, 12, 9);

  test('habit owns a trimmed name and canonical weekday revision', () {
    final habit = Habit.create(
      id: kHabitsTestHabitId,
      accountId: kHabitsTestAccountA,
      name: '  Reading  ',
      weekdays: {DateTime.wednesday, DateTime.monday},
      revisionId: kHabitsTestRevisionId,
      createdAt: instant,
      effectiveLocalDate: '2026-10-12',
      utcOffsetMinutes: 120,
    );
    expect(habit.name, 'Reading');
    expect(habit.scheduleRevisions.single.weekdays, [1, 3]);
    expect(habit.isDueOn('2026-10-12'), isTrue);
    expect(habit.isDueOn('2026-10-13'), isFalse);
    expect(
      () => habit.scheduleRevisions.single.weekdays.add(5),
      throwsUnsupportedError,
    );
  });

  test('invalid name, weekdays, and reminder are rejected', () {
    Habit create(String name, Set<int> weekdays, int? reminder) => Habit.create(
      id: kHabitsTestHabitId,
      accountId: kHabitsTestAccountA,
      name: name,
      weekdays: weekdays,
      revisionId: kHabitsTestRevisionId,
      createdAt: instant,
      effectiveLocalDate: '2026-10-12',
      utcOffsetMinutes: 120,
      reminderMinuteOfDay: reminder,
    );
    expect(() => create(' ', {1}, null), throwsArgumentError);
    expect(() => create('Read', {}, null), throwsArgumentError);
    expect(() => create('Read', {0}, null), throwsArgumentError);
    expect(() => create('Read', {1}, 1440), throwsArgumentError);
    expect(() => create('Read', {1}, -1), throwsArgumentError);
  });

  test('one day has immutable local date and UTC action time', () {
    final day = HabitDay.completed(
      accountId: kHabitsTestAccountA,
      habitId: kHabitsTestHabitId,
      localDate: '2026-10-12',
      completedAt: instant,
      earnedAgainstRevisionId: kHabitsTestRevisionId,
      recordedUtcOffsetMinutes: 120,
    );
    expect(day.localDate, '2026-10-12');
    expect(day.earnedWhileDue, isTrue);
    expect(
      day.undo(DateTime.utc(2026, 10, 12, 10), 60).localDate,
      day.localDate,
    );
    expect(
      () => HabitDay.completed(
        accountId: kHabitsTestAccountA,
        habitId: kHabitsTestHabitId,
        localDate: '2026-02-30',
        completedAt: instant,
        earnedAgainstRevisionId: kHabitsTestRevisionId,
        recordedUtcOffsetMinutes: 120,
      ),
      throwsArgumentError,
    );
  });
}
