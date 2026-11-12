import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../application/qiyam_repository.dart';
import '../domain/qiyam_night_record.dart';
import '../domain/qiyam_streak.dart';

/// Drift-backed Qiyam night store on the encrypted database (schema v10).
/// Reads and writes are owner-scoped; the sync payload carries the typed
/// fields the 0016 RPC expects (without owner or record id, which the server
/// recomputes).
final class DriftQiyamRepository implements QiyamRepository {
  DriftQiyamRepository(this._database);

  /// The number of recorded rows one streak read fetches per indexed range
  /// read before serving the walk from memory.
  static const int _streakBatchSize = 60;

  final FoundationDatabase _database;

  @override
  Future<AppResult<QiyamNightRecord?>> readFresh({
    required String accountId,
    required String nightDate,
  }) async {
    try {
      final row =
          await (_database.select(_database.qiyamNights)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.nightDate.equals(nightDate),
              ))
              .getSingleOrNull();
      return AppResult.success(row == null ? null : _decode(row));
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Stream<QiyamNightRecord?> watchNight({
    required String accountId,
    required String nightDate,
  }) =>
      (_database.select(_database.qiyamNights)..where(
            (table) =>
                table.accountId.equals(accountId) &
                table.nightDate.equals(nightDate),
          ))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _decode(row));

  @override
  Future<AppResult<int>> streak({
    required String accountId,
    required String currentNight,
  }) async {
    try {
      // Descending batches of recorded rows served to the walk from memory:
      // the walk keeps its early exit at the first breaking night and the
      // 3,650-night cap, and a long streak costs a handful of indexed range
      // reads instead of one query per night (Phase 5 review finding 3).
      final buffer = <String, QiyamNightVerdict>{};
      String? oldestFetched;
      var exhausted = false;
      final streak = await qiyamStreak(
        currentNight: currentNight,
        verdictOf: (nightDate) async {
          if (!buffer.containsKey(nightDate) && !exhausted) {
            // A local copy: Dart does not promote a closure-captured
            // variable, so `oldestFetched != null` alone would not hold.
            final oldest = oldestFetched;
            final insideCoveredRange =
                oldest != null && nightDate.compareTo(oldest) >= 0;
            if (!insideCoveredRange) {
              final rows =
                  await (_database.select(_database.qiyamNights)
                        ..where(
                          (table) =>
                              table.accountId.equals(accountId) &
                              table.nightDate.isSmallerOrEqualValue(nightDate),
                        )
                        ..orderBy([
                          (table) => OrderingTerm.desc(table.nightDate),
                        ])
                        ..limit(_streakBatchSize))
                      .get();
              if (rows.length < _streakBatchSize) {
                exhausted = true;
              }
              for (final row in rows) {
                buffer[row.nightDate] = row.performed
                    ? QiyamNightVerdict.performed
                    : QiyamNightVerdict.notPerformed;
              }
              oldestFetched = rows.isEmpty ? nightDate : rows.last.nightDate;
            }
          }
          return buffer[nightDate];
        },
      );
      return AppResult.success(streak);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<QiyamHistoryPage>> history({
    required String accountId,
    required String before,
    int limit = 30,
  }) async {
    try {
      if (limit < 1) {
        throw ArgumentError.value(limit, 'limit');
      }
      // Validates the bound format; a malformed one is a failure.
      _parseDay(before);
      // Keyset paging over RECORDED rows (Phase 5 review finding 1): 30
      // rows per page, newest first, one indexed range read; the extra row
      // tells whether an older row exists. A stretch of unrecorded nights
      // never hides the rows behind it.
      final rows =
          await (_database.select(_database.qiyamNights)
                ..where(
                  (table) =>
                      table.accountId.equals(accountId) &
                      table.nightDate.isSmallerThanValue(before),
                )
                ..orderBy([(table) => OrderingTerm.desc(table.nightDate)])
                ..limit(limit + 1))
              .get();
      final hasMore = rows.length > limit;
      final page = hasMore ? rows.sublist(0, limit) : rows;
      return AppResult.success(
        QiyamHistoryPage(
          records: [for (final row in page) _decode(row)],
          hasMore: hasMore,
        ),
      );
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<void>> writeNight(
    QiyamNightRecord record, {
    required String operationId,
    required bool queueForSync,
    required bool hadPrior,
  }) async {
    try {
      if (queueForSync) {
        final existing =
            await (_database.select(_database.pendingChanges)
                  ..where((table) => table.operationId.equals(operationId)))
                .getSingleOrNull();
        if (existing != null) {
          throw StateError('Duplicate qiyam operation');
        }
      }
      await _database
          .into(_database.qiyamNights)
          .insertOnConflictUpdate(
            QiyamNightsCompanion.insert(
              accountId: record.accountId,
              nightDate: record.nightDate,
              recordId: record.recordId,
              performed: record.performed,
              rakahs: Value(record.rakahs),
              witr: record.witr,
              startTime: Value(record.startTime),
              endTime: Value(record.endTime),
              note: Value(record.note),
              recordedZoneId: record.recordedZoneId,
              recordedOffsetMinutes: record.recordedOffsetMinutes,
              createdAt: record.createdAt.toIso8601String(),
              updatedAt: record.updatedAt.toIso8601String(),
              lastAcknowledgedUpdatedAt: Value(
                record.lastAcknowledgedUpdatedAt?.toIso8601String(),
              ),
            ),
          );
      if (queueForSync) {
        await _database
            .into(_database.pendingChanges)
            .insert(
              PendingChangesCompanion.insert(
                operationId: operationId,
                accountId: record.accountId,
                entityType: 'qiyam_night',
                entityId: record.recordId,
                kind: hadPrior ? ChangeKind.update : ChangeKind.create,
                state: PendingChangeState.pending,
                serializedChange: jsonEncode(_payload(record)),
                createdAt: record.updatedAt,
                versionTimestamp: record.updatedAt,
                baseUpdatedAt: Value(record.lastAcknowledgedUpdatedAt),
              ),
            );
      }
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

  Map<String, Object?> _payload(QiyamNightRecord record) => {
    'night_date': record.nightDate,
    'performed': record.performed,
    'rakahs': record.rakahs,
    'witr': record.witr,
    'start_time': record.startTime,
    'end_time': record.endTime,
    'note': record.note,
    'recorded_zone_id': record.recordedZoneId,
    'recorded_offset_minutes': record.recordedOffsetMinutes,
    'updated_at': record.updatedAt.toIso8601String(),
    'base_updated_at': record.lastAcknowledgedUpdatedAt?.toIso8601String(),
  };

  QiyamNightRecord _decode(QiyamNight row) => QiyamNightRecord(
    accountId: row.accountId,
    nightDate: row.nightDate,
    recordId: row.recordId,
    performed: row.performed,
    rakahs: row.rakahs,
    witr: row.witr,
    startTime: row.startTime,
    endTime: row.endTime,
    note: row.note,
    recordedZoneId: row.recordedZoneId,
    recordedOffsetMinutes: row.recordedOffsetMinutes,
    createdAt: DateTime.parse(row.createdAt),
    updatedAt: DateTime.parse(row.updatedAt),
    lastAcknowledgedUpdatedAt: row.lastAcknowledgedUpdatedAt == null
        ? null
        : DateTime.parse(row.lastAcknowledgedUpdatedAt!),
  );

  static DateTime _parseDay(String value) => DateTime.utc(
    int.parse(value.substring(0, 4)),
    int.parse(value.substring(5, 7)),
    int.parse(value.substring(8, 10)),
  );

  static AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: 'qiyam.night.store_failed',
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}

final class _TransactionFailure implements Exception {
  const _TransactionFailure(this.failure);
  final AppFailure failure;
}
