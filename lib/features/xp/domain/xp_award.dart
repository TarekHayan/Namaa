const String kPrayerDoneAwardSource = 'prayer_done';

/// Canonical shared XP evidence for one first completion.
final class XpAward {
  XpAward({
    required this.accountId,
    required this.source,
    required this.sourceId,
    required this.amount,
    required this.awardedAt,
  }) {
    if (accountId.trim().isEmpty ||
        sourceId.trim().isEmpty ||
        !awardedAt.isUtc ||
        !((source == 'task_done' && amount == 20) ||
            (source == kPrayerDoneAwardSource &&
                (amount == 5 || amount == 10)))) {
      throw ArgumentError('Invalid XP award');
    }
  }

  /// Read-only compatibility for awards already stored by older app versions.
  XpAward.fromStored({
    required this.accountId,
    required this.source,
    required this.sourceId,
    required this.amount,
    required this.awardedAt,
  }) {
    if (accountId.trim().isEmpty ||
        sourceId.trim().isEmpty ||
        !awardedAt.isUtc ||
        amount < 0 ||
        (source != 'task_done' &&
            source != 'task_completion' &&
            source != kPrayerDoneAwardSource)) {
      throw ArgumentError('Invalid stored XP award');
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
      other is XpAward &&
      other.accountId == accountId &&
      other.source == source &&
      other.sourceId == sourceId &&
      other.amount == amount &&
      other.awardedAt == awardedAt;

  @override
  int get hashCode =>
      Object.hash(accountId, source, sourceId, amount, awardedAt);
}
