/// One retained Qiyam conflict as the owner sees it: both stored versions
/// of one night, with no resolution action anywhere.
final class QiyamConflictEvidence {
  const QiyamConflictEvidence({
    required this.id,
    required this.nightDate,
    required this.activePerformed,
    required this.retainedPerformed,
    required this.activeRakahs,
    required this.retainedRakahs,
    required this.activeAt,
    required this.retainedAt,
  });

  final String id;
  final String nightDate;
  final bool activePerformed;
  final bool retainedPerformed;
  final int? activeRakahs;
  final int? retainedRakahs;
  final DateTime activeAt;
  final DateTime retainedAt;
}
