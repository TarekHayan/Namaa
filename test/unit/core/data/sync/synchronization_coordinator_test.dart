import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/synchronization_coordinator.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';

/// Stateful in-memory Local Store fake mirroring the contract semantics.
class FakeLocalStore implements LocalStorePort {
  final Map<String, String> preferences = {};
  final Map<String, PendingChangeRecord> outbox = {};
  final List<ConflictRecordInput> conflicts = [];
  final Map<String, LocalRecordChange> records = {};

  @override
  Future<AppResult<String?>> readPreference(String key) async =>
      AppResult<String?>.success(preferences[key]);

  @override
  Future<AppResult<void>> savePreference(String key, String value) async {
    preferences[key] = value;
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> commitLocalChange(
    LocalRecordChange change,
    PendingChangeRequest pending,
  ) async {
    if (outbox.containsKey(pending.operationId) ||
        records.containsKey(change.recordId)) {
      return AppResult<void>.failure(_failure('duplicate'));
    }
    outbox[pending.operationId] = PendingChangeRecord(
      operationId: pending.operationId,
      accountId: pending.accountId,
      entityType: pending.entityType,
      entityId: pending.entityId,
      kind: pending.kind,
      state: PendingChangeState.pending,
      attemptCount: 0,
      serializedChange: pending.serializedChange,
      createdAt: pending.createdAt,
      versionTimestamp: pending.versionTimestamp,
    );
    records[change.recordId] = change;
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<List<PendingChangeRecord>>> readPendingChanges(
    String accountId,
  ) async => AppResult<List<PendingChangeRecord>>.success(
    outbox.values.where((r) => r.accountId == accountId).toList(),
  );

  @override
  Future<AppResult<void>> acknowledgeChange(
    String operationId,
    String acknowledgementId,
  ) async {
    final record = outbox[operationId];
    if (record == null || record.state == PendingChangeState.acknowledged) {
      return AppResult<void>.failure(_failure('not dispatchable'));
    }
    outbox[operationId] = PendingChangeRecord(
      operationId: record.operationId,
      accountId: record.accountId,
      entityType: record.entityType,
      entityId: record.entityId,
      kind: record.kind,
      state: PendingChangeState.acknowledged,
      attemptCount: record.attemptCount,
      serializedChange: record.serializedChange,
      createdAt: record.createdAt,
      versionTimestamp: record.versionTimestamp,
    );
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> recordRecoverableFailure(
    String operationId,
    String summary,
  ) async {
    final record = outbox[operationId];
    if (record == null || record.state != PendingChangeState.pending) {
      return AppResult<void>.failure(_failure('not pending'));
    }
    outbox[operationId] = PendingChangeRecord(
      operationId: record.operationId,
      accountId: record.accountId,
      entityType: record.entityType,
      entityId: record.entityId,
      kind: record.kind,
      state: PendingChangeState.pending,
      attemptCount: record.attemptCount + 1,
      lastFailureSummary: summary,
      serializedChange: record.serializedChange,
      createdAt: record.createdAt,
      versionTimestamp: record.versionTimestamp,
    );
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> markChangeConflicted(String operationId) async {
    final record = outbox[operationId];
    if (record == null) {
      return AppResult<void>.failure(_failure('missing'));
    }
    outbox[operationId] = PendingChangeRecord(
      operationId: record.operationId,
      accountId: record.accountId,
      entityType: record.entityType,
      entityId: record.entityId,
      kind: record.kind,
      state: PendingChangeState.conflict,
      attemptCount: record.attemptCount,
      serializedChange: record.serializedChange,
      createdAt: record.createdAt,
      versionTimestamp: record.versionTimestamp,
    );
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> recordConflict(ConflictRecordInput conflict) async {
    conflicts.add(conflict);
    return AppResult<void>.success(null);
  }

  bool failConflictFinalization = false;

  @override
  Future<AppResult<void>> recordConflictAndFinalize({
    required ConflictRecordInput conflict,
    required String operationId,
  }) async {
    if (failConflictFinalization) {
      return AppResult<void>.failure(_failure('conflict-finalization-failed'));
    }
    final record = outbox[operationId];
    if (record == null) {
      return AppResult<void>.failure(_failure('missing'));
    }
    conflicts.add(conflict);
    outbox[operationId] = PendingChangeRecord(
      operationId: record.operationId,
      accountId: record.accountId,
      entityType: record.entityType,
      entityId: record.entityId,
      kind: record.kind,
      state: PendingChangeState.conflict,
      attemptCount: record.attemptCount,
      serializedChange: record.serializedChange,
      createdAt: record.createdAt,
      versionTimestamp: record.versionTimestamp,
    );
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<MigrationOutcome>> runMigration(
    int targetSchemaVersion,
  ) async => AppResult<MigrationOutcome>.success(
    MigrationOutcome(completedVersion: targetSchemaVersion, recovered: false),
  );

  AppFailure _failure(String cause) => AppFailure.blocking(
    category: AppFailureCategory.persistence,
    messageKey: 'foundation.test.$cause',
    occurredAt: DateTime.utc(2026, 9, 6),
  );
}

/// Cloud Session fake returning a fixed account.
class FakeCloudSession implements CloudSessionPort {
  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.success(
        const CloudSyncContext(accountId: 'account-1'),
      );
}

/// Cloud Sync fake dispatching a scripted outcome per call.
class FakeCloudSync implements CloudSyncPort {
  FakeCloudSync(this.outcomes);

  final List<AppResult<DispatchOutcome>> outcomes;
  final List<String> dispatchedOperationIds = [];
  int _cursor = 0;

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    dispatchedOperationIds.add(change.operationId);
    if (_cursor >= outcomes.length) {
      return AppResult<DispatchOutcome>.success(
        const DispatchAcknowledged(acknowledgementId: 'ack-default'),
      );
    }
    return outcomes[_cursor++];
  }

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async => AppResult<RemoteVersion?>.success(null);
}

PendingChangeRecord _pendingRecord(
  String operationId,
  DateTime versionTimestamp,
) => PendingChangeRecord(
  operationId: operationId,
  accountId: 'account-1',
  entityType: 'foundation_record',
  entityId: 'probe-1',
  kind: ChangeKind.update,
  state: PendingChangeState.pending,
  attemptCount: 0,
  serializedChange: 'payload-local',
  createdAt: versionTimestamp,
  versionTimestamp: versionTimestamp,
);

SynchronizationCoordinator buildCoordinator(
  FakeLocalStore store,
  FakeCloudSync sync,
) => SynchronizationCoordinator(
  localStore: store,
  cloudSession: FakeCloudSession(),
  cloudSync: sync,
);

AppFailure _recoverableDispatchFailure() => AppFailure.recoverable(
  category: AppFailureCategory.network,
  messageKey: 'foundation.sync.recoverable',
  occurredAt: DateTime.utc(2026, 9, 6),
);

void main() {
  final t = DateTime.utc(2026, 9, 6, 12);

  test(
    'a recoverable failure stays pending with the same operation ID, then acks',
    () async {
      final store = FakeLocalStore();
      await store.commitLocalChange(
        LocalRecordChange(
          recordId: 'probe-1',
          accountId: 'account-1',
          payload: 'payload-local',
          versionTimestamp: t,
        ),
        PendingChangeRequest(
          operationId: 'op-1',
          accountId: 'account-1',
          entityType: 'foundation_record',
          entityId: 'probe-1',
          kind: ChangeKind.update,
          serializedChange: 'payload-local',
          createdAt: t,
          versionTimestamp: t,
        ),
      );
      final sync = FakeCloudSync([
        AppResult<DispatchOutcome>.failure(_recoverableDispatchFailure()),
      ]);
      final coordinator = buildCoordinator(store, sync);

      final first = await coordinator.synchronize();
      expect(first.valueOrNull!.recoverableFailures, 1);
      final afterFailure = store.outbox['op-1']!;
      expect(afterFailure.state, PendingChangeState.pending);
      expect(afterFailure.attemptCount, 1);
      expect(afterFailure.operationId, 'op-1');

      // Second pass: the default outcome is acknowledgement.
      final second = await coordinator.synchronize();
      expect(second.valueOrNull!.acknowledged, 1);
      expect(store.outbox['op-1']!.state, PendingChangeState.acknowledged);
    },
  );

  test('an acknowledged operation is never dispatched again', () async {
    final store = FakeLocalStore();
    store.outbox['op-1'] = _pendingRecord('op-1', t);
    final sync = FakeCloudSync(const []);
    final coordinator = buildCoordinator(store, sync);

    await coordinator.synchronize();
    expect(sync.dispatchedOperationIds, ['op-1']);

    // A second pass finds only the acknowledged operation: no re-dispatch.
    await coordinator.synchronize();
    expect(sync.dispatchedOperationIds, ['op-1']);
  });

  test(
    'remote conflict: newest timestamp becomes active, loser is retained',
    () async {
      final store = FakeLocalStore();
      // Local is newer than the remote version the fake reports.
      store.outbox['op-1'] = _pendingRecord('op-1', t);
      final sync = FakeCloudSync([
        AppResult<DispatchOutcome>.success(
          DispatchVersionConflict(
            remoteVersionTimestamp: t.subtract(const Duration(minutes: 1)),
            remotePayload: 'payload-remote',
          ),
        ),
      ]);
      final coordinator = buildCoordinator(store, sync);

      final summary = (await coordinator.synchronize()).valueOrNull!;
      expect(summary.conflictsRecorded, 1);

      final conflict = store.conflicts.single;
      expect(conflict.activeVersion.source, VersionSource.local);
      expect(conflict.activeVersion.payload, 'payload-local');
      expect(conflict.retainedVersion.source, VersionSource.remote);
      expect(conflict.retainedVersion.payload, 'payload-remote');
      expect(
        conflict.retainedVersion.versionTimestamp,
        t.subtract(const Duration(minutes: 1)),
      );
      // The conflicted operation is never re-dispatched.
      expect(store.outbox['op-1']!.state, PendingChangeState.conflict);
      await coordinator.synchronize();
      expect(sync.dispatchedOperationIds, ['op-1']);
    },
  );

  test('remote-newer conflict retains the local version as evidence', () async {
    final store = FakeLocalStore();
    store.outbox['op-1'] = _pendingRecord('op-1', t);
    final sync = FakeCloudSync([
      AppResult<DispatchOutcome>.success(
        DispatchVersionConflict(
          remoteVersionTimestamp: t.add(const Duration(minutes: 1)),
          remotePayload: 'payload-remote',
        ),
      ),
    ]);

    await buildCoordinator(store, sync).synchronize();

    final conflict = store.conflicts.single;
    expect(conflict.activeVersion.source, VersionSource.remote);
    expect(conflict.retainedVersion.source, VersionSource.local);
    expect(conflict.retainedVersion.payload, 'payload-local');
  });

  test(
    'equal timestamps stay an open recoverable conflict with no winner',
    () async {
      final store = FakeLocalStore();
      store.outbox['op-1'] = _pendingRecord('op-1', t);
      final sync = FakeCloudSync([
        AppResult<DispatchOutcome>.success(
          DispatchVersionConflict(
            remoteVersionTimestamp: t,
            remotePayload: 'payload-remote',
          ),
        ),
      ]);
      final coordinator = buildCoordinator(store, sync);

      final summary = (await coordinator.synchronize()).valueOrNull!;
      expect(summary.equalTimestampConflicts, 1);
      expect(summary.conflictsRecorded, 0);
      expect(store.conflicts, isEmpty);
      // Still pending: a later approved tie-breaker can resolve it.
      expect(store.outbox['op-1']!.state, PendingChangeState.pending);
    },
  );

  test(
    'failure during atomic conflict finalization preserves pending operation without orphan conflict record',
    () async {
      final store = FakeLocalStore();
      store.outbox['op-1'] = _pendingRecord('op-1', t);
      store.failConflictFinalization = true;

      final sync = FakeCloudSync([
        AppResult<DispatchOutcome>.success(
          DispatchVersionConflict(
            remoteVersionTimestamp: t.subtract(const Duration(minutes: 1)),
            remotePayload: 'payload-remote',
          ),
        ),
      ]);
      final coordinator = buildCoordinator(store, sync);

      final result = await coordinator.synchronize();
      expect(result.failureOrNull, isNotNull);

      // No orphan conflict record was saved:
      expect(store.conflicts, isEmpty);
      // Operation remains pending for future synchronization attempts and is not stuck:
      expect(store.outbox['op-1']!.state, PendingChangeState.pending);
    },
  );
}
