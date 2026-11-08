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
import 'package:namma_project/core/domain/values/version_source.dart';

import '../application/prayer_conflict_reader.dart';
import '../application/prayer_repository.dart';
import '../domain/prayer_conflict_evidence.dart';
import '../domain/prayer_local_date.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_report.dart';
import '../domain/prayer_status.dart';
import 'prayer_payload_codec.dart';
import 'prayer_remote_models.dart';

/// Owner/day indexed encrypted report store. Commands compose its transaction
/// with the shared award ledger in the next story.
final class DriftPrayerRepository
    implements PrayerRepository, PrayerConflictReader {
  DriftPrayerRepository(this._database);

  final FoundationDatabase _database;
  final PrayerPayloadCodec _codec = const PrayerPayloadCodec();

  @override
  Stream<List<PrayerConflictEvidence>> watchConflicts(String accountId) =>
      (_database.select(_database.conflictRecords)
            ..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.entityType.equals('prayer_report'),
            )
            ..orderBy([(table) => OrderingTerm.desc(table.detectedAt)]))
          .watch()
          .map(
            (rows) => List.unmodifiable(
              rows.map((row) {
                final active =
                    jsonDecode(row.activePayload) as Map<String, dynamic>;
                final retained =
                    jsonDecode(row.retainedPayload) as Map<String, dynamic>;
                return PrayerConflictEvidence(
                  id: row.conflictId,
                  date: PrayerLocalDate.parse(active['localDate'] as String),
                  name: PrayerNameWire.parse(active['prayerName'] as String),
                  activeStatus: PrayerStatusWire.parse(
                    active['status'] as String,
                  ),
                  retainedStatus: PrayerStatusWire.parse(
                    retained['status'] as String,
                  ),
                  activeAt: row.activeTimestamp.toUtc(),
                  retainedAt: row.retainedTimestamp.toUtc(),
                );
              }),
            ),
          );

  /// Returns the stable creation instant for an outbox snapshot. The local
  /// row can have newer edits, but creation never changes for this identity.
  Future<AppResult<DateTime>> createdAtFor({
    required String accountId,
    required PrayerLocalDate date,
    required PrayerName prayerName,
    required String reportId,
  }) async {
    final result = await readFresh(
      accountId: accountId,
      date: date,
      prayerName: prayerName,
    );
    if (result.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final row = result.valueOrNull;
    if (row == null || row.reportId != reportId) {
      return AppResult.failure(
        _failure(const FormatException('Prayer outbox report missing')),
      );
    }
    return AppResult.success(row.createdAt);
  }

  /// Commit the server receipt before the generic outbox ACK. A retry of a
  /// lost ACK is safe; a later local edit cannot be overwritten by this one.
  Future<AppResult<void>> finalizeReceipt({
    required String accountId,
    required String reportId,
    required DateTime outboundVersion,
    required PrayerDispatchReceipt receipt,
  }) async {
    try {
      if (receipt.active.accountId != accountId ||
          receipt.active.reportId != reportId ||
          (receipt.award != null &&
              (receipt.award!.accountId != accountId ||
                  receipt.award!.sourceId != reportId))) {
        throw const FormatException('Foreign Prayer receipt');
      }
      await _database.transaction(() async {
        final read = await readFresh(
          accountId: accountId,
          date: receipt.active.date,
          prayerName: receipt.active.name,
        );
        if (read.failureOrNull != null) {
          throw StateError('Prayer local read failed');
        }
        final current = read.valueOrNull;
        if (current == null || current.reportId != reportId) {
          throw StateError('Prayer receipt has no local report');
        }
        if (receipt.award case final award?) {
          await _database
              .into(_database.xpAwards)
              .insertOnConflictUpdate(
                XpAwardsCompanion.insert(
                  accountId: award.accountId,
                  source: award.source,
                  sourceId: award.sourceId,
                  amount: award.amount,
                  awardedAt: award.awardedAt,
                ),
              );
        }
        if (receipt.conflict case final conflict?) {
          await _insertConflict(conflict, accountId);
        }
        final canReplace = current.updatedAt == outboundVersion;
        final newerAck =
            current.lastAcknowledgedUpdatedAt != null &&
            current.lastAcknowledgedUpdatedAt!.isAfter(
              receipt.active.updatedAt,
            );
        if (canReplace && !newerAck) {
          await _upsert(
            PrayerReport(
              accountId: accountId,
              reportId: reportId,
              date: receipt.active.date,
              name: receipt.active.name,
              status: receipt.active.status,
              reportedCompletionAt: receipt.active.reportedCompletionAt,
              recordedZoneId: receipt.active.recordedZoneId,
              recordedOffsetMinutes: receipt.active.recordedOffsetMinutes,
              createdAt: receipt.active.createdAt,
              updatedAt: receipt.active.updatedAt,
              lastAcknowledgedUpdatedAt: receipt.active.updatedAt,
              canonicalRewardConfirmedAt: receipt.award == null
                  ? current.canonicalRewardConfirmedAt
                  : current.canonicalRewardConfirmedAt ??
                        DateTime.now().toUtc(),
            ),
          );
        } else if (!newerAck) {
          await (_database.update(_database.prayerReports)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.reportId.equals(reportId),
              ))
              .write(
                PrayerReportsCompanion(
                  lastAcknowledgedUpdatedAt: Value(
                    receipt.active.updatedAt.toIso8601String(),
                  ),
                  canonicalRewardConfirmedAt: receipt.award == null
                      ? const Value.absent()
                      : Value(
                          (current.canonicalRewardConfirmedAt ??
                                  DateTime.now().toUtc())
                              .toIso8601String(),
                        ),
                ),
              );
        }
      });
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  Future<void> _insertConflict(
    PrayerRemoteConflict conflict,
    String owner,
  ) async {
    if (conflict.active.accountId != owner ||
        conflict.retained.accountId != owner ||
        conflict.active.reportId != conflict.retained.reportId) {
      throw const FormatException('Foreign Prayer conflict');
    }
    await _database
        .into(_database.conflictRecords)
        .insert(
          ConflictRecordsCompanion.insert(
            conflictId: conflict.id,
            accountId: owner,
            entityType: 'prayer_report',
            entityId: conflict.active.reportId,
            activeSource: VersionSource.remote,
            activeTimestamp: conflict.active.updatedAt,
            activePayload: PrayerRemoteModels.payload(conflict.active),
            retainedSource: VersionSource.remote,
            retainedTimestamp: conflict.retained.updatedAt,
            retainedPayload: PrayerRemoteModels.payload(conflict.retained),
            detectedAt: conflict.detectedAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<AppResult<void>> applyRemoteConflict(
    PrayerRemoteConflict conflict, {
    required String accountId,
  }) async {
    try {
      await _insertConflict(conflict, accountId);
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

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

  /// Every local report of one owner, read in one query so a full inbound
  /// pass does not issue one SELECT per remote row.
  Future<AppResult<List<PrayerReport>>> readAllForOwner(
    String accountId,
  ) async {
    try {
      final rows = await (_database.select(
        _database.prayerReports,
      )..where((table) => table.accountId.equals(accountId))).get();
      return AppResult.success(List.unmodifiable(rows.map(_decode)));
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
    required DateTime? expectedCurrentVersion,
    bool queueForSync = true,
  }) async {
    try {
      await _database.transaction(() async {
        final prior = (await readFresh(
          accountId: report.accountId,
          date: report.date,
          prayerName: report.name,
        )).valueOrNull;
        if (operationId.trim().isEmpty ||
            prior?.updatedAt != expectedCurrentVersion ||
            acknowledgedBase != prior?.lastAcknowledgedUpdatedAt ||
            (prior != null && !report.updatedAt.isAfter(prior.updatedAt)) ||
            (prior != null && prior.reportId != report.reportId)) {
          throw StateError('Invalid prayer report transition');
        }
        if (queueForSync) {
          final existingOperation =
              await (_database.select(_database.pendingChanges)
                    ..where((table) => table.operationId.equals(operationId)))
                  .getSingleOrNull();
          if (existingOperation != null) {
            throw StateError('Duplicate prayer operation');
          }
        }
        await _upsert(report);
        if (queueForSync) {
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
        }
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
