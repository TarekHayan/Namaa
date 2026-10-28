import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

final class TaskCompletionCommit {
  TaskCompletionCommit({
    required this.task,
    required this.operationId,
    required this.queuedAt,
    this.firstAward,
  }) {
    if (operationId.trim().isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'must not be blank',
      );
    }
    if (!queuedAt.isUtc) {
      throw ArgumentError.value(queuedAt, 'queuedAt', 'must be UTC');
    }
    if (queuedAt != task.updatedAt) {
      throw ArgumentError.value(
        queuedAt,
        'queuedAt',
        'must match the committed Task version',
      );
    }
    final award = firstAward;
    if (task.isCompleted && award == null) {
      throw ArgumentError.value(
        award,
        'firstAward',
        'is required for a completion commit',
      );
    }
    if (award != null &&
        (award.accountId != task.accountId ||
            award.source != kTaskDoneAwardSource ||
            award.sourceId != task.id ||
            award.amount != kTaskCompletionXp ||
            award.awardedAt != task.completedAt)) {
      throw ArgumentError.value(
        award.uniqueKey,
        'firstAward',
        'must match the committed Task completion',
      );
    }
  }

  final Task task;
  final TaskCompletionAward? firstAward;
  final String operationId;
  final DateTime queuedAt;
}

/// Commits completion state, first XP award, and Task outbox entry atomically.
abstract interface class TaskCompletionUnitOfWork {
  Future<AppResult<void>> commit(TaskCompletionCommit request);
}
