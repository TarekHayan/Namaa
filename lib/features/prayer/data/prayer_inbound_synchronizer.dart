import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../application/prayer_inbound_sync_port.dart';
import 'prayer_reconciler.dart';
import 'supabase_prayer_reader.dart';

final class PrayerInboundSynchronizer implements PrayerInboundSyncPort {
  const PrayerInboundSynchronizer({
    required PrayerRemoteReader reader,
    required PrayerReconciler reconciler,
  }) : _reader = reader,
       _reconciler = reconciler;

  final PrayerRemoteReader _reader;
  final PrayerReconciler _reconciler;

  @override
  Future<AppResult<PrayerInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  }) async {
    if (!isCurrentScope()) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    late final PrayerRemoteSnapshot remote;
    try {
      remote = await _reader.readAll(accountId);
    } catch (_) {
      return AppResult.failure(_failure(AppFailureCategory.cloud));
    }
    if (!isCurrentScope()) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    final result = await _reconciler.reconcile(
      accountId: accountId,
      remote: remote,
      isCurrentScope: isCurrentScope,
    );
    if (result.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final summary = result.valueOrNull!;
    return AppResult.success(
      PrayerInboundSummary(
        importedReports: summary.importedReports,
        importedConflicts: summary.importedConflicts,
        importedAwards: summary.importedAwards,
      ),
    );
  }

  static AppFailure _failure(AppFailureCategory category) =>
      AppFailure.recoverable(
        category: category,
        messageKey: 'prayer.sync.failed',
        occurredAt: DateTime.now().toUtc(),
      );
}
