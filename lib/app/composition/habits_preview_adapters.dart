import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

/// Non-release trial identity, separate from both real users and Tasks trial.
const String kHabitsPreviewAccountId = '00000000-0000-4000-8000-000000000004';

final class HabitsPreviewSession implements CloudSessionPort {
  const HabitsPreviewSession();

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.value(
    const CloudSessionSnapshot(
      status: CloudSessionStatus.signedIn,
      accountId: kHabitsPreviewAccountId,
    ),
  );

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      const AppResult.success(
        CloudSyncContext(accountId: kHabitsPreviewAccountId),
      );
}

/// Preview writes stay in the encrypted local database until cloud sync lands.
final class HabitsPreviewSynchronization
    implements PendingSynchronizationEngine {
  const HabitsPreviewSynchronization();

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
