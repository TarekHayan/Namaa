import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

/// Reads a complete authenticated account snapshot, including tombstones.
abstract interface class TaskRemoteReaderPort {
  Future<AppResult<List<Task>>> readAllTasks(String accountId);
}
