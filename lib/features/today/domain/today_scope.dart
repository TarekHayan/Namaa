/// In-memory owner binding for one Today view.
library;

enum TodayScopeMode { preview, account }

final class TodayScope {
  TodayScope._({
    required this.mode,
    required this.scopeKey,
    required this.taskOwnerId,
    required this.habitOwnerId,
    required this.prayerOwnerId,
    required this.xpOwnerId,
    required this.generation,
  }) {
    if (generation < 0 ||
        scopeKey.trim().isEmpty ||
        taskOwnerId.trim().isEmpty ||
        habitOwnerId.trim().isEmpty ||
        prayerOwnerId.trim().isEmpty ||
        xpOwnerId.trim().isEmpty) {
      throw ArgumentError('Today scope requires valid identity and generation');
    }
    if (xpOwnerId != taskOwnerId ||
        (mode == TodayScopeMode.account &&
            (habitOwnerId != taskOwnerId || prayerOwnerId != taskOwnerId)) ||
        (mode == TodayScopeMode.preview &&
            (habitOwnerId == taskOwnerId ||
                prayerOwnerId == taskOwnerId ||
                prayerOwnerId == habitOwnerId))) {
      throw ArgumentError('Today owner bindings do not match the scope mode');
    }
  }

  /// Composition supplies the three distinct preview identities.
  factory TodayScope.preview({
    required String taskOwnerId,
    required String habitOwnerId,
    String? prayerOwnerId,
    required int generation,
  }) {
    if (taskOwnerId == habitOwnerId) {
      throw ArgumentError('Preview owner IDs must remain distinct');
    }
    final resolvedPrayerOwnerId =
        prayerOwnerId ?? '$taskOwnerId:prayer-preview';
    return TodayScope._(
      mode: TodayScopeMode.preview,
      scopeKey: 'preview',
      taskOwnerId: taskOwnerId,
      habitOwnerId: habitOwnerId,
      prayerOwnerId: resolvedPrayerOwnerId,
      xpOwnerId: taskOwnerId,
      generation: generation,
    );
  }

  /// One resolved real account owns every source.
  factory TodayScope.account({
    required String accountId,
    required int generation,
  }) => TodayScope._(
    mode: TodayScopeMode.account,
    scopeKey: 'account:$accountId',
    taskOwnerId: accountId,
    habitOwnerId: accountId,
    prayerOwnerId: accountId,
    xpOwnerId: accountId,
    generation: generation,
  );

  final TodayScopeMode mode;
  final String scopeKey;
  final String taskOwnerId;
  final String habitOwnerId;
  final String prayerOwnerId;
  final String xpOwnerId;
  final int generation;

  bool get isPreview => mode == TodayScopeMode.preview;
}
