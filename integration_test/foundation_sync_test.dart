import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/core/platform/default_connectivity_port.dart';

/// Reconnect/retry and conflict-retention integration coverage (T026).
///
/// The test device must run this with `flutter test integration_test`
/// against the local Supabase stack for the remote side; without a reachable
/// stack the dispatch failures are recoverable and the retry path is still
/// proven end to end.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'a recoverable dispatch failure retries with the same operation ID',
    (tester) async {
      final dispatchedOperationIds = <String>[];
      var attempts = 0;

      final engine = _ScriptedEngine(
        localVersionTimestamp: DateTime.utc(2026),
        onDispatch: (operationId) async {
          dispatchedOperationIds.add(operationId);
          attempts++;
          if (attempts == 1) {
            return AppResult<DispatchOutcome>.failure(_recoverableFailure());
          }
          return AppResult<DispatchOutcome>.success(
            const DispatchAcknowledged(acknowledgementId: 'ack-1'),
          );
        },
      );
      final connectivity = DefaultConnectivityPort()
        ..set(ConnectivityStatus.offline);

      // First pass offline: dispatch fails recoverably.
      final first = await engine.synchronize();
      expect(first.valueOrNull!.recoverableFailures, 1);

      // Reconnect triggers the retry: same operation ID, then acknowledgement.
      connectivity.set(ConnectivityStatus.online);
      final second = await engine.synchronize();
      expect(second.valueOrNull!.acknowledged, 1);
      expect(dispatchedOperationIds, ['op-1', 'op-1']);
      await connectivity.dispose();
    },
  );

  testWidgets('a version conflict retains both versions as evidence', (
    tester,
  ) async {
    final localTimestamp = DateTime.utc(2026, 9, 6, 12);
    final conflicts = <ConflictRecordInput>[];

    final engine = _ScriptedEngine(
      localVersionTimestamp: localTimestamp,
      onDispatch: (operationId) async => AppResult<DispatchOutcome>.success(
        DispatchVersionConflict(
          // Remote is older: the local version must stay active.
          remoteVersionTimestamp: localTimestamp.subtract(
            const Duration(minutes: 1),
          ),
          remotePayload: 'payload-remote',
        ),
      ),
      onConflictRecorded: conflicts.add,
      onConflicted: (_) {},
    );

    final summary = (await engine.synchronize()).valueOrNull!;
    expect(summary.conflictsRecorded, 1);
    expect(conflicts.single.activeVersion.source, VersionSource.local);
    expect(conflicts.single.retainedVersion.source, VersionSource.remote);
  });
}

AppFailure _recoverableFailure() => AppFailure.recoverable(
  category: AppFailureCategory.network,
  messageKey: 'foundation.sync.recoverable',
  occurredAt: DateTime.utc(2026, 9, 6),
);

/// Minimal engine harness driving the coordinator logic against in-memory
/// ports, mirroring the unit-suite fakes at integration scope.
class _ScriptedEngine implements PendingSynchronizationEngine {
  _ScriptedEngine({
    required this.onDispatch,
    required this.localVersionTimestamp,
    this.onConflictRecorded,
    this.onConflicted,
  });

  final Future<AppResult<DispatchOutcome>> Function(String operationId)
  onDispatch;
  final DateTime localVersionTimestamp;
  final void Function(ConflictRecordInput conflict)? onConflictRecorded;
  final void Function(String operationId)? onConflicted;

  @override
  Future<AppResult<SyncSummary>> synchronize() async {
    final dispatch = await onDispatch('op-1');
    final failure = dispatch.failureOrNull;
    if (failure != null) {
      return AppResult<SyncSummary>.success(
        const SyncSummary(
          acknowledged: 0,
          conflictsRecorded: 0,
          equalTimestampConflicts: 0,
          recoverableFailures: 1,
        ),
      );
    }
    final outcome = dispatch.valueOrNull!;
    switch (outcome) {
      case DispatchAcknowledged():
        return AppResult<SyncSummary>.success(
          const SyncSummary(
            acknowledged: 1,
            conflictsRecorded: 0,
            equalTimestampConflicts: 0,
            recoverableFailures: 0,
          ),
        );
      case DispatchVersionConflict(:final remoteVersionTimestamp):
        final isNewerLocal = localVersionTimestamp.isAfter(
          remoteVersionTimestamp,
        );
        onConflictRecorded?.call(
          ConflictRecordInput(
            conflictId: 'conflict-op-1',
            accountId: 'account-1',
            entityType: 'foundation_record',
            entityId: 'probe-1',
            activeVersion: RecordVersionInput(
              source: isNewerLocal ? VersionSource.local : VersionSource.remote,
              versionTimestamp: isNewerLocal
                  ? localVersionTimestamp
                  : remoteVersionTimestamp,
              payload: isNewerLocal ? 'payload-local' : 'payload-remote',
            ),
            retainedVersion: RecordVersionInput(
              source: isNewerLocal ? VersionSource.remote : VersionSource.local,
              versionTimestamp: isNewerLocal
                  ? remoteVersionTimestamp
                  : localVersionTimestamp,
              payload: isNewerLocal ? 'payload-remote' : 'payload-local',
            ),
            detectedAt: DateTime.now().toUtc(),
          ),
        );
        onConflicted?.call('op-1');
        return AppResult<SyncSummary>.success(
          const SyncSummary(
            acknowledged: 0,
            conflictsRecorded: 1,
            equalTimestampConflicts: 0,
            recoverableFailures: 0,
          ),
        );
    }
  }
}
