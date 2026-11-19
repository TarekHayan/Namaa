import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';

import '../domain/qiyam_night_record.dart';
import 'drift_qiyam_repository.dart';
import 'supabase_qiyam_reader.dart';

final class QiyamReconciliationSummary {
  const QiyamReconciliationSummary({
    required this.importedNights,
    required this.importedConflicts,
    required this.importedAwards,
  });

  final int importedNights;
  final int importedConflicts;
  final int importedAwards;
}

/// Applies a complete owner snapshot atomically. Pending local descendants
/// survive; their own RPC receipt resolves a stale base on the server.
final class QiyamReconciler {
  const QiyamReconciler({
    required DriftQiyamRepository repository,
    required LocalStorePort localStore,
    required SharedAwardLedgerPort awards,
  }) : _repository = repository,
       _localStore = localStore,
       _awards = awards;

  final DriftQiyamRepository _repository;
  final LocalStorePort _localStore;
  final SharedAwardLedgerPort _awards;

  Future<AppResult<QiyamReconciliationSummary>> reconcile({
    required String accountId,
    required QiyamRemoteSnapshot remote,
    bool Function()? isCurrentScope,
  }) async {
    bool current() => isCurrentScope?.call() ?? true;
    if (!current()) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    if (remote.nights.any((row) => row.accountId != accountId) ||
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
          if (row.entityType == kQiyamNightEntityType) row.entityId,
      };
      var importedNights = 0;
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
      for (final night in remote.nights) {
        if (!current()) {
          return AppResult.failure(_failure(AppFailureCategory.authorization));
        }
        if (pendingIds.contains(night.recordId)) continue;
        final read = await _repository.readFresh(
          accountId: accountId,
          nightDate: night.nightDate,
        );
        if (read.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        final local = read.valueOrNull;
        if (local != null && local.recordId != night.recordId) {
          return AppResult.failure(_failure(AppFailureCategory.persistence));
        }
        // A page read can finish after a newer receipt was committed locally;
        // the next full pass imports the current server state.
        if (local?.lastAcknowledgedUpdatedAt case final acknowledged?) {
          if (acknowledged.isAfter(night.updatedAt)) continue;
        }
        final same = local != null && _sameSemantic(local, night);
        if (same && local.lastAcknowledgedUpdatedAt == night.updatedAt) {
          continue;
        }
        final applied = await _repository.writeNight(
          QiyamNightRecord(
            accountId: accountId,
            nightDate: night.nightDate,
            recordId: night.recordId,
            performed: night.performed,
            rakahs: night.rakahs,
            witr: night.witr,
            startTime: night.startTime,
            endTime: night.endTime,
            note: night.note,
            recordedZoneId: night.recordedZoneId,
            recordedOffsetMinutes: night.recordedOffsetMinutes,
            createdAt: night.createdAt,
            updatedAt: night.updatedAt,
            lastAcknowledgedUpdatedAt: night.updatedAt,
          ),
          operationId: 'inbound:${night.recordId}',
          queueForSync: false,
          hadPrior: local != null,
        );
        if (applied.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        importedNights++;
      }
      if (!current()) {
        return AppResult.failure(_failure(AppFailureCategory.authorization));
      }
      return AppResult.success(
        QiyamReconciliationSummary(
          importedNights: importedNights,
          importedConflicts: importedConflicts,
          importedAwards: importedAwards,
        ),
      );
    });
  }

  bool _sameSemantic(QiyamNightRecord a, QiyamNightRecord b) =>
      a.recordId == b.recordId &&
      a.nightDate == b.nightDate &&
      a.performed == b.performed &&
      a.rakahs == b.rakahs &&
      a.witr == b.witr &&
      a.startTime == b.startTime &&
      a.endTime == b.endTime &&
      a.note == b.note &&
      a.recordedZoneId == b.recordedZoneId &&
      a.recordedOffsetMinutes == b.recordedOffsetMinutes &&
      a.createdAt == b.createdAt &&
      a.updatedAt == b.updatedAt;

  AppFailure _failure(AppFailureCategory category) => AppFailure.recoverable(
    category: category,
    messageKey: 'qiyam.sync.failed',
    occurredAt: DateTime.now().toUtc(),
  );
}
