import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';

import '../domain/prayer_report.dart';
import 'drift_prayer_repository.dart';
import 'supabase_prayer_reader.dart';

final class PrayerReconciliationSummary {
  const PrayerReconciliationSummary({
    required this.importedReports,
    required this.importedConflicts,
    required this.importedAwards,
  });
  final int importedReports;
  final int importedConflicts;
  final int importedAwards;
}

/// Applies a complete owner snapshot atomically. Pending local descendants
/// survive; their own RPC receipt will resolve a stale base on the server.
final class PrayerReconciler {
  const PrayerReconciler({
    required DriftPrayerRepository repository,
    required LocalStorePort localStore,
    required SharedAwardLedgerPort awards,
  }) : _repository = repository,
       _localStore = localStore,
       _awards = awards;

  final DriftPrayerRepository _repository;
  final LocalStorePort _localStore;
  final SharedAwardLedgerPort _awards;

  Future<AppResult<PrayerReconciliationSummary>> reconcile({
    required String accountId,
    required PrayerRemoteSnapshot remote,
    bool Function()? isCurrentScope,
  }) async {
    bool current() => isCurrentScope?.call() ?? true;
    if (!current()) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    if (remote.reports.any((row) => row.accountId != accountId) ||
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
          if (row.entityType == kPrayerReportEntityType) row.entityId,
      };
      var importedReports = 0;
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
      final awardIds = remote.awards.map((award) => award.sourceId).toSet();
      final localRead = await _repository.readAllForOwner(accountId);
      if (localRead.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      // Keyed by the owner/day/prayer slot so an identity mismatch in the
      // same slot is still detected, as the per-row read did before.
      final locals = {
        for (final row in localRead.valueOrNull!)
          '${row.date.value}/${row.name.name}': row,
      };
      for (final report in remote.reports) {
        if (!current()) {
          return AppResult.failure(_failure(AppFailureCategory.authorization));
        }
        final local = locals['${report.date.value}/${report.name.name}'];
        if (local != null && local.reportId != report.reportId) {
          return AppResult.failure(_failure(AppFailureCategory.persistence));
        }
        if (pendingIds.contains(report.reportId)) continue;
        // A page read can finish after a newer receipt was committed locally.
        // The next full pass will import the current server state.
        if (local?.lastAcknowledgedUpdatedAt case final acknowledged?) {
          if (acknowledged.isAfter(report.updatedAt)) continue;
        }
        final same = local != null && _sameSemantic(local, report);
        if (same &&
            local.lastAcknowledgedUpdatedAt == report.updatedAt &&
            (!awardIds.contains(report.reportId) ||
                local.canonicalRewardConfirmedAt != null)) {
          continue;
        }
        final inbound = PrayerReport(
          accountId: accountId,
          reportId: report.reportId,
          date: report.date,
          name: report.name,
          status: report.status,
          reportedCompletionAt: report.reportedCompletionAt,
          recordedZoneId: report.recordedZoneId,
          recordedOffsetMinutes: report.recordedOffsetMinutes,
          createdAt: report.createdAt,
          updatedAt: report.updatedAt,
          lastAcknowledgedUpdatedAt: report.updatedAt,
          canonicalRewardConfirmedAt: awardIds.contains(report.reportId)
              ? local?.canonicalRewardConfirmedAt ?? DateTime.now().toUtc()
              : local?.canonicalRewardConfirmedAt,
        );
        final applied = await _repository.applyInbound(inbound);
        if (applied.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        importedReports++;
      }
      if (!current()) {
        return AppResult.failure(_failure(AppFailureCategory.authorization));
      }
      return AppResult.success(
        PrayerReconciliationSummary(
          importedReports: importedReports,
          importedConflicts: importedConflicts,
          importedAwards: importedAwards,
        ),
      );
    });
  }

  bool _sameSemantic(PrayerReport a, PrayerReport b) =>
      a.reportId == b.reportId &&
      a.status == b.status &&
      a.reportedCompletionAt == b.reportedCompletionAt &&
      a.recordedZoneId == b.recordedZoneId &&
      a.recordedOffsetMinutes == b.recordedOffsetMinutes &&
      a.createdAt == b.createdAt &&
      a.updatedAt == b.updatedAt;

  AppFailure _failure(AppFailureCategory category) => AppFailure.recoverable(
    category: category,
    messageKey: 'prayer.sync.failed',
    occurredAt: DateTime.now().toUtc(),
  );
}
