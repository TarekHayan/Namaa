/// Read-only references to existing owner records. No Today persistence.
library;

import 'today_calendar.dart';

final class TodayTaskReference {
  TodayTaskReference({
    required this.taskId,
    required this.ownerId,
    required this.title,
    required this.scheduledLocalDate,
    required this.scheduledMinuteOfDay,
    required this.estimatedDurationMinutes,
    required this.isCompleted,
    required this.isUrgentImportant,
    required this.isOverdue,
    required this.ownerOrder,
  }) {
    if (taskId.trim().isEmpty ||
        ownerId.trim().isEmpty ||
        title.trim().isEmpty ||
        ownerOrder < 0 ||
        (scheduledMinuteOfDay != null &&
            (scheduledMinuteOfDay! < 0 || scheduledMinuteOfDay! > 1439)) ||
        (estimatedDurationMinutes != null && estimatedDurationMinutes! <= 0)) {
      throw ArgumentError('Invalid Today Task reference');
    }
  }

  final String taskId;
  final String ownerId;
  final String title;
  final TodayLocalDate scheduledLocalDate;
  final int? scheduledMinuteOfDay;
  final int? estimatedDurationMinutes;
  final bool isCompleted;
  final bool isUrgentImportant;
  final bool isOverdue;
  final int ownerOrder;
}

final class TodayHabitReference {
  TodayHabitReference({
    required this.habitId,
    required this.ownerId,
    required this.name,
    required this.localDate,
    required this.isDue,
    required this.isCompleted,
    required this.earnedWhileDue,
    required this.currentStreak,
    required this.ownerOrder,
  }) {
    if (habitId.trim().isEmpty ||
        ownerId.trim().isEmpty ||
        name.trim().isEmpty ||
        currentStreak < 0 ||
        ownerOrder < 0 ||
        (earnedWhileDue && !isCompleted)) {
      throw ArgumentError('Invalid Today Habit reference');
    }
  }

  final String habitId;
  final String ownerId;
  final String name;
  final TodayLocalDate localDate;
  final bool isDue;
  final bool isCompleted;
  final bool earnedWhileDue;
  final int currentStreak;
  final int ownerOrder;

  bool get isEligible => isDue || (isCompleted && earnedWhileDue);
}

final class TodayAwardReference {
  TodayAwardReference({
    required this.ownerId,
    required this.source,
    required this.sourceId,
    required this.amount,
    required this.awardedAtUtc,
  }) {
    if (ownerId.trim().isEmpty ||
        source.trim().isEmpty ||
        sourceId.trim().isEmpty ||
        amount < 0 ||
        !awardedAtUtc.isUtc) {
      throw ArgumentError('Invalid Today award reference');
    }
  }

  final String ownerId;
  final String source;
  final String sourceId;
  final int amount;
  final DateTime awardedAtUtc;

  String get uniqueKey => '$ownerId/$source/$sourceId';
}
