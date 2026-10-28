import 'habit.dart';

/// Independently versioned action for one immutable acting-device local date.
final class HabitDay {
  HabitDay._({
    required this.accountId,
    required this.habitId,
    required this.localDate,
    required this.completedAt,
    required this.count,
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
    int count = 1,
  }) => HabitDay.restore(
    accountId: accountId,
    habitId: habitId,
    localDate: localDate,
    completedAt: completedAt,
    count: count,
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
    int? count,
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
    final effectiveCount = count ?? (completedAt == null ? 0 : 1);
    if (effectiveCount < 0 ||
        effectiveCount > 9999 ||
        (completedAt != null && effectiveCount == 0)) {
      throw ArgumentError.value(effectiveCount, 'count');
    }
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
      count: effectiveCount,
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
  final int count;
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
    count: 0,
    earnedWhileDue: false,
    earnedAgainstRevisionId: null,
    recordedUtcOffsetMinutes: utcOffsetMinutes,
    updatedAt: at,
  );

  HabitDay changeCount({
    required int count,
    required int target,
    required DateTime at,
    required int utcOffsetMinutes,
    required String revisionId,
  }) {
    if (target < 1 || target > 9999 || count < 0 || count > target) {
      throw ArgumentError.value(count, 'count');
    }
    final reached = count >= target;
    return HabitDay.restore(
      accountId: accountId,
      habitId: habitId,
      localDate: localDate,
      count: count,
      completedAt: reached ? (completedAt ?? at) : null,
      earnedWhileDue: reached,
      earnedAgainstRevisionId: reached
          ? (earnedAgainstRevisionId ?? revisionId)
          : null,
      recordedUtcOffsetMinutes: utcOffsetMinutes,
      updatedAt: at,
    );
  }
}
