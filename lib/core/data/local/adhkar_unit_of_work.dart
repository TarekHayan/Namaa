import 'package:drift/drift.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide XpAward;
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

/// The transactional Adhkar count commit (data-model.md): the count write,
/// the provisional set award on the first completion of the approved item
/// set the screen shows, and the outbox entry happen together or not at all.
final class DriftAdhkarUnitOfWork implements AdhkarCountCommitPort {
  DriftAdhkarUnitOfWork({
    required FoundationDatabase database,
    required AdhkarRepository repository,
    required SharedAwardLedgerPort awards,
  }) : _database = database,
       _repository = repository,
       _awards = awards;

  final FoundationDatabase _database;
  final AdhkarRepository _repository;
  final SharedAwardLedgerPort _awards;

  @override
  Future<AppResult<AdhkarCommitOutcome>> commit(
    AdhkarCommitRequest request,
  ) async {
    try {
      final outcome = await _database.transaction(() async {
        final prior = (await _repository.readFresh(
          accountId: request.accountId,
          adhkarDay: request.adhkarDay,
          itemId: request.itemId,
        )).valueOrNull;
        if (request.expectedCurrentVersion != prior?.updatedAt ||
            request.acknowledgedBase != prior?.lastAcknowledgedUpdatedAt ||
            (prior != null && !request.updatedAt.isAfter(prior.updatedAt))) {
          throw _AdhkarCommitFailure(
            AppFailure.recoverable(
              category: AppFailureCategory.validation,
              messageKey: 'adhkar.count.stale_count',
              occurredAt: request.updatedAt,
            ),
          );
        }
        if (prior != null && prior.count == request.newCount) {
          // Nothing changes: the at-target increment is a no-op (the command
          // guards first; this is the transactional backstop).
          return AdhkarCommitOutcome(
            wroteCount: false,
            newCount: prior.count,
            setCompleted: false,
            awardInserted: false,
          );
        }
        final record = AdhkarCountRecord(
          accountId: request.accountId,
          adhkarDay: request.adhkarDay,
          itemId: request.itemId,
          recordId: request.recordId,
          catalogVersion: request.catalogVersion,
          list: request.list,
          count: request.newCount,
          createdAt: prior?.createdAt ?? request.updatedAt,
          updatedAt: request.updatedAt,
          lastAcknowledgedUpdatedAt: prior?.lastAcknowledgedUpdatedAt,
        );
        final write = await _repository.writeCount(
          record,
          operationId: request.operationId,
          queueForSync: request.queueForSync,
          hadPrior: prior != null,
        );
        if (write.failureOrNull case final failure?) {
          throw _AdhkarCommitFailure(failure);
        }
        // Set completion is judged against the same approved item set the
        // screen shows (carried on the request); a missing row counts as 0.
        final counts =
            (await _repository.readListCounts(
              accountId: request.accountId,
              adhkarDay: request.adhkarDay,
              list: request.list,
            )).valueOrNull ??
            const <AdhkarCountRecord>[];
        final countsByItem = {for (final row in counts) row.itemId: row.count};
        final setCompleted = request.listItems.every(
          (item) => (countsByItem[item.itemId] ?? 0) >= item.target,
        );
        var awardInserted = false;
        if (setCompleted) {
          final setSourceId = request.setAwardSourceId;
          final existing =
              await (_database.select(_database.xpAwards)..where(
                    (table) =>
                        table.accountId.equals(request.accountId) &
                        table.source.equals(kAdhkarSetDoneAwardSource) &
                        table.sourceId.equals(setSourceId),
                  ))
                  .getSingleOrNull();
          if (existing == null) {
            final insert = await _awards.insertSharedOnce(
              XpAward(
                accountId: request.accountId,
                source: kAdhkarSetDoneAwardSource,
                sourceId: setSourceId,
                amount: 15,
                awardedAt: request.updatedAt,
              ),
            );
            if (insert.failureOrNull case final failure?) {
              throw _AdhkarCommitFailure(failure);
            }
            awardInserted = insert.valueOrNull == AwardInsertOutcome.inserted;
          }
        }
        return AdhkarCommitOutcome(
          wroteCount: true,
          newCount: request.newCount,
          setCompleted: setCompleted,
          awardInserted: awardInserted,
        );
      });
      return AppResult.success(outcome);
    } on _AdhkarCommitFailure catch (error) {
      return AppResult.failure(error.failure);
    } catch (error) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'adhkar.count.save_failed',
          occurredAt: DateTime.now().toUtc(),
          technicalCause: error.runtimeType.toString(),
        ),
      );
    }
  }
}

final class _AdhkarCommitFailure implements Exception {
  const _AdhkarCommitFailure(this.failure);
  final AppFailure failure;
}
