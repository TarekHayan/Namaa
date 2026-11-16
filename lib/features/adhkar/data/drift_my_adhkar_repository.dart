import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

/// The Drift My Adhkar store (data-model.md "My Adhkar"): item rows,
/// per-day count rows and the outbox entries (`my_adhkar_item` /
/// `my_adhkar_count`) written in one transaction each. There is no XP
/// write anywhere in this store (FR-026).
final class DriftMyAdhkarRepository implements MyAdhkarRepository {
  DriftMyAdhkarRepository(this._database);

  static const String _itemEntityType = 'my_adhkar_item';
  static const String _countEntityType = 'my_adhkar_count';

  final FoundationDatabase _database;

  @override
  Stream<List<MyDhikrItem>> watchItems(String accountId) =>
      (_database.select(_database.myAdhkarItems)
            ..where(
              (table) =>
                  table.accountId.equals(accountId) & table.deletedAt.isNull(),
            )
            ..orderBy([
              (table) => OrderingTerm.asc(table.createdAt),
              (table) => OrderingTerm.asc(table.itemId),
            ]))
          .watch()
          .map((rows) => List<MyDhikrItem>.unmodifiable(rows.map(_decodeItem)));

  @override
  Stream<List<MyAdhkarCountRecord>> watchCounts({
    required String accountId,
    required String adhkarDay,
  }) =>
      (_database.select(_database.myAdhkarCounts)
            ..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.adhkarDay.equals(adhkarDay),
            )
            ..orderBy([(table) => OrderingTerm.asc(table.itemId)]))
          .watch()
          .map(
            (rows) =>
                List<MyAdhkarCountRecord>.unmodifiable(rows.map(_decodeCount)),
          );

  @override
  Future<AppResult<MyDhikrItem?>> readFresh({
    required String accountId,
    required String itemId,
  }) async {
    try {
      final row =
          await (_database.select(_database.myAdhkarItems)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.itemId.equals(itemId),
              ))
              .getSingleOrNull();
      return AppResult.success(row == null ? null : _decodeItem(row));
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.item.store_failed'));
    }
  }

  @override
  Future<AppResult<MyAdhkarCountRecord?>> readCountFresh({
    required String accountId,
    required String itemId,
    required String adhkarDay,
  }) async {
    try {
      final row =
          await (_database.select(_database.myAdhkarCounts)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.itemId.equals(itemId) &
                    table.adhkarDay.equals(adhkarDay),
              ))
              .getSingleOrNull();
      return AppResult.success(row == null ? null : _decodeCount(row));
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.count.store_failed'));
    }
  }

  @override
  Future<AppResult<int>> liveItemCount({required String accountId}) async {
    try {
      final row = await _database
          .customSelect(
            'SELECT COUNT(*) AS c FROM my_adhkar_items '
            'WHERE account_id = ? AND deleted_at IS NULL',
            variables: [Variable.withString(accountId)],
          )
          .getSingle();
      return AppResult.success(row.data['c'] as int);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.item.store_failed'));
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
      return AppResult.failure(_failure(error, 'my_adhkar.item.store_failed'));
    }
  }

  @override
  Future<AppResult<void>> insertItem(
    MyDhikrItem item, {
    required String operationId,
    required bool queueForSync,
  }) async {
    try {
      if (queueForSync) {
        await _requireNewOperation(operationId);
      }
      await _database
          .into(_database.myAdhkarItems)
          .insertOnConflictUpdate(
            MyAdhkarItemsCompanion.insert(
              accountId: item.accountId,
              itemId: item.itemId,
              content: item.text,
              target: item.target,
              note: Value(item.note),
              createdAt: item.createdAt.toIso8601String(),
              updatedAt: item.updatedAt.toIso8601String(),
              lastAcknowledgedUpdatedAt: Value(
                item.lastAcknowledgedUpdatedAt?.toIso8601String(),
              ),
              deletedAt: Value(item.deletedAt?.toIso8601String()),
            ),
          );
      if (queueForSync) {
        await _appendItemOutbox(item, operationId, ChangeKind.create);
      }
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.item.save_failed'));
    }
  }

  @override
  Future<AppResult<void>> updateItem(
    MyDhikrItem item, {
    required String operationId,
    required bool queueForSync,
  }) async {
    try {
      if (queueForSync) {
        await _requireNewOperation(operationId);
      }
      final updated =
          await (_database.update(_database.myAdhkarItems)..where(
                (table) =>
                    table.accountId.equals(item.accountId) &
                    table.itemId.equals(item.itemId),
              ))
              .write(
                MyAdhkarItemsCompanion(
                  content: Value(item.text),
                  target: Value(item.target),
                  note: Value(item.note),
                  updatedAt: Value(item.updatedAt.toIso8601String()),
                  lastAcknowledgedUpdatedAt: Value(
                    item.lastAcknowledgedUpdatedAt?.toIso8601String(),
                  ),
                ),
              );
      if (updated == 0) {
        throw StateError('My Adhkar item to update is missing');
      }
      if (queueForSync) {
        await _appendItemOutbox(item, operationId, ChangeKind.update);
      }
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.item.save_failed'));
    }
  }

  @override
  Future<AppResult<void>> markDeleted({
    required String accountId,
    required String itemId,
    required DateTime deletedAt,
    required DateTime updatedAt,
    required String operationId,
    required bool queueForSync,
  }) async {
    try {
      if (queueForSync) {
        await _requireNewOperation(operationId);
      }
      final prior =
          await (_database.select(_database.myAdhkarItems)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.itemId.equals(itemId),
              ))
              .getSingleOrNull();
      if (prior == null) {
        throw StateError('My Adhkar item to delete is missing');
      }
      if (prior.deletedAt != null) {
        // Already deleted: the tombstone is set once and never cleared or
        // moved (data-model.md, Delete command).
        return const AppResult.success(null);
      }
      final updated =
          await (_database.update(_database.myAdhkarItems)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.itemId.equals(itemId) &
                    table.deletedAt.isNull(),
              ))
              .write(
                MyAdhkarItemsCompanion(
                  updatedAt: Value(updatedAt.toIso8601String()),
                  deletedAt: Value(deletedAt.toIso8601String()),
                ),
              );
      if (updated == 0) {
        throw StateError('My Adhkar delete raced another writer');
      }
      if (queueForSync) {
        await _appendItemOutbox(
          _decodeItem(prior).copyWith(updatedAt: updatedAt),
          operationId,
          ChangeKind.update,
          deletedAtOverride: deletedAt,
        );
      }
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.item.save_failed'));
    }
  }

  @override
  Future<AppResult<MyAdhkarCountCommitOutcome>> commitCount(
    MyAdhkarCountCommitRequest request,
  ) async {
    try {
      final outcome = await _database.transaction(() async {
        final prior = (await readCountFresh(
          accountId: request.accountId,
          itemId: request.itemId,
          adhkarDay: request.adhkarDay,
        )).valueOrNull;
        if (request.expectedCurrentVersion != prior?.updatedAt ||
            request.acknowledgedBase != prior?.lastAcknowledgedUpdatedAt ||
            (prior != null && !request.updatedAt.isAfter(prior.updatedAt))) {
          throw _TransactionFailure(
            AppFailure.recoverable(
              category: AppFailureCategory.validation,
              messageKey: 'my_adhkar.count.stale_count',
              occurredAt: request.updatedAt,
            ),
          );
        }
        if (prior != null && prior.count == request.newCount) {
          return MyAdhkarCountCommitOutcome(
            wroteCount: false,
            newCount: prior.count,
          );
        }
        if (request.queueForSync) {
          await _requireNewOperation(request.operationId);
        }
        await _database
            .into(_database.myAdhkarCounts)
            .insertOnConflictUpdate(
              MyAdhkarCountsCompanion.insert(
                accountId: request.accountId,
                itemId: request.itemId,
                adhkarDay: request.adhkarDay,
                recordId: request.recordId,
                count: request.newCount,
                createdAt: (prior?.createdAt ?? request.createdAt)
                    .toIso8601String(),
                updatedAt: request.updatedAt.toIso8601String(),
                lastAcknowledgedUpdatedAt: Value(
                  prior?.lastAcknowledgedUpdatedAt?.toIso8601String(),
                ),
              ),
            );
        if (request.queueForSync) {
          await _database
              .into(_database.pendingChanges)
              .insert(
                PendingChangesCompanion.insert(
                  operationId: request.operationId,
                  accountId: request.accountId,
                  entityType: _countEntityType,
                  entityId: request.recordId,
                  kind: request.hadPrior
                      ? ChangeKind.update
                      : ChangeKind.create,
                  state: PendingChangeState.pending,
                  serializedChange: jsonEncode({
                    'item_id': request.itemId,
                    'adhkar_day': request.adhkarDay,
                    'record_id': request.recordId,
                    'count': request.newCount,
                    'created_at': (prior?.createdAt ?? request.createdAt)
                        .toIso8601String(),
                    'updated_at': request.updatedAt.toIso8601String(),
                    'base_updated_at': prior?.lastAcknowledgedUpdatedAt
                        ?.toIso8601String(),
                  }),
                  createdAt: request.updatedAt,
                  versionTimestamp: request.updatedAt,
                  baseUpdatedAt: Value(prior?.lastAcknowledgedUpdatedAt),
                ),
              );
        }
        return MyAdhkarCountCommitOutcome(
          wroteCount: true,
          newCount: request.newCount,
        );
      });
      return AppResult.success(outcome);
    } on _TransactionFailure catch (error) {
      return AppResult.failure(error.failure);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.count.save_failed'));
    }
  }

  Future<void> _requireNewOperation(String operationId) async {
    final existing =
        await (_database.select(_database.pendingChanges)
              ..where((table) => table.operationId.equals(operationId)))
            .getSingleOrNull();
    if (existing != null) {
      throw StateError('Duplicate my_adhkar operation');
    }
  }

  Future<void> _appendItemOutbox(
    MyDhikrItem item,
    String operationId,
    ChangeKind kind, {
    DateTime? deletedAtOverride,
  }) => _database
      .into(_database.pendingChanges)
      .insert(
        PendingChangesCompanion.insert(
          operationId: operationId,
          accountId: item.accountId,
          entityType: _itemEntityType,
          entityId: item.itemId,
          kind: kind,
          state: PendingChangeState.pending,
          serializedChange: jsonEncode({
            'item_id': item.itemId,
            'text': item.text,
            'target': item.target,
            'note': item.note,
            'created_at': item.createdAt.toIso8601String(),
            'updated_at': item.updatedAt.toIso8601String(),
            'deleted_at': (deletedAtOverride ?? item.deletedAt)
                ?.toIso8601String(),
            'base_updated_at': item.lastAcknowledgedUpdatedAt
                ?.toIso8601String(),
          }),
          createdAt: item.updatedAt,
          versionTimestamp: item.updatedAt,
          baseUpdatedAt: Value(item.lastAcknowledgedUpdatedAt),
        ),
      );

  MyDhikrItem _decodeItem(MyAdhkarItem row) => MyDhikrItem(
    accountId: row.accountId,
    itemId: row.itemId,
    text: row.content,
    target: row.target,
    note: row.note,
    createdAt: DateTime.parse(row.createdAt),
    updatedAt: DateTime.parse(row.updatedAt),
    lastAcknowledgedUpdatedAt: row.lastAcknowledgedUpdatedAt == null
        ? null
        : DateTime.parse(row.lastAcknowledgedUpdatedAt!),
    deletedAt: row.deletedAt == null ? null : DateTime.parse(row.deletedAt!),
  );

  MyAdhkarCountRecord _decodeCount(MyAdhkarCount row) => MyAdhkarCountRecord(
    accountId: row.accountId,
    itemId: row.itemId,
    adhkarDay: row.adhkarDay,
    recordId: row.recordId,
    count: row.count,
    createdAt: DateTime.parse(row.createdAt),
    updatedAt: DateTime.parse(row.updatedAt),
    lastAcknowledgedUpdatedAt: row.lastAcknowledgedUpdatedAt == null
        ? null
        : DateTime.parse(row.lastAcknowledgedUpdatedAt!),
  );

  static AppFailure _failure(Object error, String messageKey) =>
      AppFailure.recoverable(
        category: AppFailureCategory.persistence,
        messageKey: messageKey,
        occurredAt: DateTime.now().toUtc(),
        technicalCause: error.runtimeType.toString(),
      );
}

final class _TransactionFailure implements Exception {
  const _TransactionFailure(this.failure);
  final AppFailure failure;
}
