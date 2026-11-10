import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../application/adhkar_repository.dart';
import 'uuid_adhkar_identity.dart';

/// Drift-backed Adhkar count store on the encrypted database (schema v10).
/// Reads and writes are owner-scoped; the sync payload carries the typed
/// fields the 0016 RPC expects (without owner or record id, which the server
/// recomputes).
final class DriftAdhkarRepository implements AdhkarRepository {
  DriftAdhkarRepository(this._database, {required UuidAdhkarIdentity identity})
    : _identity = identity;

  final FoundationDatabase _database;
  final UuidAdhkarIdentity _identity;

  @override
  Future<AppResult<AdhkarCountRecord?>> readFresh({
    required String accountId,
    required String adhkarDay,
    required String itemId,
  }) async {
    try {
      final row =
          await (_database.select(_database.adhkarItemCounts)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.adhkarDay.equals(adhkarDay) &
                    table.itemId.equals(itemId),
              ))
              .getSingleOrNull();
      return AppResult.success(row == null ? null : _decode(row));
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Stream<List<AdhkarCountRecord>> watchDay({
    required String accountId,
    required String adhkarDay,
  }) =>
      (_database.select(_database.adhkarItemCounts)
            ..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.adhkarDay.equals(adhkarDay),
            )
            ..orderBy([(table) => OrderingTerm.asc(table.itemId)]))
          .watch()
          .map(
            (rows) => List<AdhkarCountRecord>.unmodifiable(rows.map(_decode)),
          );

  @override
  Future<AppResult<List<AdhkarCountRecord>>> readListCounts({
    required String accountId,
    required String adhkarDay,
    required String list,
  }) async {
    try {
      final rows =
          await (_database.select(_database.adhkarItemCounts)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.adhkarDay.equals(adhkarDay) &
                    table.list.equals(list),
              ))
              .get();
      return AppResult.success(
        List<AdhkarCountRecord>.unmodifiable(rows.map(_decode)),
      );
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<void>> writeCount(
    AdhkarCountRecord record, {
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
          throw StateError('Duplicate adhkar operation');
        }
      }
      await _database
          .into(_database.adhkarItemCounts)
          .insertOnConflictUpdate(
            AdhkarItemCountsCompanion.insert(
              accountId: record.accountId,
              adhkarDay: record.adhkarDay,
              itemId: record.itemId,
              recordId: record.recordId,
              catalogVersion: record.catalogVersion,
              list: record.list,
              count: record.count,
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
                entityType: 'adhkar_item',
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
  Future<AppResult<Set<String>>> fullyCompletedDays({
    required String accountId,
    required String lastDay,
    required int maxLookBackDays,
  }) async {
    try {
      final awards =
          await (_database.select(_database.xpAwards)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.source.equals(kAdhkarSetDoneAwardSource),
              ))
              .get();
      final known = awards.map((row) => row.sourceId).toSet();
      final completed = <String>{};
      var day = _parseDay(lastDay);
      for (var visited = 0; visited < maxLookBackDays; visited++) {
        final key = _key(day);
        final morning = _identity.setAwardSourceId(key, 'morning');
        final evening = _identity.setAwardSourceId(key, 'evening');
        if (known.contains(morning) && known.contains(evening)) {
          completed.add(key);
        }
        day = day.subtract(const Duration(days: 1));
      }
      return AppResult.success(completed);
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

  Map<String, Object?> _payload(AdhkarCountRecord record) => {
    'adhkar_day': record.adhkarDay,
    'item_id': record.itemId,
    'catalog_version': record.catalogVersion,
    'count': record.count,
    'updated_at': record.updatedAt.toIso8601String(),
    'base_updated_at': record.lastAcknowledgedUpdatedAt?.toIso8601String(),
  };

  AdhkarCountRecord _decode(AdhkarItemCount row) => AdhkarCountRecord(
    accountId: row.accountId,
    adhkarDay: row.adhkarDay,
    itemId: row.itemId,
    recordId: row.recordId,
    catalogVersion: row.catalogVersion,
    list: row.list,
    count: row.count,
    createdAt: DateTime.parse(row.createdAt),
    updatedAt: DateTime.parse(row.updatedAt),
    lastAcknowledgedUpdatedAt: row.lastAcknowledgedUpdatedAt == null
        ? null
        : DateTime.parse(row.lastAcknowledgedUpdatedAt!),
  );

  static AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: 'adhkar.count.store_failed',
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}

final class _TransactionFailure implements Exception {
  const _TransactionFailure(this.failure);
  final AppFailure failure;
}

DateTime _parseDay(String value) => DateTime.utc(
  int.parse(value.substring(0, 4)),
  int.parse(value.substring(5, 7)),
  int.parse(value.substring(8, 10)),
);

String _key(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
