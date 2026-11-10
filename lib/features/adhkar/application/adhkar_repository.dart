import 'package:namma_project/core/domain/results/app_result.dart';

/// One stored Adhkar count row (data-model.md, `adhkar_item_counts`). A
/// missing row means count 0; a persisted 0 row is a reset.
final class AdhkarCountRecord {
  const AdhkarCountRecord({
    required this.accountId,
    required this.adhkarDay,
    required this.itemId,
    required this.recordId,
    required this.catalogVersion,
    required this.list,
    required this.count,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAcknowledgedUpdatedAt,
  });

  final String accountId;
  final String adhkarDay;
  final String itemId;
  final String recordId;
  final int catalogVersion;
  final String list;
  final int count;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAcknowledgedUpdatedAt;
}

/// One approved catalog item of the list being counted. The commit carries
/// the same approved set the screen shows, so client set completion can
/// never diverge from the catalog (Phase 3 limits).
final class AdhkarListItem {
  const AdhkarListItem({required this.itemId, required this.target});

  final String itemId;
  final int target;
}

/// A transactional count commit: the count write, the provisional set award
/// on the first completion, and the outbox entry happen together or not at
/// all.
final class AdhkarCommitRequest {
  AdhkarCommitRequest({
    required this.accountId,
    required this.adhkarDay,
    required this.itemId,
    required this.recordId,
    required this.catalogVersion,
    required this.list,
    required this.newCount,
    required this.updatedAt,
    required this.operationId,
    required this.expectedCurrentVersion,
    required this.acknowledgedBase,
    required this.queueForSync,
    required this.listItems,
    required this.setAwardSourceId,
  }) {
    if (accountId.trim().isEmpty ||
        adhkarDay.trim().isEmpty ||
        itemId.trim().isEmpty ||
        recordId.trim().isEmpty ||
        list.trim().isEmpty ||
        newCount < 0 ||
        operationId.trim().isEmpty ||
        !updatedAt.isUtc ||
        listItems.isEmpty ||
        setAwardSourceId.trim().isEmpty) {
      throw ArgumentError('Invalid Adhkar commit request');
    }
  }

  final String accountId;
  final String adhkarDay;
  final String itemId;
  final String recordId;
  final int catalogVersion;
  final String list;
  final int newCount;
  final DateTime updatedAt;
  final String operationId;
  final DateTime? expectedCurrentVersion;
  final DateTime? acknowledgedBase;
  final bool queueForSync;
  final List<AdhkarListItem> listItems;

  /// The deterministic set-award identity for (day, list), computed by the
  /// caller through the shared 009 identity.
  final String setAwardSourceId;
}

/// The outcome of one transactional commit.
final class AdhkarCommitOutcome {
  const AdhkarCommitOutcome({
    required this.wroteCount,
    required this.newCount,
    required this.setCompleted,
    required this.awardInserted,
  });

  /// False only for the at-target no-op.
  final bool wroteCount;
  final int newCount;
  final bool setCompleted;

  /// True when this commit inserted the provisional set award.
  final bool awardInserted;
}

/// The Adhkar count store boundary (contracts/adhkar-qiyam-application.md).
abstract interface class AdhkarRepository {
  Future<AppResult<AdhkarCountRecord?>> readFresh({
    required String accountId,
    required String adhkarDay,
    required String itemId,
  });

  Stream<List<AdhkarCountRecord>> watchDay({
    required String accountId,
    required String adhkarDay,
  });

  /// The stored counts of one list for one day and catalog version, used for
  /// set-completion evaluation inside the commit transaction.
  Future<AppResult<List<AdhkarCountRecord>>> readListCounts({
    required String accountId,
    required String adhkarDay,
    required String list,
  });

  /// Writes the count row and appends the outbox entry; call inside a
  /// transaction. [hadPrior] selects the outbox kind (create vs update).
  Future<AppResult<void>> writeCount(
    AdhkarCountRecord record, {
    required String operationId,
    required bool queueForSync,
    required bool hadPrior,
  });

  /// The days within the look-back range where BOTH set awards exist (the
  /// set award is the idempotent completion record). Feeds the derived
  /// streak walk.
  Future<AppResult<Set<String>>> fullyCompletedDays({
    required String accountId,
    required String lastDay,
    required int maxLookBackDays,
  });

  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  );
}

/// The transactional commit boundary the commands use (implemented by the
/// Drift unit of work in core/data).
abstract interface class AdhkarCountCommitPort {
  Future<AppResult<AdhkarCommitOutcome>> commit(AdhkarCommitRequest request);
}
