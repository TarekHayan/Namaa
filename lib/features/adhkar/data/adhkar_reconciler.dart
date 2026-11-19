import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';

import '../application/adhkar_repository.dart';
import 'drift_adhkar_repository.dart';
import 'supabase_adhkar_reader.dart';

final class AdhkarReconciliationSummary {
  const AdhkarReconciliationSummary({
    required this.importedCounts,
    required this.importedConflicts,
    required this.importedAwards,
  });

  final int importedCounts;
  final int importedConflicts;
  final int importedAwards;
}

/// Applies a complete owner snapshot atomically (the Prayer reconciler's
/// contract). Pending local descendants survive; their own RPC receipt
/// resolves a stale base on the server.
final class AdhkarReconciler {
  const AdhkarReconciler({
    required DriftAdhkarRepository repository,
    required LocalStorePort localStore,
    required SharedAwardLedgerPort awards,
  }) : _repository = repository,
       _localStore = localStore,
       _awards = awards;

  final DriftAdhkarRepository _repository;
  final LocalStorePort _localStore;
  final SharedAwardLedgerPort _awards;

  Future<AppResult<AdhkarReconciliationSummary>> reconcile({
    required String accountId,
    required AdhkarRemoteSnapshot remote,
    bool Function()? isCurrentScope,
  }) async {
    bool current() => isCurrentScope?.call() ?? true;
    if (!current()) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    if (remote.counts.any((row) => row.accountId != accountId) ||
        remote.awards.any((row) => row.accountId != accountId) ||
        remote.conflicts.any(
          (row) =>
              row.active.accountId != accountId ||
              row.retained.accountId != accountId,
        )) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    return _repository.runInTransaction(() async {
      final pendingResult = await _localStore.readPendingChanges(accountId);
      if (!current()) {
        return AppResult.failure(_failure(AppFailureCategory.authorization));
      }
      if (pendingResult.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      final pendingIds = {
        for (final row in pendingResult.valueOrNull!)
          if (row.entityType == kAdhkarItemEntityType) row.entityId,
      };
      var importedCounts = 0;
      var importedConflicts = 0;
      var importedAwards = 0;
      for (final award in remote.awards) {
        if (!current()) {
          return AppResult.failure(_failure(AppFailureCategory.authorization));
        }
        final applied = await _awards.applyRemoteSharedAward(award);
        if (applied.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        importedAwards++;
      }
      for (final conflict in remote.conflicts) {
        if (!current()) {
          return AppResult.failure(_failure(AppFailureCategory.authorization));
        }
        final applied = await _repository.applyRemoteConflict(
          conflict,
          accountId: accountId,
        );
        if (applied.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        importedConflicts++;
      }
      for (final count in remote.counts) {
        if (!current()) {
          return AppResult.failure(_failure(AppFailureCategory.authorization));
        }
        if (pendingIds.contains(count.recordId)) continue;
        final read = await _repository.readFresh(
          accountId: accountId,
          adhkarDay: count.adhkarDay,
          itemId: count.itemId,
        );
        if (read.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        final local = read.valueOrNull;
        if (local != null && local.recordId != count.recordId) {
          return AppResult.failure(_failure(AppFailureCategory.persistence));
        }
        // A page read can finish after a newer receipt was committed locally;
        // the next full pass imports the current server state.
        if (local?.lastAcknowledgedUpdatedAt case final acknowledged?) {
          if (acknowledged.isAfter(count.updatedAt)) continue;
        }
        final same = local != null && _sameSemantic(local, count);
        if (same && local.lastAcknowledgedUpdatedAt == count.updatedAt) {
          continue;
        }
        final applied = await _repository.writeCount(
          AdhkarCountRecord(
            accountId: accountId,
            adhkarDay: count.adhkarDay,
            itemId: count.itemId,
            recordId: count.recordId,
            catalogVersion: count.catalogVersion,
            list: count.list,
            count: count.count,
            createdAt: count.createdAt,
            updatedAt: count.updatedAt,
            lastAcknowledgedUpdatedAt: count.updatedAt,
          ),
          operationId: 'inbound:${count.recordId}',
          queueForSync: false,
          hadPrior: local != null,
        );
        if (applied.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        importedCounts++;
      }
      if (!current()) {
        return AppResult.failure(_failure(AppFailureCategory.authorization));
      }
      return AppResult.success(
        AdhkarReconciliationSummary(
          importedCounts: importedCounts,
          importedConflicts: importedConflicts,
          importedAwards: importedAwards,
        ),
      );
    });
  }

  bool _sameSemantic(AdhkarCountRecord a, AdhkarCountRecord b) =>
      a.recordId == b.recordId &&
      a.adhkarDay == b.adhkarDay &&
      a.itemId == b.itemId &&
      a.catalogVersion == b.catalogVersion &&
      a.list == b.list &&
      a.count == b.count &&
      a.createdAt == b.createdAt &&
      a.updatedAt == b.updatedAt;

  AppFailure _failure(AppFailureCategory category) => AppFailure.recoverable(
    category: category,
    messageKey: 'adhkar.sync.failed',
    occurredAt: DateTime.now().toUtc(),
  );
}
