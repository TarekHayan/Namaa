/// The read-only Adhkar/Qiyam reference Today renders (data-model.md,
/// TodayAdhkarQiyamReference): Morning x/N, Evening x/N, the current Adhkar
/// period, tonight's Qiyam state and both derived streaks. Today never
/// touches Adhkar or Qiyam storage.
library;

/// The current Adhkar period; null only when the Prayer schedule is
/// unavailable, where no day is invented (owner decision, 2026-11-10).
enum TodayAdhkarPeriod { morning, evening, unrestricted }

/// Tonight's Qiyam state: an unanswered night, the explicit answers, or the
/// locked state when the schedule cannot resolve the night.
enum TodayQiyamTonight { unanswered, yes, no, locked }

final class TodayAdhkarQiyamReference {
  const TodayAdhkarQiyamReference({
    required this.ownerId,
    required this.scheduleUnavailable,
    required this.adhkarLoadFailed,
    required this.morningCompleted,
    required this.morningTotal,
    required this.eveningCompleted,
    required this.eveningTotal,
    required this.period,
    required this.qiyamLoadFailed,
    required this.tonight,
    required this.adhkarStreak,
    required this.qiyamStreak,
    this.lastThirdUtc,
    this.qiyamZoneId,
  });

  final String ownerId;

  /// True when the Prayer schedule behind both domains is unavailable: the
  /// counts read 0/0, the streaks are null (not 0) and tonight is locked.
  /// Exposed honestly — never a calendar-day fallback.
  final bool scheduleUnavailable;

  /// True when an Adhkar read failed (the catalog snapshot, the day's
  /// counts or the streak walk). A failed read is never presented as
  /// progress or as a streak of 0 — the screen shows a failure instead
  /// (Phase 6 review finding 2). Separate from [scheduleUnavailable].
  final bool adhkarLoadFailed;

  /// True when a Qiyam read failed (the night record or the streak walk);
  /// tonight's state is then not a real answer. Separate from
  /// [scheduleUnavailable].
  final bool qiyamLoadFailed;

  final int morningCompleted;
  final int morningTotal;
  final int eveningCompleted;
  final int eveningTotal;

  /// The resolved period; null only when the schedule is unavailable.
  final TodayAdhkarPeriod? period;

  final TodayQiyamTonight tonight;

  /// The derived streaks; null when there is no day or night to walk from
  /// (an unavailable schedule) or when the read failed — never a
  /// fabricated 0.
  final int? adhkarStreak;
  final int? qiyamStreak;

  /// The start of tonight's last third and the zone to show it in, the same
  /// values the Qiyam screen shows; null when the schedule cannot produce
  /// them (setup needed or unavailable).
  final DateTime? lastThirdUtc;
  final String? qiyamZoneId;
}
