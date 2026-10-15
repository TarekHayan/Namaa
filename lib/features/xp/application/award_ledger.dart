import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

enum AwardInsertOutcome { inserted, alreadyExists }

/// Shared, infrastructure-neutral authority for immutable Task XP awards.
abstract interface class AwardLedgerPort {
  /// Local completion inserts once; reopening and later completions cannot
  /// change the first locally recorded award.
  Future<AppResult<AwardInsertOutcome>> insertOnce(TaskCompletionAward award);

  /// Reconciles an offline award copy with the first award committed by the
  /// shared remote ledger. A second local row is never created for the key.
  Future<AppResult<void>> applyRemoteAward(TaskCompletionAward award);

  Future<AppResult<TaskCompletionAward?>> readAward({
    required String accountId,
    required String source,
    required String sourceId,
  });

  Stream<List<TaskCompletionAward>> watchAwards(String accountId);
}
