import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../application/adhkar_inbound_sync_port.dart';
import 'adhkar_reconciler.dart';
import 'supabase_adhkar_reader.dart';

final class AdhkarInboundSynchronizer implements AdhkarInboundSyncPort {
  const AdhkarInboundSynchronizer({
    required AdhkarRemoteReader reader,
    required AdhkarReconciler reconciler,
  }) : _reader = reader,
       _reconciler = reconciler;

  final AdhkarRemoteReader _reader;
  final AdhkarReconciler _reconciler;

  @override
  Future<AppResult<AdhkarInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  }) async {
    if (!isCurrentScope()) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    late final AdhkarRemoteSnapshot remote;
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
      AdhkarInboundSummary(
        importedCounts: summary.importedCounts,
        importedConflicts: summary.importedConflicts,
        importedAwards: summary.importedAwards,
      ),
    );
  }

  static AppFailure _failure(AppFailureCategory category) =>
      AppFailure.recoverable(
        category: category,
        messageKey: 'adhkar.sync.failed',
        occurredAt: DateTime.now().toUtc(),
      );
}
