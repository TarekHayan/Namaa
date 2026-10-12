import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_completion_unit_of_work.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';

/// Drift transaction joining the Tasks aggregate, XP ledger, and outbox.
final class DriftTaskCompletionUnitOfWork implements TaskCompletionUnitOfWork {
  DriftTaskCompletionUnitOfWork({
    required FoundationDatabase database,
    required TaskPayloadCodec codec,
    required AwardLedgerPort awardLedger,
  }) : _database = database,
       _awardLedger = awardLedger,
       _tasks = DriftTaskRepository(database: database, codec: codec);

  final FoundationDatabase _database;
  final AwardLedgerPort _awardLedger;
  final DriftTaskRepository _tasks;

  @override
  Future<AppResult<void>> commit(TaskCompletionCommit request) async {
    try {
      await _database.transaction(() async {
        final award = request.firstAward;
        if (award != null) {
          final awardResult = await _awardLedger.insertOnce(award);
          final awardFailure = awardResult.failureOrNull;
          if (awardFailure != null) {
            throw _CompletionTransactionFailure(awardFailure);
          }
        }

        final taskResult = await _tasks.commitTask(
          TaskWriteRequest(
            task: request.task,
            operationId: request.operationId,
            kind: ChangeKind.update,
            queuedAt: request.queuedAt,
          ),
        );
        final taskFailure = taskResult.failureOrNull;
        if (taskFailure != null) {
          throw _CompletionTransactionFailure(taskFailure);
        }
      });
      return AppResult<void>.success(null);
    } on _CompletionTransactionFailure catch (error) {
      return AppResult<void>.failure(error.failure);
    } catch (error) {
      return AppResult<void>.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: kDatabaseUnreadableMessageKey,
          occurredAt: DateTime.now().toUtc(),
          technicalCause: error.runtimeType.toString(),
        ),
      );
    }
  }
}

final class _CompletionTransactionFailure implements Exception {
  const _CompletionTransactionFailure(this.failure);

  final AppFailure failure;
}
