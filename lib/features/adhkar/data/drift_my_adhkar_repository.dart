import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/my_adhkar_remote_models.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

/// The Drift My Adhkar store (data-model.md "My Adhkar", reshaped
/// 2026-11-16): groups, entries (text + optional source) and their
/// membership join, with the outbox entries (`my_adhkar_group` /
/// `my_adhkar_item`). There is no counter, count table or Adhkar-day
/// dependency, and no XP write anywhere (FR-026). Every statement binds its
/// inputs as parameters; the mutation primitives are called inside
/// [runInTransaction], which gives them one transaction.
final class DriftMyAdhkarRepository implements MyAdhkarRepository {
  DriftMyAdhkarRepository(this._database);

  static const String _itemEntityType = 'my_adhkar_item';
  static const String _groupEntityType = 'my_adhkar_group';

  final FoundationDatabase _database;

  // -- Groups ---------------------------------------------------------------

  @override
  Stream<List<MyAdhkarGroupSummary>> watchGroups(String accountId) => _database
      .customSelect(
        'SELECT g.group_id, g.name, g.created_at, g.updated_at, '
        'g.last_acknowledged_updated_at, g.deleted_at, '
        '(SELECT COUNT(*) FROM my_adhkar_item_groups mig '
        'JOIN my_adhkar_items mi ON mi.account_id = mig.account_id '
        'AND mi.item_id = mig.item_id AND mi.deleted_at IS NULL '
        'WHERE mig.account_id = g.account_id '
        'AND mig.group_id = g.group_id) AS entry_count '
        'FROM my_adhkar_groups g '
        'WHERE g.account_id = ? AND g.deleted_at IS NULL '
        'ORDER BY g.created_at, g.group_id',
        variables: [Variable.withString(accountId)],
        readsFrom: {
          _database.myAdhkarGroups,
          _database.myAdhkarItems,
          _database.myAdhkarItemGroups,
        },
      )
      .watch()
      .map(
        (rows) => List<MyAdhkarGroupSummary>.unmodifiable(
          rows.map(
            (row) => MyAdhkarGroupSummary(
              group: _decodeGroup(
                accountId: accountId,
                groupId: row.read<String>('group_id'),
                name: row.read<String>('name'),
                createdAt: row.read<String>('created_at'),
                updatedAt: row.read<String>('updated_at'),
                lastAcknowledgedUpdatedAt: row.readNullable<String>(
                  'last_acknowledged_updated_at',
                ),
                deletedAt: row.readNullable<String>('deleted_at'),
              ),
              liveEntryCount: row.read<int>('entry_count'),
            ),
          ),
        ),
      );

  @override
  Stream<List<MyDhikrItem>> watchGroupItems({
    required String accountId,
    required String groupId,
  }) =>
      (_database.select(_database.myAdhkarItems).join([
              innerJoin(
                _database.myAdhkarItemGroups,
                _database.myAdhkarItemGroups.accountId.equalsExp(
                      _database.myAdhkarItems.accountId,
                    ) &
                    _database.myAdhkarItemGroups.itemId.equalsExp(
                      _database.myAdhkarItems.itemId,
                    ),
              ),
            ])
            ..where(
              _database.myAdhkarItems.accountId.equals(accountId) &
                  _database.myAdhkarItemGroups.groupId.equals(groupId) &
                  _database.myAdhkarItems.deletedAt.isNull(),
            )
            ..orderBy([
              OrderingTerm.asc(_database.myAdhkarItemGroups.addedAt),
              OrderingTerm.asc(_database.myAdhkarItems.itemId),
            ]))
          .watch()
          .map(
            (rows) => List<MyDhikrItem>.unmodifiable(
              rows.map(
                (row) => _decodeItemRow(
                  row.readTable(_database.myAdhkarItems),
                  groupIds: [groupId],
                ),
              ),
            ),
          );

  @override
  Future<AppResult<MyAdhkarGroup?>> readGroupFresh({
    required String accountId,
    required String groupId,
  }) async {
    try {
      final row =
          await (_database.select(_database.myAdhkarGroups)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.groupId.equals(groupId),
              ))
              .getSingleOrNull();
      return AppResult.success(row == null ? null : _decodeGroupRow(row));
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.group.store_failed'));
    }
  }

  @override
  Future<AppResult<int>> liveGroupCount({required String accountId}) async {
    try {
      final row = await _database
          .customSelect(
            'SELECT COUNT(*) AS c FROM my_adhkar_groups '
            'WHERE account_id = ? AND deleted_at IS NULL',
            variables: [Variable.withString(accountId)],
          )
          .getSingle();
      return AppResult.success(row.data['c'] as int);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.group.store_failed'));
    }
  }

  @override
  Future<AppResult<void>> insertGroup(
    MyAdhkarGroup group, {
    required String operationId,
    required bool queueForSync,
  }) async {
    try {
      if (queueForSync) {
        await _requireNewOperation(operationId);
      }
      await _database
          .into(_database.myAdhkarGroups)
          .insertOnConflictUpdate(
            MyAdhkarGroupsCompanion.insert(
              accountId: group.accountId,
              groupId: group.groupId,
              name: group.name,
              createdAt: group.createdAt.toIso8601String(),
              updatedAt: group.updatedAt.toIso8601String(),
              lastAcknowledgedUpdatedAt: Value(
                group.lastAcknowledgedUpdatedAt?.toIso8601String(),
              ),
              deletedAt: Value(group.deletedAt?.toIso8601String()),
            ),
          );
      if (queueForSync) {
        await _appendGroupOutbox(group, operationId, ChangeKind.create);
      }
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.group.save_failed'));
    }
  }

  @override
  Future<AppResult<void>> renameGroup(
    MyAdhkarGroup renamed, {
    required DateTime priorUpdatedAt,
    required String operationId,
    required bool queueForSync,
  }) async {
    try {
      if (queueForSync) {
        await _requireNewOperation(operationId);
      }
      final updated = await _database.customUpdate(
        'UPDATE my_adhkar_groups SET name = ?, updated_at = ?, '
        'last_acknowledged_updated_at = ? '
        'WHERE account_id = ? AND group_id = ? '
        'AND deleted_at IS NULL AND updated_at = ?',
        variables: [
          Variable.withString(renamed.name),
          Variable.withString(renamed.updatedAt.toIso8601String()),
          Variable(renamed.lastAcknowledgedUpdatedAt?.toIso8601String()),
          Variable.withString(renamed.accountId),
          Variable.withString(renamed.groupId),
          Variable.withString(priorUpdatedAt.toIso8601String()),
        ],
      );
      if (updated == 0) {
        throw StateError(
          'My Adhkar group rename raced a delete or another writer',
        );
      }
      if (queueForSync) {
        await _appendGroupOutbox(renamed, operationId, ChangeKind.update);
      }
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.group.save_failed'));
    }
  }

  @override
  Future<AppResult<int>> deleteGroupCascade({
    required String accountId,
    required String groupId,
    required DateTime deletedAt,
    required String operationId,
    required bool queueForSync,
  }) async {
    try {
      if (queueForSync) {
        await _requireNewOperation(operationId);
      }
      final groupRow =
          await (_database.select(_database.myAdhkarGroups)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.groupId.equals(groupId),
              ))
              .getSingleOrNull();
      if (groupRow == null) {
        throw StateError('My Adhkar group to delete is missing');
      }
      if (groupRow.deletedAt != null) {
        // Already deleted: the tombstone is set once and never moved, so
        // this is the no-op path.
        return const AppResult.success(0);
      }
      // The live entries that currently sit in this group.
      final memberRows =
          await (_database.select(_database.myAdhkarItemGroups)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.groupId.equals(groupId),
              ))
              .get();
      final cascadedIds = <String>[];
      for (final row in memberRows) {
        final entryRow =
            await (_database.select(_database.myAdhkarItems)..where(
                  (table) =>
                      table.accountId.equals(accountId) &
                      table.itemId.equals(row.itemId) &
                      table.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        if (entryRow == null) continue;
        final otherMemberships =
            await (_database.select(_database.myAdhkarItemGroups)..where(
                  (table) =>
                      table.accountId.equals(accountId) &
                      table.itemId.equals(row.itemId) &
                      table.groupId.equals(groupId).not(),
                ))
                .get();
        final hasOtherLiveGroup = await _hasLiveGroup(
          accountId,
          otherMemberships.map((row) => row.groupId).toList(),
        );
        if (!hasOtherLiveGroup) {
          cascadedIds.add(row.itemId);
        }
      }
      // 1. The group's tombstone with a monotonic updated_at
      // (max(now, prior + 1 microsecond)), the same rule as
      // markItemDeleted — a skewed clock never moves the version backwards.
      final groupMonotonic = _maxInstant(deletedAt, _after(groupRow.updatedAt));
      final groupUpdated =
          await (_database.update(_database.myAdhkarGroups)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.groupId.equals(groupId) &
                    table.deletedAt.isNull(),
              ))
              .write(
                MyAdhkarGroupsCompanion(
                  updatedAt: Value(groupMonotonic.toIso8601String()),
                  deletedAt: Value(deletedAt.toIso8601String()),
                ),
              );
      if (groupUpdated == 0) {
        throw StateError('My Adhkar group delete raced another writer');
      }
      // 2. Remove this group's memberships.
      await (_database.delete(_database.myAdhkarItemGroups)..where(
            (table) =>
                table.accountId.equals(accountId) &
                table.groupId.equals(groupId),
          ))
          .go();
      // 3. Tombstone the entries left with no live group, each with a
      // monotonic updated_at.
      for (final itemId in cascadedIds) {
        final entryRow =
            await (_database.select(_database.myAdhkarItems)..where(
                  (table) =>
                      table.accountId.equals(accountId) &
                      table.itemId.equals(itemId) &
                      table.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        if (entryRow == null) continue;
        final monotonic = _maxInstant(deletedAt, _after(entryRow.updatedAt));
        await (_database.update(_database.myAdhkarItems)..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.itemId.equals(itemId) &
                  table.deletedAt.isNull(),
            ))
            .write(
              MyAdhkarItemsCompanion(
                updatedAt: Value(monotonic.toIso8601String()),
                deletedAt: Value(deletedAt.toIso8601String()),
              ),
            );
        await (_database.delete(_database.myAdhkarItemGroups)..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.itemId.equals(itemId),
            ))
            .go();
      }
      // 4. Exactly ONE outbox operation: the group only, built directly so
      // no copy can throw on a skewed clock. The cascaded entries are not
      // queued — the server applies the same cascade itself, so other
      // devices receive them as server entry versions.
      if (queueForSync) {
        await _appendGroupOutbox(
          MyAdhkarGroup(
            accountId: groupRow.accountId,
            groupId: groupRow.groupId,
            name: groupRow.name,
            createdAt: DateTime.parse(groupRow.createdAt),
            updatedAt: groupMonotonic,
            lastAcknowledgedUpdatedAt:
                groupRow.lastAcknowledgedUpdatedAt == null
                ? null
                : DateTime.parse(groupRow.lastAcknowledgedUpdatedAt!),
            deletedAt: deletedAt,
          ),
          operationId,
          ChangeKind.update,
          deletedAtOverride: deletedAt,
        );
      }
      return AppResult.success(cascadedIds.length);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.group.save_failed'));
    }
  }

  @override
  Future<AppResult<int>> liveEntriesOnlyInGroup({
    required String accountId,
    required String groupId,
  }) async {
    try {
      final row = await _database
          .customSelect(
            'SELECT COUNT(*) AS c FROM my_adhkar_items mi '
            'WHERE mi.account_id = ? AND mi.deleted_at IS NULL '
            'AND EXISTS (SELECT 1 FROM my_adhkar_item_groups m '
            'WHERE m.account_id = mi.account_id '
            'AND m.item_id = mi.item_id AND m.group_id = ?) '
            'AND NOT EXISTS ('
            'SELECT 1 FROM my_adhkar_item_groups m2 '
            'JOIN my_adhkar_groups g2 ON g2.account_id = m2.account_id '
            'AND g2.group_id = m2.group_id AND g2.deleted_at IS NULL '
            'WHERE m2.account_id = mi.account_id '
            'AND m2.item_id = mi.item_id AND m2.group_id != ?)',
            variables: [
              Variable.withString(accountId),
              Variable.withString(groupId),
              Variable.withString(groupId),
            ],
          )
          .getSingle();
      return AppResult.success(row.data['c'] as int);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.group.store_failed'));
    }
  }

  Future<bool> _hasLiveGroup(String accountId, List<String> groupIds) async {
    for (final groupId in groupIds) {
      final row =
          await (_database.select(_database.myAdhkarGroups)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.groupId.equals(groupId) &
                    table.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (row != null) return true;
    }
    return false;
  }

  // -- Entries ---------------------------------------------------------------

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
      if (row == null) return AppResult.success(null);
      final memberships =
          await (_database.select(_database.myAdhkarItemGroups)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.itemId.equals(itemId),
              ))
              .get();
      final groupIds = memberships.map((row) => row.groupId).toList()..sort();
      return AppResult.success(_decodeItemRow(row, groupIds: groupIds));
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.item.store_failed'));
    }
  }

  @override
  Future<AppResult<int>> liveEntryCount({required String accountId}) async {
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
              source: Value(item.source),
              createdAt: item.createdAt.toIso8601String(),
              updatedAt: item.updatedAt.toIso8601String(),
              lastAcknowledgedUpdatedAt: Value(
                item.lastAcknowledgedUpdatedAt?.toIso8601String(),
              ),
              deletedAt: Value(item.deletedAt?.toIso8601String()),
            ),
          );
      await _writeMemberships(item, addedAt: item.createdAt);
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
    MyDhikrItem edited, {
    required DateTime priorUpdatedAt,
    required String operationId,
    required bool queueForSync,
  }) async {
    try {
      if (queueForSync) {
        await _requireNewOperation(operationId);
      }
      final updated = await _database.customUpdate(
        'UPDATE my_adhkar_items SET text = ?, source = ?, updated_at = ?, '
        'last_acknowledged_updated_at = ? '
        'WHERE account_id = ? AND item_id = ? '
        'AND deleted_at IS NULL AND updated_at = ?',
        variables: [
          Variable.withString(edited.text),
          Variable(edited.source),
          Variable.withString(edited.updatedAt.toIso8601String()),
          Variable(edited.lastAcknowledgedUpdatedAt?.toIso8601String()),
          Variable.withString(edited.accountId),
          Variable.withString(edited.itemId),
          Variable.withString(priorUpdatedAt.toIso8601String()),
        ],
      );
      if (updated == 0) {
        throw StateError('My Adhkar edit raced a delete or another writer');
      }
      // Membership is part of the entry's version: kept groups keep their
      // added_at, a new group gets the edit time.
      final currentRows =
          await (_database.select(_database.myAdhkarItemGroups)..where(
                (table) =>
                    table.accountId.equals(edited.accountId) &
                    table.itemId.equals(edited.itemId),
              ))
              .get();
      final currentIds = currentRows.map((row) => row.groupId).toSet();
      final targetIds = edited.groupIds.toSet();
      for (final row in currentRows) {
        if (!targetIds.contains(row.groupId)) {
          await (_database.delete(_database.myAdhkarItemGroups)..where(
                (table) =>
                    table.accountId.equals(edited.accountId) &
                    table.itemId.equals(edited.itemId) &
                    table.groupId.equals(row.groupId),
              ))
              .go();
        }
      }
      for (final groupId in targetIds.where((id) => !currentIds.contains(id))) {
        await _database
            .into(_database.myAdhkarItemGroups)
            .insert(
              MyAdhkarItemGroupsCompanion.insert(
                accountId: edited.accountId,
                itemId: edited.itemId,
                groupId: groupId,
                addedAt: edited.updatedAt.toIso8601String(),
              ),
            );
      }
      if (queueForSync) {
        await _appendItemOutbox(edited, operationId, ChangeKind.update);
      }
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.item.save_failed'));
    }
  }

  @override
  Future<AppResult<MyDhikrItem>> markItemDeleted({
    required String accountId,
    required String itemId,
    required DateTime deletedAt,
    required String operationId,
    required bool queueForSync,
  }) async {
    try {
      if (queueForSync) {
        await _requireNewOperation(operationId);
      }
      final priorRow =
          await (_database.select(_database.myAdhkarItems)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.itemId.equals(itemId),
              ))
              .getSingleOrNull();
      if (priorRow == null) {
        throw StateError('My Adhkar entry to delete is missing');
      }
      if (priorRow.deletedAt != null) {
        // Already deleted: return the tombstone unchanged (set once, never
        // moved).
        final memberships =
            await (_database.select(_database.myAdhkarItemGroups)..where(
                  (table) =>
                      table.accountId.equals(accountId) &
                      table.itemId.equals(itemId),
                ))
                .get();
        return AppResult.success(
          _decodeItemRow(
            priorRow,
            groupIds: memberships.map((row) => row.groupId).toList()..sort(),
          ),
        );
      }
      // Monotonic: max(now, prior + 1 microsecond); the domain guarantees
      // prior.updated_at >= createdAt, so the result is never before it.
      final monotonic = _maxInstant(deletedAt, _after(priorRow.updatedAt));
      final updated = await _database.customUpdate(
        'UPDATE my_adhkar_items SET updated_at = ?, deleted_at = ? '
        'WHERE account_id = ? AND item_id = ? AND deleted_at IS NULL',
        variables: [
          Variable.withString(monotonic.toIso8601String()),
          Variable.withString(deletedAt.toIso8601String()),
          Variable.withString(accountId),
          Variable.withString(itemId),
        ],
      );
      if (updated == 0) {
        throw StateError('My Adhkar delete raced another writer');
      }
      await (_database.delete(_database.myAdhkarItemGroups)..where(
            (table) =>
                table.accountId.equals(accountId) & table.itemId.equals(itemId),
          ))
          .go();
      // Built directly: a deleted entry may have no groups left, so the
      // live-entry decode would reject the empty set.
      final tombstoned = MyDhikrItem(
        accountId: priorRow.accountId,
        itemId: priorRow.itemId,
        text: priorRow.content,
        source: priorRow.source,
        groupIds: const [],
        createdAt: DateTime.parse(priorRow.createdAt),
        updatedAt: monotonic,
        lastAcknowledgedUpdatedAt: priorRow.lastAcknowledgedUpdatedAt == null
            ? null
            : DateTime.parse(priorRow.lastAcknowledgedUpdatedAt!),
        deletedAt: deletedAt,
      );
      if (queueForSync) {
        await _appendItemOutbox(
          tombstoned,
          operationId,
          ChangeKind.update,
          deletedAtOverride: deletedAt,
        );
      }
      return AppResult.success(tombstoned);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.item.save_failed'));
    }
  }

  // -- Receipt finalization --------------------------------------------------

  /// Settles one acknowledged group receipt locally in one transaction
  /// (contracts/adhkar-qiyam-sync.md): the conflict evidence is upserted by
  /// its stable id, and the server's active version is applied only when no
  /// newer local work exists (the canReplace/newerAck guards mirror the
  /// Adhkar store).
  Future<AppResult<void>> finalizeGroupReceipt({
    required String accountId,
    required String groupId,
    required DateTime outboundVersion,
    required MyAdhkarDispatchReceipt receipt,
  }) async {
    try {
      final active = receipt.group;
      if (active == null ||
          receipt.entityType != 'group' ||
          active.accountId != accountId ||
          active.groupId != groupId) {
        throw const FormatException('Foreign My Adhkar group receipt');
      }
      await _database.transaction(() async {
        final read = await readGroupFresh(
          accountId: accountId,
          groupId: groupId,
        );
        if (read.failureOrNull != null) {
          throw StateError('My Adhkar local read failed');
        }
        final current = read.valueOrNull;
        if (current == null) {
          throw StateError('My Adhkar receipt has no local group');
        }
        if (receipt.conflict case final conflict?) {
          await _upsertConflict(conflict, accountId);
        }
        final canReplace = current.updatedAt == outboundVersion;
        final newerAck =
            current.lastAcknowledgedUpdatedAt != null &&
            current.lastAcknowledgedUpdatedAt!.isAfter(active.updatedAt);
        if (canReplace && !newerAck) {
          await (_database.update(_database.myAdhkarGroups)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.groupId.equals(groupId),
              ))
              .write(
                MyAdhkarGroupsCompanion(
                  name: Value(active.name),
                  updatedAt: Value(active.updatedAt.toIso8601String()),
                  lastAcknowledgedUpdatedAt: Value(
                    active.updatedAt.toIso8601String(),
                  ),
                  deletedAt: Value(active.deletedAt?.toIso8601String()),
                ),
              );
        } else if (!newerAck) {
          await (_database.update(_database.myAdhkarGroups)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.groupId.equals(groupId),
              ))
              .write(
                MyAdhkarGroupsCompanion(
                  lastAcknowledgedUpdatedAt: Value(
                    active.updatedAt.toIso8601String(),
                  ),
                ),
              );
        }
      });
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.group.save_failed'));
    }
  }

  /// Settles one acknowledged entry receipt locally in one transaction:
  /// the conflict evidence is upserted, and the server's active version —
  /// with its group set — is applied only when no newer local work exists.
  Future<AppResult<void>> finalizeItemReceipt({
    required String accountId,
    required String itemId,
    required DateTime outboundVersion,
    required MyAdhkarDispatchReceipt receipt,
  }) async {
    try {
      final active = receipt.item;
      if (active == null ||
          receipt.entityType != 'item' ||
          active.accountId != accountId ||
          active.itemId != itemId) {
        throw const FormatException('Foreign My Adhkar item receipt');
      }
      await _database.transaction(() async {
        final read = await readFresh(accountId: accountId, itemId: itemId);
        if (read.failureOrNull != null) {
          throw StateError('My Adhkar local read failed');
        }
        final current = read.valueOrNull;
        if (current == null) {
          throw StateError('My Adhkar receipt has no local entry');
        }
        if (receipt.conflict case final conflict?) {
          await _upsertConflict(conflict, accountId);
        }
        final canReplace = current.updatedAt == outboundVersion;
        final newerAck =
            current.lastAcknowledgedUpdatedAt != null &&
            current.lastAcknowledgedUpdatedAt!.isAfter(active.updatedAt);
        if (canReplace && !newerAck) {
          await (_database.update(_database.myAdhkarItems)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.itemId.equals(itemId),
              ))
              .write(
                MyAdhkarItemsCompanion(
                  content: Value(active.text),
                  source: Value(active.source),
                  updatedAt: Value(active.updatedAt.toIso8601String()),
                  lastAcknowledgedUpdatedAt: Value(
                    active.updatedAt.toIso8601String(),
                  ),
                  deletedAt: Value(active.deletedAt?.toIso8601String()),
                ),
              );
          if (active.isDeleted) {
            await (_database.delete(_database.myAdhkarItemGroups)..where(
                  (table) =>
                      table.accountId.equals(accountId) &
                      table.itemId.equals(itemId),
                ))
                .go();
          } else {
            await _syncMemberships(
              accountId: accountId,
              itemId: itemId,
              groupIds: active.groupIds,
              newAddedAt: active.updatedAt,
            );
          }
        } else if (!newerAck) {
          await (_database.update(_database.myAdhkarItems)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.itemId.equals(itemId),
              ))
              .write(
                MyAdhkarItemsCompanion(
                  lastAcknowledgedUpdatedAt: Value(
                    active.updatedAt.toIso8601String(),
                  ),
                ),
              );
        }
      });
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.item.save_failed'));
    }
  }

  /// Upserts one remote conflict's evidence by its stable id; repeated
  /// detection reuses the row (read-only evidence, never a resolution).
  Future<AppResult<void>> applyRemoteConflict(
    MyAdhkarRemoteConflict conflict, {
    required String accountId,
  }) async {
    try {
      await _upsertConflict(conflict, accountId);
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error, 'my_adhkar.item.store_failed'));
    }
  }

  /// Inserts the evidence once (`INSERT OR IGNORE` on the stable id) and
  /// throws on any failure, so a caller inside a transaction rolls back
  /// instead of acknowledging without the evidence.
  Future<void> _upsertConflict(
    MyAdhkarRemoteConflict conflict,
    String accountId,
  ) async {
    DateTime versionOf(Map<String, dynamic> record) {
      final value = record['updated_at'];
      return value is String
          ? DateTime.parse(value).toUtc()
          : conflict.detectedAt;
    }

    await _database
        .into(_database.conflictRecords)
        .insert(
          ConflictRecordsCompanion.insert(
            conflictId: conflict.id,
            accountId: accountId,
            entityType: 'my_adhkar_${conflict.entityType}',
            entityId: conflict.entityId,
            activeSource: VersionSource.remote,
            activeTimestamp: versionOf(conflict.active),
            activePayload: jsonEncode(conflict.active),
            retainedSource: VersionSource.remote,
            retainedTimestamp: versionOf(conflict.retained),
            retainedPayload: jsonEncode(conflict.retained),
            detectedAt: conflict.detectedAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// The read-only My Adhkar conflict evidence, newest first, for the
  /// Adhkar "Sync differences" list (T098).
  Stream<List<MyAdhkarConflictEvidence>> watchConflicts(String accountId) =>
      (_database.select(_database.conflictRecords)
            ..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.entityType.isIn(['my_adhkar_group', 'my_adhkar_item']),
            )
            ..orderBy([(table) => OrderingTerm.desc(table.detectedAt)]))
          .watch()
          .map(
            (rows) => List<MyAdhkarConflictEvidence>.unmodifiable(
              rows.map(
                (row) => MyAdhkarConflictEvidence(
                  id: row.conflictId,
                  entityType: row.entityType == 'my_adhkar_group'
                      ? 'group'
                      : 'item',
                  entityId: row.entityId,
                  active: jsonDecode(row.activePayload) as Map<String, dynamic>,
                  retained:
                      jsonDecode(row.retainedPayload) as Map<String, dynamic>,
                  detectedAt: row.detectedAt.toUtc(),
                ),
              ),
            ),
          );

  // -- Shared helpers --------------------------------------------------------

  Future<void> _requireNewOperation(String operationId) async {
    final existing =
        await (_database.select(_database.pendingChanges)
              ..where((table) => table.operationId.equals(operationId)))
            .getSingleOrNull();
    if (existing != null) {
      throw StateError('Duplicate my_adhkar operation');
    }
  }

  /// Makes the stored membership rows equal [groupIds]: a kept group keeps
  /// its local `added_at` (the entry's order inside that group), a removed
  /// group's row goes, and a new group gets `newAddedAt` (or the server's
  /// own `added_at` for it when [serverAddedAt] carries one).
  Future<void> _syncMemberships({
    required String accountId,
    required String itemId,
    required List<String> groupIds,
    required DateTime newAddedAt,
    Map<String, DateTime> serverAddedAt = const {},
  }) async {
    final current =
        await (_database.select(_database.myAdhkarItemGroups)..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.itemId.equals(itemId),
            ))
            .get();
    final target = groupIds.toSet();
    final present = <String>{};
    for (final row in current) {
      if (target.contains(row.groupId)) {
        present.add(row.groupId);
      } else {
        await (_database.delete(_database.myAdhkarItemGroups)..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.itemId.equals(itemId) &
                  table.groupId.equals(row.groupId),
            ))
            .go();
      }
    }
    for (final groupId in target.difference(present)) {
      await _database
          .into(_database.myAdhkarItemGroups)
          .insert(
            MyAdhkarItemGroupsCompanion.insert(
              accountId: accountId,
              itemId: itemId,
              groupId: groupId,
              addedAt: (serverAddedAt[groupId] ?? newAddedAt)
                  .toUtc()
                  .toIso8601String(),
            ),
          );
    }
  }

  Future<void> _writeMemberships(
    MyDhikrItem item, {
    required DateTime addedAt,
  }) async {
    await (_database.delete(_database.myAdhkarItemGroups)..where(
          (table) =>
              table.accountId.equals(item.accountId) &
              table.itemId.equals(item.itemId),
        ))
        .go();
    for (final groupId in item.groupIds) {
      await _database
          .into(_database.myAdhkarItemGroups)
          .insert(
            MyAdhkarItemGroupsCompanion.insert(
              accountId: item.accountId,
              itemId: item.itemId,
              groupId: groupId,
              addedAt: addedAt.toIso8601String(),
            ),
          );
    }
  }

  Future<void> _appendGroupOutbox(
    MyAdhkarGroup group,
    String operationId,
    ChangeKind kind, {
    DateTime? deletedAtOverride,
  }) => _database
      .into(_database.pendingChanges)
      .insert(
        PendingChangesCompanion.insert(
          operationId: operationId,
          accountId: group.accountId,
          entityType: _groupEntityType,
          entityId: group.groupId,
          kind: kind,
          state: PendingChangeState.pending,
          serializedChange: jsonEncode({
            'group_id': group.groupId,
            'name': group.name,
            'created_at': group.createdAt.toIso8601String(),
            'updated_at': group.updatedAt.toIso8601String(),
            'deleted_at': (deletedAtOverride ?? group.deletedAt)
                ?.toIso8601String(),
            'base_updated_at': group.lastAcknowledgedUpdatedAt
                ?.toIso8601String(),
          }),
          createdAt: group.updatedAt,
          versionTimestamp: group.updatedAt,
          baseUpdatedAt: Value(group.lastAcknowledgedUpdatedAt),
        ),
      );

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
            'source': item.source,
            'created_at': item.createdAt.toIso8601String(),
            'updated_at': item.updatedAt.toIso8601String(),
            'deleted_at': (deletedAtOverride ?? item.deletedAt)
                ?.toIso8601String(),
            'group_ids': [...item.groupIds]..sort(),
            'base_updated_at': item.lastAcknowledgedUpdatedAt
                ?.toIso8601String(),
          }),
          createdAt: item.updatedAt,
          versionTimestamp: item.updatedAt,
          baseUpdatedAt: Value(item.lastAcknowledgedUpdatedAt),
        ),
      );

  MyDhikrItem _decodeItemRow(MyAdhkarItem row, {List<String>? groupIds}) =>
      MyDhikrItem(
        accountId: row.accountId,
        itemId: row.itemId,
        text: row.content,
        source: row.source,
        groupIds: groupIds ?? const [],
        createdAt: DateTime.parse(row.createdAt),
        updatedAt: DateTime.parse(row.updatedAt),
        lastAcknowledgedUpdatedAt: row.lastAcknowledgedUpdatedAt == null
            ? null
            : DateTime.parse(row.lastAcknowledgedUpdatedAt!),
        deletedAt: row.deletedAt == null
            ? null
            : DateTime.parse(row.deletedAt!),
      );

  MyAdhkarGroup _decodeGroupRow(MyAdhkarGroupRow row) => _decodeGroup(
    accountId: row.accountId,
    groupId: row.groupId,
    name: row.name,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    lastAcknowledgedUpdatedAt: row.lastAcknowledgedUpdatedAt,
    deletedAt: row.deletedAt,
  );

  MyAdhkarGroup _decodeGroup({
    required String accountId,
    required String groupId,
    required String name,
    required String createdAt,
    required String updatedAt,
    required String? lastAcknowledgedUpdatedAt,
    required String? deletedAt,
  }) => MyAdhkarGroup(
    accountId: accountId,
    groupId: groupId,
    name: name,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
    lastAcknowledgedUpdatedAt: lastAcknowledgedUpdatedAt == null
        ? null
        : DateTime.parse(lastAcknowledgedUpdatedAt),
    deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt),
  );

  /// `prior + 1 microsecond` for the monotonic version rule.
  static DateTime _after(String isoUpdatedAt) =>
      DateTime.parse(isoUpdatedAt).add(const Duration(microseconds: 1));

  static DateTime _maxInstant(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

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
