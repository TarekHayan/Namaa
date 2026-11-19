/// One retained Qiyam conflict as the owner sees it: both stored versions
/// of one night, with no resolution action anywhere. Each version carries
/// the answer and the optional details it held (rak'ahs, Witr, times and
/// note), so the read-only page can show what differed.
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
    this.activeWitr = false,
    this.retainedWitr = false,
    this.activeStartTime,
    this.activeEndTime,
    this.retainedStartTime,
    this.retainedEndTime,
    this.activeNote,
    this.retainedNote,
  });

  final String id;
  final String nightDate;
  final bool activePerformed;
  final bool retainedPerformed;
  final int? activeRakahs;
  final int? retainedRakahs;
  final DateTime activeAt;
  final DateTime retainedAt;
  final bool activeWitr;
  final bool retainedWitr;
  final String? activeStartTime;
  final String? activeEndTime;
  final String? retainedStartTime;
  final String? retainedEndTime;
  final String? activeNote;
  final String? retainedNote;
}
