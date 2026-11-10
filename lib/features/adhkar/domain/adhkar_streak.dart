/// The derived Adhkar streak (FR-006b, research.md R9): consecutive Adhkar
/// days on which both Morning and Evening were complete. The streak is never
/// stored and stays specific to Adhkar; there is no history list.
///
/// The walk trusts the per-day completion it receives — the repository
/// judges each day against the catalog version that day's counts were made
/// against — so a catalog version change keeps past days valid. The current
/// day does not break the streak before it ends: it counts only when both
/// lists are complete, and otherwise the walk starts at the previous day.
library;

/// One Adhkar day's set-completion state, already judged by the repository
/// against that day's catalog version.
final class AdhkarDayCompletion {
  const AdhkarDayCompletion({
    required this.morningComplete,
    required this.eveningComplete,
  });

  final bool morningComplete;
  final bool eveningComplete;

  bool get complete => morningComplete && eveningComplete;
}

/// The maximum number of days the streak walk visits (research.md R9).
const int kAdhkarStreakWalkCapDays = 3650;

int adhkarStreak({
  required Map<String, AdhkarDayCompletion> completions,
  required String today,
}) {
  var day = _parseDay(today);
  var visited = 0;
  var streak = 0;
  while (visited < kAdhkarStreakWalkCapDays) {
    final completion = completions[_key(day)];
    final isToday = visited == 0;
    if (completion == null || !completion.complete) {
      // An incomplete or missing today does not break the run behind it;
      // any earlier day does.
      if (isToday) {
        day = day.subtract(const Duration(days: 1));
        visited++;
        continue;
      }
      return streak;
    }
    streak++;
    day = day.subtract(const Duration(days: 1));
    visited++;
  }
  return streak;
}

DateTime _parseDay(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw ArgumentError.value(value, 'today');
  }
  return DateTime.utc(
    int.parse(value.substring(0, 4)),
    int.parse(value.substring(5, 7)),
    int.parse(value.substring(8, 10)),
  );
}

String _key(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
