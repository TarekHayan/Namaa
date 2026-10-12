import 'package:drift/drift.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

/// Encrypted Drift implementation of the immutable shared XP ledger.
final class DriftAwardLedger implements AwardLedgerPort {
  DriftAwardLedger(this._database);

  final FoundationDatabase _database;

  @override
  Future<AppResult<AwardInsertOutcome>> insertOnce(
    TaskCompletionAward award,
  ) async {
    try {
      final inserted = await _database
          .into(_database.xpAwards)
          .insertReturningOrNull(
            XpAwardsCompanion.insert(
              accountId: award.accountId,
              source: award.source,
              sourceId: award.sourceId,
              amount: award.amount,
              awardedAt: award.awardedAt,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      return AppResult<AwardInsertOutcome>.success(
        inserted == null
            ? AwardInsertOutcome.alreadyExists
            : AwardInsertOutcome.inserted,
      );
    } catch (error) {
      return AppResult<AwardInsertOutcome>.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<void>> applyRemoteAward(TaskCompletionAward award) async {
    try {
      final existing =
          await (_database.select(_database.xpAwards)..where(
                (table) =>
                    table.accountId.equals(award.accountId) &
                    table.source.equals(award.source) &
                    table.sourceId.equals(award.sourceId),
              ))
              .getSingleOrNull();
      if (existing == null || _fromRow(existing) != award) {
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
      return AppResult<void>.success(null);
    } catch (error) {
      return AppResult<void>.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<TaskCompletionAward?>> readAward({
    required String accountId,
    required String source,
    required String sourceId,
  }) async {
    try {
      final row =
          await (_database.select(_database.xpAwards)..where(
                (table) =>
                    table.accountId.equals(accountId) &
                    table.source.equals(source) &
                    table.sourceId.equals(sourceId),
              ))
              .getSingleOrNull();
      return AppResult<TaskCompletionAward?>.success(
        row == null ? null : _fromRow(row),
      );
    } catch (error) {
      return AppResult<TaskCompletionAward?>.failure(_failure(error));
    }
  }

  @override
  Stream<List<TaskCompletionAward>> watchAwards(String accountId) {
    final query = _database.select(_database.xpAwards)
      ..where((table) => table.accountId.equals(accountId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.awardedAt),
        (table) => OrderingTerm.asc(table.source),
        (table) => OrderingTerm.asc(table.sourceId),
      ]);
    return query.watch().map(
      (rows) => List<TaskCompletionAward>.unmodifiable(rows.map(_fromRow)),
    );
  }

  TaskCompletionAward _fromRow(XpAward row) => TaskCompletionAward(
    accountId: row.accountId,
    source: row.source,
    sourceId: row.sourceId,
    amount: row.amount,
    awardedAt: row.awardedAt.toUtc(),
  );

  AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: kDatabaseUnreadableMessageKey,
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}
