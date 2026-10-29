import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide PrayerReport;
import 'package:namma_project/core/data/local/foundation_database.dart'
    as local
    show PrayerReport;
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../application/prayer_repository.dart';
import '../domain/prayer_local_date.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_report.dart';
import '../domain/prayer_status.dart';
import 'prayer_payload_codec.dart';

/// Owner/day indexed encrypted report store. Commands compose its transaction
/// with the shared award ledger in the next story.
final class DriftPrayerRepository implements PrayerRepository {
  DriftPrayerRepository(this._database);

  final FoundationDatabase _database;
  final PrayerPayloadCodec _codec = const PrayerPayloadCodec();

  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) async {
    try {
      return await _database.transaction(() async {
        final result = await action();
        if (result.failureOrNull case final failure?) {
          throw _TransactionFailure(failure);
        }
        return result;
      });
    } on _TransactionFailure catch (error) {
      return AppResult.failure(error.failure);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<PrayerReport?>> readFresh({
    required String accountId,
    required PrayerLocalDate date,
    required PrayerName prayerName,
  }) async {
    try {
      final row =
          await (_database.select(_database.prayerReports)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.localDate.equals(date.value) &
                    table.prayerName.equals(prayerName.wireName),
              ))
              .getSingleOrNull();
      return AppResult.success(row == null ? null : _decode(row));
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Stream<List<PrayerReport>> watchDay({
    required String accountId,
    required PrayerLocalDate date,
  }) =>
      (_database.select(_database.prayerReports)
            ..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.localDate.equals(date.value),
            )
            ..orderBy([(table) => OrderingTerm.asc(table.prayerName)]))
          .watch()
          .map((rows) => List<PrayerReport>.unmodifiable(rows.map(_decode)));

  @override
  Future<AppResult<void>> writeLocal(
    PrayerReport report, {
    required String operationId,
    required DateTime? acknowledgedBase,
  }) async {
    try {
      await _database.transaction(() async {
        final prior = (await readFresh(
          accountId: report.accountId,
          date: report.date,
          prayerName: report.name,
        )).valueOrNull;
        if (operationId.trim().isEmpty ||
            acknowledgedBase != prior?.lastAcknowledgedUpdatedAt ||
            (prior != null && !report.updatedAt.isAfter(prior.updatedAt)) ||
            (prior != null && prior.reportId != report.reportId)) {
          throw StateError('Invalid prayer report transition');
        }
        final existingOperation =
            await (_database.select(_database.pendingChanges)
                  ..where((table) => table.operationId.equals(operationId)))
                .getSingleOrNull();
        if (existingOperation != null) {
          throw StateError('Duplicate prayer operation');
        }
        await _upsert(report);
        await _database
            .into(_database.pendingChanges)
            .insert(
              PendingChangesCompanion.insert(
                operationId: operationId,
                accountId: report.accountId,
                entityType: 'prayer_report',
                entityId: report.reportId,
                kind: prior == null ? ChangeKind.create : ChangeKind.update,
                state: PendingChangeState.pending,
                serializedChange: jsonEncode(_codec.encode(report)),
                createdAt: report.updatedAt,
                versionTimestamp: report.updatedAt,
                baseUpdatedAt: Value(acknowledgedBase),
              ),
            );
      });
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<void>> applyInbound(PrayerReport report) async {
    try {
      await _upsert(report);
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  Future<void> _upsert(PrayerReport report) => _database
      .into(_database.prayerReports)
      .insertOnConflictUpdate(
        PrayerReportsCompanion.insert(
          accountId: report.accountId,
          localDate: report.date.value,
          prayerName: report.name.wireName,
          reportId: report.reportId,
          status: report.status.wireName,
          reportedCompletionAt: Value(
            report.reportedCompletionAt?.toIso8601String(),
          ),
          recordedZoneId: report.recordedZoneId,
          recordedOffsetMinutes: report.recordedOffsetMinutes,
          createdAt: report.createdAt.toIso8601String(),
          updatedAt: report.updatedAt.toIso8601String(),
          lastAcknowledgedUpdatedAt: Value(
            report.lastAcknowledgedUpdatedAt?.toIso8601String(),
          ),
          canonicalRewardConfirmedAt: Value(
            report.canonicalRewardConfirmedAt?.toIso8601String(),
          ),
        ),
      )
      .then((_) {});

  PrayerReport _decode(local.PrayerReport row) => PrayerReport(
    accountId: row.accountId,
    reportId: row.reportId,
    date: PrayerLocalDate.parse(row.localDate),
    name: PrayerNameWire.parse(row.prayerName),
    status: PrayerStatusWire.parse(row.status),
    reportedCompletionAt: row.reportedCompletionAt == null
        ? null
        : DateTime.parse(row.reportedCompletionAt!).toUtc(),
    recordedZoneId: row.recordedZoneId,
    recordedOffsetMinutes: row.recordedOffsetMinutes,
    createdAt: DateTime.parse(row.createdAt).toUtc(),
    updatedAt: DateTime.parse(row.updatedAt).toUtc(),
    lastAcknowledgedUpdatedAt: row.lastAcknowledgedUpdatedAt == null
        ? null
        : DateTime.parse(row.lastAcknowledgedUpdatedAt!).toUtc(),
    canonicalRewardConfirmedAt: row.canonicalRewardConfirmedAt == null
        ? null
        : DateTime.parse(row.canonicalRewardConfirmedAt!).toUtc(),
  );

  AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: kDatabaseUnreadableMessageKey,
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}

final class _TransactionFailure implements Exception {
  const _TransactionFailure(this.failure);
  final AppFailure failure;
}
