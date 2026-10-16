import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

import '../../../../support/habits_test_support.dart';

void main() {
  const codec = HabitPayloadCodec();

  test(
    'Habit payload keeps schedule revision date, UTC instant and offset',
    () {
      final habit = Habit.create(
        id: kHabitsTestHabitId,
        accountId: kHabitsTestAccountA,
        name: '  Read  ',
        weekdays: {DateTime.wednesday, DateTime.monday},
        revisionId: kHabitsTestRevisionId,
        createdAt: DateTime.utc(2026, 10, 12, 22),
        effectiveLocalDate: '2026-10-13',
        utcOffsetMinutes: 180,
        reminderMinuteOfDay: 540,
      );
      final restored = codec.decodeHabit(codec.encodeHabit(habit));
      expect(restored.name, 'Read');
      expect(restored.reminderMinuteOfDay, 540);
      expect(restored.currentRevision.weekdays, [1, 3]);
      expect(restored.currentRevision.effectiveLocalDate, '2026-10-13');
      expect(restored.currentRevision.utcOffsetMinutes, 180);
      expect(
        restored.currentRevision.effectiveAt,
        DateTime.utc(2026, 10, 12, 22),
      );
    },
  );

  test(
    'HabitDay payload keeps immutable local date through undo and travel',
    () {
      final day = HabitDay.completed(
        accountId: kHabitsTestAccountA,
        habitId: kHabitsTestHabitId,
        localDate: '2026-10-13',
        completedAt: DateTime.utc(2026, 10, 12, 22),
        earnedAgainstRevisionId: kHabitsTestRevisionId,
        recordedUtcOffsetMinutes: 180,
      );
      final restored = codec.decodeDay(codec.encodeDay(day));
      expect(restored.localDate, '2026-10-13');
      expect(restored.recordedUtcOffsetMinutes, 180);
      expect(restored.completedAt, DateTime.utc(2026, 10, 12, 22));
      final undone = codec.decodeDay(
        codec.encodeDay(day.undo(DateTime.utc(2026, 10, 13, 10), -60)),
      );
      expect(undone.localDate, '2026-10-13');
      expect(undone.recordedUtcOffsetMinutes, -60);
      expect(undone.isCompleted, isFalse);
    },
  );
}
