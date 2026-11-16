import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

/// One stored My Adhkar group row with its live-entry count for the group
/// list (FR-028: each group shows its name and number of entries).
final class MyAdhkarGroupSummary {
  const MyAdhkarGroupSummary({
    required this.group,
    required this.liveEntryCount,
  });

  final MyAdhkarGroup group;
  final int liveEntryCount;
}

/// The My Adhkar store boundary (contracts/adhkar-qiyam-application.md,
/// "My Adhkar ports and commands", reshaped 2026-11-16). My Adhkar never
/// touches the XP ledger, the set award or the streak; nothing here
/// returns or accepts XP. It has no Adhkar-day or clock dependency.
abstract interface class MyAdhkarRepository {
  // -- Groups ---------------------------------------------------------------

  /// The live groups, oldest first, each with its live-entry count.
  Stream<List<MyAdhkarGroupSummary>> watchGroups(String accountId);

  /// The live entries of one group, in the order they were added to it
  /// (`added_at`, oldest first).
  Stream<List<MyDhikrItem>> watchGroupItems({
    required String accountId,
    required String groupId,
  });

  /// The stored group including its tombstone, so the commands can reject
  /// with `groupDeleted` instead of guessing.
  Future<AppResult<MyAdhkarGroup?>> readGroupFresh({
    required String accountId,
    required String groupId,
  });

  /// The number of live groups; the 100-group limit judges live groups
  /// only.
  Future<AppResult<int>> liveGroupCount({required String accountId});

  /// Inserts a group row and appends the outbox entry; call inside a
  /// transaction.
  Future<AppResult<void>> insertGroup(
    MyAdhkarGroup group, {
    required String operationId,
    required bool queueForSync,
  });

  /// Renames a live group: the UPDATE is guarded on `deleted_at IS NULL`
  /// and the prior `updated_at`, so a rename never writes over a deleted
  /// group or a concurrent change. Appends the outbox entry; call inside a
  /// transaction.
  Future<AppResult<void>> renameGroup(
    MyAdhkarGroup renamed, {
    required DateTime priorUpdatedAt,
    required String operationId,
    required bool queueForSync,
  });

  /// The FR-029 cascade in one transaction: set the group's tombstone,
  /// remove its memberships, tombstone every live entry left with no live
  /// group (each with a monotonic `updated_at`), and append exactly ONE
  /// outbox operation — for the group only (the server applies the same
  /// cascade itself). Returns the number of cascaded entries.
  Future<AppResult<int>> deleteGroupCascade({
    required String accountId,
    required String groupId,
    required DateTime deletedAt,
    required String operationId,
    required bool queueForSync,
  });

  /// How many live entries the group delete would tombstone: the live
  /// entries whose only live group this is (the confirmation count).
  Future<AppResult<int>> liveEntriesOnlyInGroup({
    required String accountId,
    required String groupId,
  });

  // -- Entries ---------------------------------------------------------------

  /// The stored entry including its tombstone and its current group set,
  /// so the commands can reject with `itemDeleted` and keep `added_at`.
  Future<AppResult<MyDhikrItem?>> readFresh({
    required String accountId,
    required String itemId,
  });

  /// The number of live entries; the 1000-entry limit judges live entries
  /// only.
  Future<AppResult<int>> liveEntryCount({required String accountId});

  /// Runs [action] in one database transaction: a returned failure rolls
  /// the whole transaction back.
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  );

  /// Inserts an entry row, its membership rows (`added_at` = the entry's
  /// creation time) and the outbox entry in the same transaction; call
  /// inside a transaction.
  Future<AppResult<void>> insertItem(
    MyDhikrItem item, {
    required String operationId,
    required bool queueForSync,
  });

  /// Updates an entry row — the UPDATE is guarded on `deleted_at IS NULL`
  /// and the prior `updated_at`, so an edit never resurrects a deleted
  /// entry — syncs the membership rows (a kept group keeps its `added_at`,
  /// a new group gets the edit time) and appends the outbox entry; call
  /// inside a transaction.
  Future<AppResult<void>> updateItem(
    MyDhikrItem edited, {
    required DateTime priorUpdatedAt,
    required String operationId,
    required bool queueForSync,
  });

  /// Sets the tombstone with a monotonic `updated_at`
  /// (`max(now, prior + 1 microsecond)`, never before `createdAt`), removes
  /// the entry's membership rows and appends the outbox entry; call inside
  /// a transaction. Returns the tombstoned row.
  Future<AppResult<MyDhikrItem>> markItemDeleted({
    required String accountId,
    required String itemId,
    required DateTime deletedAt,
    required String operationId,
    required bool queueForSync,
  });
}
