import 'dart:convert';

import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

/// Stable payloads for the local outbox and later account-owned sync.
final class HabitPayloadCodec {
  const HabitPayloadCodec();

  String encodeHabit(Habit habit) => jsonEncode({
    'id': habit.id,
    'accountId': habit.accountId,
    'name': habit.name,
    'scheduleRevisions': jsonDecode(encodeRevisions(habit.scheduleRevisions)),
    'reminderMinuteOfDay': habit.reminderMinuteOfDay,
    'createdAt': habit.createdAt.toIso8601String(),
    'updatedAt': habit.updatedAt.toIso8601String(),
    'deletedAt': habit.deletedAt?.toIso8601String(),
  });

  Habit decodeHabit(String payload) {
    try {
      final value = jsonDecode(payload) as Map<String, dynamic>;
      return Habit.restore(
        id: value['id'] as String,
        accountId: value['accountId'] as String,
        name: value['name'] as String,
        scheduleRevisions: decodeRevisions(
          jsonEncode(value['scheduleRevisions']),
        ),
        reminderMinuteOfDay: value['reminderMinuteOfDay'] as int?,
        createdAt: DateTime.parse(value['createdAt'] as String).toUtc(),
        updatedAt: DateTime.parse(value['updatedAt'] as String).toUtc(),
        deletedAt: (value['deletedAt'] as String?) == null
            ? null
            : DateTime.parse(value['deletedAt'] as String).toUtc(),
      );
    } on Object catch (error) {
      throw FormatException('Invalid Habit payload', error);
    }
  }

  String encodeRevisions(Iterable<HabitScheduleRevision> revisions) =>
      jsonEncode([
        for (final revision in revisions)
          {
            'revisionId': revision.revisionId,
            'effectiveAt': revision.effectiveAt.toIso8601String(),
            'effectiveLocalDate': revision.effectiveLocalDate,
            'utcOffsetMinutes': revision.utcOffsetMinutes,
            'weekdays': revision.weekdays,
          },
      ]);

  List<HabitScheduleRevision> decodeRevisions(String payload) {
    try {
      final value = jsonDecode(payload) as List<dynamic>;
      return List.unmodifiable(
        value.map((entry) {
          final revision = entry as Map<String, dynamic>;
          return HabitScheduleRevision(
            revisionId: revision['revisionId'] as String,
            effectiveAt: DateTime.parse(
              revision['effectiveAt'] as String,
            ).toUtc(),
            effectiveLocalDate: revision['effectiveLocalDate'] as String,
            utcOffsetMinutes: revision['utcOffsetMinutes'] as int,
            weekdays: (revision['weekdays'] as List<dynamic>).cast<int>(),
          );
        }),
      );
    } on Object catch (error) {
      throw FormatException('Invalid Habit revisions', error);
    }
  }

  String encodeDay(HabitDay day) => jsonEncode({
    'accountId': day.accountId,
    'habitId': day.habitId,
    'localDate': day.localDate,
    'completedAt': day.completedAt?.toIso8601String(),
    'earnedWhileDue': day.earnedWhileDue,
    'earnedAgainstRevisionId': day.earnedAgainstRevisionId,
    'recordedUtcOffsetMinutes': day.recordedUtcOffsetMinutes,
    'updatedAt': day.updatedAt.toIso8601String(),
  });

  HabitDay decodeDay(String payload) {
    try {
      final value = jsonDecode(payload) as Map<String, dynamic>;
      return HabitDay.restore(
        accountId: value['accountId'] as String,
        habitId: value['habitId'] as String,
        localDate: value['localDate'] as String,
        completedAt: (value['completedAt'] as String?) == null
            ? null
            : DateTime.parse(value['completedAt'] as String).toUtc(),
        earnedWhileDue: value['earnedWhileDue'] as bool,
        earnedAgainstRevisionId: value['earnedAgainstRevisionId'] as String?,
        recordedUtcOffsetMinutes: value['recordedUtcOffsetMinutes'] as int,
        updatedAt: DateTime.parse(value['updatedAt'] as String).toUtc(),
      );
    } on Object catch (error) {
      throw FormatException('Invalid HabitDay payload', error);
    }
  }
}
