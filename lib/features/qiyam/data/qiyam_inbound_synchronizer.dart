import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../application/qiyam_inbound_sync_port.dart';
import 'qiyam_reconciler.dart';
import 'supabase_qiyam_reader.dart';

final class QiyamInboundSynchronizer implements QiyamInboundSyncPort {
  const QiyamInboundSynchronizer({
    required QiyamRemoteReader reader,
    required QiyamReconciler reconciler,
  }) : _reader = reader,
       _reconciler = reconciler;

  final QiyamRemoteReader _reader;
  final QiyamReconciler _reconciler;

  @override
  Future<AppResult<QiyamInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  }) async {
    if (!isCurrentScope()) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    late final QiyamRemoteSnapshot remote;
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
      QiyamInboundSummary(
        importedNights: summary.importedNights,
        importedConflicts: summary.importedConflicts,
        importedAwards: summary.importedAwards,
      ),
    );
  }

  static AppFailure _failure(AppFailureCategory category) =>
      AppFailure.recoverable(
        category: category,
        messageKey: 'qiyam.sync.failed',
        occurredAt: DateTime.now().toUtc(),
      );
}
