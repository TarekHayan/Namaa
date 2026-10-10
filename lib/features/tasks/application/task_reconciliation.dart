import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

/// Counts produced by one complete inbound Task reconciliation pass.
final class TaskReconciliationSummary {
  const TaskReconciliationSummary({
    required this.imported,
    required this.conflictsRecorded,
    required this.equalTimestampConflicts,
  });

  final int imported;
  final int conflictsRecorded;
  final int equalTimestampConflicts;
}

/// Infrastructure-neutral boundary for merging a complete remote Task page
/// sequence into the local account partition.
abstract interface class TaskReconciliationPort {
  Future<AppResult<TaskReconciliationSummary>> reconcile({
    required String accountId,
    required List<Task> remoteTasks,
  });
}
