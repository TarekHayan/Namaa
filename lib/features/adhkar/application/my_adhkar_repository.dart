import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

/// One stored My Adhkar count row (data-model.md, `my_adhkar_counts`).
final class MyAdhkarCountRecord {
  const MyAdhkarCountRecord({
    required this.accountId,
    required this.itemId,
    required this.adhkarDay,
    required this.recordId,
    required this.count,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAcknowledgedUpdatedAt,
  });

  final String accountId;
  final String itemId;
  final String adhkarDay;
  final String recordId;
  final int count;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAcknowledgedUpdatedAt;
}

/// A transactional My Adhkar count commit: the count write and the outbox
/// entry happen together or not at all. There is no award and no catalog
/// version on this path (FR-026).
final class MyAdhkarCountCommitRequest {
  MyAdhkarCountCommitRequest({
    required this.accountId,
    required this.itemId,
    required this.adhkarDay,
    required this.recordId,
    required this.newCount,
    required this.createdAt,
    required this.updatedAt,
    required this.operationId,
    required this.expectedCurrentVersion,
    required this.acknowledgedBase,
    required this.queueForSync,
    required this.hadPrior,
  }) {
    if (accountId.trim().isEmpty ||
        itemId.trim().isEmpty ||
        adhkarDay.trim().isEmpty ||
        recordId.trim().isEmpty ||
        operationId.trim().isEmpty ||
        newCount < 0 ||
        newCount > MyDhikrDraft.maxTarget ||
        !updatedAt.isUtc ||
        !createdAt.isUtc) {
      throw ArgumentError('Invalid My Adhkar count commit request');
    }
  }

  final String accountId;
  final String itemId;
  final String adhkarDay;
  final String recordId;
  final int newCount;

  /// The row's first-ever write instant (kept from the prior row).
  final DateTime createdAt;
  final DateTime updatedAt;
  final String operationId;
  final DateTime? expectedCurrentVersion;
  final DateTime? acknowledgedBase;
  final bool queueForSync;
  final bool hadPrior;
}

/// The outcome of one transactional count commit.
final class MyAdhkarCountCommitOutcome {
  const MyAdhkarCountCommitOutcome({
    required this.wroteCount,
    required this.newCount,
  });

  /// False only for the no-op write (the count did not change).
  final bool wroteCount;
  final int newCount;
}

/// The My Adhkar store boundary (contracts/adhkar-qiyam-application.md,
/// "My Adhkar ports and commands"). My Adhkar never touches the XP ledger,
/// the set award or the streak; nothing here returns or accepts XP.
abstract interface class MyAdhkarRepository {
  /// The live items, oldest first ([MyDhikrItem.createdAt]); deleted items
  /// never appear (FR-025).
  Stream<List<MyDhikrItem>> watchItems(String accountId);

  /// That day's counts for the tab.
  Stream<List<MyAdhkarCountRecord>> watchCounts({
    required String accountId,
    required String adhkarDay,
  });

  /// The stored item including its tombstone (a deleted row is returned so
  /// the commands can reject with `itemDeleted` instead of guessing).
  Future<AppResult<MyDhikrItem?>> readFresh({
    required String accountId,
    required String itemId,
  });

  Future<AppResult<MyAdhkarCountRecord?>> readCountFresh({
    required String accountId,
    required String itemId,
    required String adhkarDay,
  });

  /// The number of live (non-deleted) items; the 100-item limit judges
  /// against live items only (data-model.md, Add command).
  Future<AppResult<int>> liveItemCount({required String accountId});

  /// Runs [action] in one database transaction: a returned failure rolls
  /// the whole transaction back, so a multi-write command (for example the
  /// target-lowering clamp) is atomic (FR-025).
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  );

  /// Inserts a new item row and appends the outbox entry; call inside a
  /// transaction.
  Future<AppResult<void>> insertItem(
    MyDhikrItem item, {
    required String operationId,
    required bool queueForSync,
  });

  /// Updates an existing item row and appends the outbox entry; call inside
  /// a transaction.
  Future<AppResult<void>> updateItem(
    MyDhikrItem item, {
    required String operationId,
    required bool queueForSync,
  });

  /// Sets the tombstone ([deletedAt], set once and never cleared) and
  /// appends the outbox entry; call inside a transaction. Deleting an
  /// already deleted item is a no-op that never moves the tombstone.
  Future<AppResult<void>> markDeleted({
    required String accountId,
    required String itemId,
    required DateTime deletedAt,
    required DateTime updatedAt,
    required String operationId,
    required bool queueForSync,
  });

  /// Writes the count row and appends the outbox entry, rejecting a stale
  /// write against [MyAdhkarCountCommitRequest.expectedCurrentVersion].
  Future<AppResult<MyAdhkarCountCommitOutcome>> commitCount(
    MyAdhkarCountCommitRequest request,
  );
}
