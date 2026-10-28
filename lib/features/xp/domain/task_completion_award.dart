/// Immutable XP evidence for the first explicit completion of one Task.
library;

const String kTaskDoneAwardSource = 'task_done';

/// XP for the first completion of any Task. The server applies the same value
/// (`apply_task_change` in supabase/migrations/0011); the client never chooses
/// it, so offline and synchronized totals always agree.
const int kTaskCompletionXp = 20;

final class TaskCompletionAward {
  TaskCompletionAward({
    required this.accountId,
    required this.source,
    required this.sourceId,
    required this.amount,
    required this.awardedAt,
  }) {
    if (accountId.trim().isEmpty) {
      throw ArgumentError.value(accountId, 'accountId', 'must not be blank');
    }
    if (source != kTaskDoneAwardSource) {
      throw ArgumentError.value(
        source,
        'source',
        'must identify a Task completion award',
      );
    }
    if (sourceId.trim().isEmpty) {
      throw ArgumentError.value(sourceId, 'sourceId', 'must not be blank');
    }
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be negative');
    }
    if (!awardedAt.isUtc) {
      throw ArgumentError.value(awardedAt, 'awardedAt', 'must be UTC');
    }
  }

  final String accountId;
  final String source;
  final String sourceId;
  final int amount;
  final DateTime awardedAt;

  String get uniqueKey => '$accountId/$source/$sourceId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCompletionAward &&
          other.accountId == accountId &&
          other.source == source &&
          other.sourceId == sourceId &&
          other.amount == amount &&
          other.awardedAt == awardedAt;

  @override
  int get hashCode =>
      Object.hash(accountId, source, sourceId, amount, awardedAt);

  @override
  String toString() =>
      'TaskCompletionAward(accountId: $accountId, source: $source, '
      'sourceId: $sourceId, amount: $amount, awardedAt: $awardedAt)';
}
