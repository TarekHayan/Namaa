/// The derived Qiyam streak (research.md R9, owner decision 2026-11-12):
/// consecutive nights recorded as performed, walked back from the current
/// night. Like the Adhkar streak it is derived on demand and never stored,
/// and it stays specific to Qiyam.
///
/// The walk asks the caller for one night's verdict at a time and stops at
/// the first night that breaks the run — it never reads every night up to
/// the cap and counts afterwards. The current night counts when it is
/// performed; whether it is unanswered OR an explicit "No" the walk starts
/// from the previous night, because tonight is still editable until the
/// next Maghrib. Any earlier night that is "No" or has no record ends the
/// run. A storage failure thrown by the lookup propagates: a failed read is
/// never a streak of 0.
library;

/// One night's stored state as the walk sees it: performed, the explicit
/// "No", or no record at all.
enum QiyamNightVerdict { performed, notPerformed, notRecorded }

/// The per-night lookup the walk drives. Returning null means the night has
/// no record; throwing means the store could not be read.
typedef QiyamNightVerdictLookup =
    Future<QiyamNightVerdict?> Function(String nightDate);

/// The maximum number of nights the walk visits (research.md R9).
const int kQiyamStreakWalkCapNights = 3650;

Future<int> qiyamStreak({
  required String currentNight,
  required QiyamNightVerdictLookup verdictOf,
  int cap = kQiyamStreakWalkCapNights,
}) async {
  if (cap < 1) {
    throw RangeError.value(cap, 'cap');
  }
  var night = _parseNight(currentNight);
  var visited = 0;
  var streak = 0;
  var isCurrentNight = true;
  while (visited < cap) {
    final verdict =
        await verdictOf(_key(night)) ?? QiyamNightVerdict.notRecorded;
    if (verdict == QiyamNightVerdict.performed) {
      streak++;
    } else if (!isCurrentNight) {
      // An earlier night that is "No" or has no record ends the run.
      return streak;
    }
    // The current night is skipped whatever its non-performed state is
    // (unanswered or an explicit "No"): it stays editable until the next
    // Maghrib, so it does not break the run behind it.
    isCurrentNight = false;
    night = night.subtract(const Duration(days: 1));
    visited++;
  }
  return streak;
}

DateTime _parseNight(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw ArgumentError.value(value, 'currentNight');
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
