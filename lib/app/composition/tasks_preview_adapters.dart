import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

/// A local-only identity used to keep trial Tasks separate from real accounts.
const String kTasksPreviewAccountId = '00000000-0000-4000-8000-000000000003';

final class TasksPreviewSession implements CloudSessionPort {
  const TasksPreviewSession();

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.value(
    const CloudSessionSnapshot(
      status: CloudSessionStatus.signedIn,
      accountId: kTasksPreviewAccountId,
    ),
  );

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      const AppResult.success(
        CloudSyncContext(accountId: kTasksPreviewAccountId),
      );
}

/// Trial writes remain in the encrypted local database and its pending outbox.
final class TasksPreviewSynchronization
    implements PendingSynchronizationEngine {
  const TasksPreviewSynchronization();

  @override
  Future<AppResult<SyncSummary>> synchronize() async => const AppResult.success(
    SyncSummary(
      acknowledged: 0,
      conflictsRecorded: 0,
      equalTimestampConflicts: 0,
      recoverableFailures: 0,
    ),
  );
}
