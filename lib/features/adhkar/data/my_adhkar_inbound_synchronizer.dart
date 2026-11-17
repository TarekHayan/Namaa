import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../application/my_adhkar_inbound_sync_port.dart';
import 'my_adhkar_reconciler.dart';
import 'supabase_my_adhkar_reader.dart';

/// The My Adhkar inbound pass: pages the owner's snapshot (keyset pages,
/// restarted from the first key on every pass) and hands it to the
/// reconciler, mirroring `AdhkarInboundSynchronizer`. A failed page, a
/// foreign owner or a stale scope fails the whole pass and applies nothing.
final class MyAdhkarInboundSynchronizer implements MyAdhkarInboundSyncPort {
  const MyAdhkarInboundSynchronizer({
    required MyAdhkarRemoteReader reader,
    required MyAdhkarReconciler reconciler,
  }) : _reader = reader,
       _reconciler = reconciler;

  final MyAdhkarRemoteReader _reader;
  final MyAdhkarReconciler _reconciler;

  @override
  Future<AppResult<MyAdhkarInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  }) async {
    if (!isCurrentScope()) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    late final MyAdhkarRemoteSnapshot remote;
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
      MyAdhkarInboundSummary(
        importedGroups: summary.importedGroups,
        importedItems: summary.importedItems,
        importedConflicts: summary.importedConflicts,
      ),
    );
  }

  static AppFailure _failure(AppFailureCategory category) =>
      AppFailure.recoverable(
        category: category,
        messageKey: 'my_adhkar.sync.failed',
        occurredAt: DateTime.now().toUtc(),
      );
}
