import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';

import '../application/adhkar_conflict_reader.dart';
import '../application/adhkar_repository.dart';
import '../domain/adhkar_conflict_evidence.dart';
import 'adhkar_remote_models.dart';

/// Drift-backed Adhkar count store on the encrypted database (schema v10).
/// Reads and writes are owner-scoped; the sync payload carries the typed
/// fields the 0016 RPC expects (without owner or record id, which the server
/// recomputes).
final class DriftAdhkarRepository
    implements AdhkarRepository, AdhkarConflictReader {
  DriftAdhkarRepository(this._database);

  final FoundationDatabase _database;

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
  Future<AppResult<AdhkarCompletedDays>> fullyCompletedDays({
    required String accountId,
    required String lastDay,
    required int maxLookBackDays,
    required int catalogVersion,
    required List<AdhkarListItem> morningItems,
    required List<AdhkarListItem> eveningItems,
  }) async {
    try {
      final firstDay = _parseDay(
        lastDay,
      ).subtract(Duration(days: maxLookBackDays - 1));
      // One indexed range read over (account_id, adhkar_day, ...).
      final rows =
          await (_database.select(_database.adhkarItemCounts)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.adhkarDay.isBetweenValues(_key(firstDay), lastDay),
              ))
              .get();
      final byDay = <String, List<AdhkarItemCount>>{};
      for (final row in rows) {
        byDay.putIfAbsent(row.adhkarDay, () => []).add(row);
      }
      final completed = <String>{};
      final unjudgeable = <String>{};
      var day = _parseDay(lastDay);
      for (var visited = 0; visited < maxLookBackDays; visited++) {
        final key = _key(day);
        final dayRows = byDay[key] ?? const <AdhkarItemCount>[];
        final judgeable = dayRows.every(
          (row) => row.catalogVersion == catalogVersion,
        );
        final complete =
            judgeable &&
            _listComplete(dayRows, morningItems) &&
            _listComplete(dayRows, eveningItems);
        if (complete) {
          completed.add(key);
        } else if (!judgeable) {
          unjudgeable.add(key);
        }
        // Early exit: today (the first visited day) may be incomplete
        // without breaking the run; any later incomplete or unjudgeable day
        // ends the walk.
        if (visited > 0 && !complete) {
          break;
        }
        day = day.subtract(const Duration(days: 1));
      }
      return AppResult.success(
        AdhkarCompletedDays(completed: completed, unjudgeable: unjudgeable),
      );
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  bool _listComplete(
    List<AdhkarItemCount> dayRows,
    List<AdhkarListItem> items,
  ) {
    final counts = {for (final row in dayRows) row.itemId: row.count};
    return items.every((item) => (counts[item.itemId] ?? 0) >= item.target);
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

  @override
  Stream<List<AdhkarConflictEvidence>> watchConflicts(String accountId) =>
      (_database.select(_database.conflictRecords)
            ..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.entityType.equals('adhkar_item'),
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
                return AdhkarConflictEvidence(
                  id: row.conflictId,
                  adhkarDay: active['adhkar_day'] as String,
                  itemId: active['item_id'] as String,
                  list: active['list'] as String?,
                  activeCount: active['count'] as int,
                  retainedCount: retained['count'] as int,
                  activeAt: row.activeTimestamp.toUtc(),
                  retainedAt: row.retainedTimestamp.toUtc(),
                );
              }),
            ),
          );

  /// Local dispatch finalization (contracts/adhkar-qiyam-sync.md), in ONE
  /// transaction before the coordinator acknowledges: settle the canonical
  /// set award — replacing the provisional replica once, by (source,
  /// sourceId) — upsert the conflict evidence by its stable id, and apply
  /// the server's active record only when no newer local work is pending or
  /// acknowledged. Any failure rolls everything back and the operation
  /// stays pending.
  Future<AppResult<void>> finalizeReceipt({
    required String accountId,
    required String adhkarDay,
    required String itemId,
    required DateTime outboundVersion,
    required AdhkarDispatchReceipt receipt,
  }) async {
    try {
      if (receipt.active.accountId != accountId ||
          receipt.active.adhkarDay != adhkarDay ||
          receipt.active.itemId != itemId) {
        throw const FormatException('Foreign Adhkar receipt');
      }
      await _database.transaction(() async {
        final read = await readFresh(
          accountId: accountId,
          adhkarDay: adhkarDay,
          itemId: itemId,
        );
        if (read.failureOrNull != null) {
          throw StateError('Adhkar local read failed');
        }
        final current = read.valueOrNull;
        if (current == null || current.recordId != receipt.active.recordId) {
          throw StateError('Adhkar receipt has no local record');
        }
        if (receipt.award case final award?) {
          if (award.accountId != accountId) {
            throw const FormatException('Foreign Adhkar award');
          }
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
          await _database
              .into(_database.adhkarItemCounts)
              .insertOnConflictUpdate(
                AdhkarItemCountsCompanion.insert(
                  accountId: receipt.active.accountId,
                  adhkarDay: receipt.active.adhkarDay,
                  itemId: receipt.active.itemId,
                  recordId: receipt.active.recordId,
                  catalogVersion: receipt.active.catalogVersion,
                  list: receipt.active.list,
                  count: receipt.active.count,
                  createdAt: receipt.active.createdAt.toIso8601String(),
                  updatedAt: receipt.active.updatedAt.toIso8601String(),
                  lastAcknowledgedUpdatedAt: Value(
                    receipt.active.updatedAt.toIso8601String(),
                  ),
                ),
              );
        } else if (!newerAck) {
          await (_database.update(_database.adhkarItemCounts)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.recordId.equals(receipt.active.recordId),
              ))
              .write(
                AdhkarItemCountsCompanion(
                  lastAcknowledgedUpdatedAt: Value(
                    receipt.active.updatedAt.toIso8601String(),
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

  /// Upserts one remote conflict's evidence by its stable id; repeated
  /// detection reuses the row (read-only evidence, never a resolution).
  Future<AppResult<void>> applyRemoteConflict(
    AdhkarRemoteConflict conflict, {
    required String accountId,
  }) async {
    try {
      await _insertConflict(conflict, accountId);
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  Future<void> _insertConflict(
    AdhkarRemoteConflict conflict,
    String owner,
  ) async {
    if (conflict.active.accountId != owner ||
        conflict.retained.accountId != owner ||
        conflict.active.recordId != conflict.retained.recordId) {
      throw const FormatException('Foreign Adhkar conflict');
    }
    await _database
        .into(_database.conflictRecords)
        .insert(
          ConflictRecordsCompanion.insert(
            conflictId: conflict.id,
            accountId: owner,
            entityType: 'adhkar_item',
            entityId: conflict.active.recordId,
            activeSource: VersionSource.remote,
            activeTimestamp: conflict.active.updatedAt,
            activePayload: AdhkarRemoteModels.conflictPayload(conflict.active),
            retainedSource: VersionSource.remote,
            retainedTimestamp: conflict.retained.updatedAt,
            retainedPayload: AdhkarRemoteModels.conflictPayload(
              conflict.retained,
            ),
            detectedAt: conflict.detectedAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }
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
