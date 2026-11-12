/// One retained Adhkar conflict as the owner sees it (contracts/
/// adhkar-qiyam-ui.md): both stored versions of one item's day, with no
/// resolution action anywhere.
final class AdhkarConflictEvidence {
  const AdhkarConflictEvidence({
    required this.id,
    required this.adhkarDay,
    required this.itemId,
    required this.activeCount,
    required this.retainedCount,
    required this.activeAt,
    required this.retainedAt,
  });

  final String id;
  final String adhkarDay;
  final String itemId;
  final int activeCount;
  final int retainedCount;
  final DateTime activeAt;
  final DateTime retainedAt;
}
