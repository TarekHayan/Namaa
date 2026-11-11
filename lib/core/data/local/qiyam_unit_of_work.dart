import 'package:drift/drift.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide XpAward;
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

/// The transactional Qiyam night save (data-model.md): the record upsert,
/// the provisional `qiyam_done` award on the first `performed = true`, and
/// the outbox entry happen together or not at all. Awards are never revoked:
/// changing to "No" and back keeps the first award.
final class DriftQiyamUnitOfWork implements QiyamNightCommitPort {
  DriftQiyamUnitOfWork({
    required FoundationDatabase database,
    required QiyamRepository repository,
    required SharedAwardLedgerPort awards,
  }) : _database = database,
       _repository = repository,
       _awards = awards;

  final FoundationDatabase _database;
  final QiyamRepository _repository;
  final SharedAwardLedgerPort _awards;

  @override
  Future<AppResult<QiyamSaveOutcome>> commit(QiyamSaveRequest request) async {
    try {
      final outcome = await _database.transaction(() async {
        final prior = (await _repository.readFresh(
          accountId: request.accountId,
          nightDate: request.nightDate,
        )).valueOrNull;
        if (request.expectedCurrentVersion != prior?.updatedAt ||
            request.acknowledgedBase != prior?.lastAcknowledgedUpdatedAt ||
            (prior != null && !request.updatedAt.isAfter(prior.updatedAt))) {
          throw _QiyamCommitFailure(
            AppFailure.recoverable(
              category: AppFailureCategory.validation,
              messageKey: 'qiyam.night.stale_record',
              occurredAt: request.updatedAt,
            ),
          );
        }
        final record = QiyamNightRecord(
          accountId: request.accountId,
          nightDate: request.nightDate,
          recordId: request.recordId,
          performed: request.performed,
          rakahs: request.rakahs,
          witr: request.witr,
          startTime: request.startTime,
          endTime: request.endTime,
          note: request.note,
          recordedZoneId: request.recordedZoneId,
          recordedOffsetMinutes: request.recordedOffsetMinutes,
          createdAt: prior?.createdAt ?? request.updatedAt,
          updatedAt: request.updatedAt,
          lastAcknowledgedUpdatedAt: prior?.lastAcknowledgedUpdatedAt,
        );
        final write = await _repository.writeNight(
          record,
          operationId: request.operationId,
          queueForSync: request.queueForSync,
          hadPrior: prior != null,
        );
        if (write.failureOrNull case final failure?) {
          throw _QiyamCommitFailure(failure);
        }
        // The provisional award is inserted on the first `performed = true`
        // whose award row is still missing (FR-010). A missing record or an
        // explicit "No" never inserts or revokes one.
        var awardInserted = false;
        if (record.performed) {
          final existing =
              await (_database.select(_database.xpAwards)..where(
                    (table) =>
                        table.accountId.equals(request.accountId) &
                        table.source.equals(kQiyamDoneAwardSource) &
                        table.sourceId.equals(request.recordId),
                  ))
                  .getSingleOrNull();
          if (existing == null) {
            final insert = await _awards.insertSharedOnce(
              XpAward(
                accountId: request.accountId,
                source: kQiyamDoneAwardSource,
                sourceId: request.recordId,
                amount: 30,
                awardedAt: request.updatedAt,
              ),
            );
            if (insert.failureOrNull case final failure?) {
              throw _QiyamCommitFailure(failure);
            }
            awardInserted = insert.valueOrNull == AwardInsertOutcome.inserted;
          }
        }
        return QiyamSaveOutcome(
          wroteRecord: true,
          awardInserted: awardInserted,
        );
      });
      return AppResult.success(outcome);
    } on _QiyamCommitFailure catch (error) {
      return AppResult.failure(error.failure);
    } catch (error) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'qiyam.night.save_failed',
          occurredAt: DateTime.now().toUtc(),
          technicalCause: error.runtimeType.toString(),
        ),
      );
    }
  }
}

final class _QiyamCommitFailure implements Exception {
  const _QiyamCommitFailure(this.failure);
  final AppFailure failure;
}
