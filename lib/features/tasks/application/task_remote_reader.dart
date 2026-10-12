import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

/// Reads a complete authenticated account snapshot, including tombstones.
abstract interface class TaskRemoteReaderPort {
  Future<AppResult<List<Task>>> readAllTasks(String accountId);
}

/// Reads the complete immutable Task-award snapshot for one account.
abstract interface class TaskAwardRemoteReaderPort {
  Future<AppResult<List<TaskCompletionAward>>> readAllTaskAwards(
    String accountId,
  );
}
