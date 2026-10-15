import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

final class TaskConflictRecord {
  const TaskConflictRecord({
    required this.id,
    required this.taskId,
    required this.activeTitle,
    required this.retainedTitle,
  });

  final String id;
  final String taskId;
  final String activeTitle;
  final String retainedTitle;
}

/// Infrastructure-neutral input for one atomic local Task/outbox write.
final class TaskWriteRequest {
  TaskWriteRequest({
    required this.task,
    required this.operationId,
    required this.kind,
    required this.queuedAt,
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
  }

  final Task task;
  final String operationId;
  final ChangeKind kind;
  final DateTime queuedAt;
}

/// Account-scoped Tasks persistence boundary.
///
/// Implementations may use Drift and Foundation synchronization ports, but
/// those implementation types never cross this interface.
abstract interface class TaskRepository {
  /// Runs an inbound comparison, conflict write, and Task replacement as one
  /// local transaction so a concurrent command cannot interleave with it.
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  );
  Future<AppResult<Task?>> readTask({
    required String accountId,
    required String taskId,
  });

  Stream<List<Task>> watchTasks(String accountId);

  Stream<List<TaskConflictRecord>> watchConflicts(String accountId);

  Future<AppResult<void>> commitTask(TaskWriteRequest request);

  Future<AppResult<bool>> hasPendingChange({
    required String accountId,
    required String taskId,
  });

  Future<AppResult<void>> applyInboundTask(Task task);
}
