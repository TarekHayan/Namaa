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
    this.list,
  });

  final String id;
  final String adhkarDay;
  final String itemId;

  /// The list the item belongs to, from the stored conflict payload; null
  /// only for evidence written before the list was stored.
  final String? list;
  final int activeCount;
  final int retainedCount;
  final DateTime activeAt;
  final DateTime retainedAt;
}
