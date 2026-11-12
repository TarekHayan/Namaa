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
    required this.morningCompleted,
    required this.morningTotal,
    required this.eveningCompleted,
    required this.eveningTotal,
    required this.period,
    required this.tonight,
    required this.adhkarStreak,
    required this.qiyamStreak,
  });

  final String ownerId;

  /// True when the Prayer schedule behind both domains is unavailable: the
  /// counts read 0/0, the streaks are null (not 0) and tonight is locked.
  /// Exposed honestly — never a calendar-day fallback.
  final bool scheduleUnavailable;

  final int morningCompleted;
  final int morningTotal;
  final int eveningCompleted;
  final int eveningTotal;

  /// The resolved period; null only when the schedule is unavailable.
  final TodayAdhkarPeriod? period;

  final TodayQiyamTonight tonight;

  /// The derived streaks; null when there is no day or night to walk from
  /// (an unavailable schedule) — never a fabricated 0.
  final int? adhkarStreak;
  final int? qiyamStreak;
}
