import 'habit.dart';

/// Independently versioned action for one immutable acting-device local date.
final class HabitDay {
  HabitDay._({
    required this.accountId,
    required this.habitId,
    required this.localDate,
    required this.completedAt,
    required this.earnedWhileDue,
    required this.earnedAgainstRevisionId,
    required this.recordedUtcOffsetMinutes,
    required this.updatedAt,
  });

  factory HabitDay.completed({
    required String accountId,
    required String habitId,
    required String localDate,
    required DateTime completedAt,
    required String earnedAgainstRevisionId,
    required int recordedUtcOffsetMinutes,
  }) => HabitDay.restore(
    accountId: accountId,
    habitId: habitId,
    localDate: localDate,
    completedAt: completedAt,
    earnedWhileDue: true,
    earnedAgainstRevisionId: earnedAgainstRevisionId,
    recordedUtcOffsetMinutes: recordedUtcOffsetMinutes,
    updatedAt: completedAt,
  );

  factory HabitDay.restore({
    required String accountId,
    required String habitId,
    required String localDate,
    required DateTime? completedAt,
    required bool earnedWhileDue,
    required String? earnedAgainstRevisionId,
    required int recordedUtcOffsetMinutes,
    required DateTime updatedAt,
  }) {
    if (accountId.trim().isEmpty || habitId.trim().isEmpty) {
      throw ArgumentError('Habit day identity must not be blank');
    }
    parseHabitLocalDate(localDate);
    validateHabitUtc(updatedAt, 'updatedAt');
    if (completedAt != null) validateHabitUtc(completedAt, 'completedAt');
    validateHabitOffset(recordedUtcOffsetMinutes);
    if (completedAt != null &&
        (!earnedWhileDue ||
            earnedAgainstRevisionId == null ||
            earnedAgainstRevisionId.isEmpty)) {
      throw ArgumentError('Completion needs due-state evidence');
    }
    if (completedAt == null &&
        (earnedWhileDue || earnedAgainstRevisionId != null)) {
      throw ArgumentError('Undo must clear due-state evidence');
    }
    return HabitDay._(
      accountId: accountId,
      habitId: habitId,
      localDate: localDate,
      completedAt: completedAt,
      earnedWhileDue: earnedWhileDue,
      earnedAgainstRevisionId: earnedAgainstRevisionId,
      recordedUtcOffsetMinutes: recordedUtcOffsetMinutes,
      updatedAt: updatedAt,
    );
  }

  final String accountId;
  final String habitId;
  final String localDate;
  final DateTime? completedAt;
  final bool earnedWhileDue;
  final String? earnedAgainstRevisionId;
  final int recordedUtcOffsetMinutes;
  final DateTime updatedAt;
  bool get isCompleted => completedAt != null;

  HabitDay undo(DateTime at, int utcOffsetMinutes) => HabitDay.restore(
    accountId: accountId,
    habitId: habitId,
    localDate: localDate,
    completedAt: null,
    earnedWhileDue: false,
    earnedAgainstRevisionId: null,
    recordedUtcOffsetMinutes: utcOffsetMinutes,
    updatedAt: at,
  );
}
