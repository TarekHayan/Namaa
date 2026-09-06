import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/foundation/domain/foundation_entities.dart';

void main() {
  final now = DateTime.utc(2026, 9, 5, 12);

  group('ApplicationPreference validation', () {
    test('accepts valid locale and appearance values', () {
      final locale = ApplicationPreference.create(
        key: FoundationPreferenceKey.locale,
        value: 'ar',
        updatedAt: now,
      );
      final appearance = ApplicationPreference.create(
        key: FoundationPreferenceKey.appearance,
        value: 'system',
        updatedAt: now,
      );
      expect(locale.value, 'ar');
      expect(appearance.value, 'system');
    });

    test('rejects a value that is invalid for the preference key', () {
      expect(
        () => ApplicationPreference.create(
          key: FoundationPreferenceKey.locale,
          value: 'fr',
          updatedAt: now,
        ),
        throwsArgumentError,
      );
      expect(
        () => ApplicationPreference.create(
          key: FoundationPreferenceKey.appearance,
          value: 'sepia',
          updatedAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a non-UTC updated-at instant', () {
      expect(
        () => ApplicationPreference.create(
          key: FoundationPreferenceKey.locale,
          value: 'ar',
          updatedAt: DateTime.now(),
        ),
        throwsArgumentError,
      );
    });
  });

  group('LocalRecord validation', () {
    test('accepts a well-formed record', () {
      final record = LocalRecord.create(
        recordId: 'probe-1',
        accountId: 'account-1',
        payload: 'payload',
        versionTimestamp: now,
        syncState: FoundationSyncState.localOnly,
        updatedAt: now,
      );
      expect(record.recordId, 'probe-1');
    });

    test('rejects an empty record id', () {
      expect(
        () => LocalRecord.create(
          recordId: '',
          payload: 'payload',
          versionTimestamp: now,
          syncState: FoundationSyncState.localOnly,
          updatedAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-UTC timestamps', () {
      expect(
        () => LocalRecord.create(
          recordId: 'probe-1',
          payload: 'payload',
          versionTimestamp: DateTime.now(),
          syncState: FoundationSyncState.localOnly,
          updatedAt: now,
        ),
        throwsArgumentError,
      );
    });
  });

  group('PendingChange lifecycle', () {
    PendingChange buildPending() => PendingChange.create(
      operationId: 'op-1',
      accountId: 'account-1',
      entityType: 'foundation_record',
      entityId: 'probe-1',
      kind: PendingOperationKind.update,
      serializedChange: '{"v":1}',
      createdAt: now,
      versionTimestamp: now,
    );

    test('rejects a negative attempt count', () {
      expect(
        () => PendingChange.create(
          operationId: 'op-1',
          accountId: 'account-1',
          entityType: 'foundation_record',
          entityId: 'probe-1',
          kind: PendingOperationKind.update,
          serializedChange: '{}',
          createdAt: now,
          versionTimestamp: now,
          attemptCount: -1,
        ),
        throwsArgumentError,
      );
    });

    test('acknowledgement is terminal and immutable', () {
      final pending = buildPending().markDispatching();
      final acknowledged = pending.acknowledge(acknowledgementId: 'ack-1');
      expect(acknowledged.state, PendingChangeLifecycle.acknowledged);
      expect(acknowledged.acknowledgementId, 'ack-1');
      expect(acknowledged.isTerminal, isTrue);

      // An acknowledged operation is never dispatched or re-acknowledged.
      expect(
        () => acknowledged.acknowledge(acknowledgementId: 'ack-2'),
        throwsStateError,
      );
      expect(() => acknowledged.markDispatching(), throwsStateError);
      // The original acknowledgement id is retained.
      expect(acknowledged.acknowledgementId, 'ack-1');
    });

    test('acknowledgement requires a dispatched operation', () {
      expect(
        () => buildPending().acknowledge(acknowledgementId: 'ack-1'),
        throwsStateError,
      );
    });

    test(
      'a recoverable failure returns to pending and increments attempts',
      () {
        final failed = buildPending()
            .markDispatching()
            .recordRecoverableFailure(summary: 'network unreachable');
        expect(failed.state, PendingChangeLifecycle.pending);
        expect(failed.attemptCount, 1);
        expect(failed.lastFailureSummary, 'network unreachable');

        // A retry retains the same operation ID.
        expect(failed.operationId, 'op-1');
      },
    );
  });

  group('Version conflict selection', () {
    RecordVersion local(DateTime t) => RecordVersion(
      source: VersionSource.local,
      versionTimestamp: t,
      payload: 'local',
    );
    RecordVersion remote(DateTime t) => RecordVersion(
      source: VersionSource.remote,
      versionTimestamp: t,
      payload: 'remote',
    );

    test(
      'newer local timestamp selects local as active and retains remote',
      () {
        final resolution = resolveVersionConflict(
          local: local(now),
          remote: remote(now.subtract(const Duration(minutes: 1))),
        );
        expect(resolution, isA<NewerVersionSelected>());
        final selected = resolution as NewerVersionSelected;
        expect(selected.active.source, VersionSource.local);
        expect(selected.retained.source, VersionSource.remote);
      },
    );

    test(
      'newer remote timestamp selects remote as active and retains local',
      () {
        final resolution = resolveVersionConflict(
          local: local(now.subtract(const Duration(minutes: 1))),
          remote: remote(now),
        );
        expect(resolution, isA<NewerVersionSelected>());
        final selected = resolution as NewerVersionSelected;
        expect(selected.active.source, VersionSource.remote);
        expect(selected.retained.source, VersionSource.local);
      },
    );

    test('equal timestamps remain an open, recoverable conflict', () {
      final resolution = resolveVersionConflict(
        local: local(now),
        remote: remote(now),
      );
      expect(resolution, isA<EqualTimestampConflict>());
      // No winner is selected; recovery waits for an approved tie-breaker.
      expect((resolution as EqualTimestampConflict).recoverable, isTrue);
    });
  });

  group('MigrationJournal lifecycle', () {
    test('started -> completed records the finish instant', () {
      final entry = MigrationJournalEntry.start(
        version: 1,
        startedAt: now,
      ).markCompleted(at: now.add(const Duration(seconds: 1)));
      expect(entry.status, MigrationJournalStatus.completed);
      expect(entry.endedAt, now.add(const Duration(seconds: 1)));
    });

    test('started -> failed -> recovered retains recovery detail', () {
      final failed = MigrationJournalEntry.start(
        version: 2,
        startedAt: now,
      ).markFailed(recoveryDetail: 'prior data retained', at: now);
      expect(failed.status, MigrationJournalStatus.failed);
      expect(failed.recoveryDetail, 'prior data retained');

      final recovered = failed.markRecovered(
        recoveryDetail: 'replayed from journal',
        at: now.add(const Duration(seconds: 2)),
      );
      expect(recovered.status, MigrationJournalStatus.recovered);
      expect(recovered.recoveryDetail, 'replayed from journal');
    });

    test('rejects invalid transitions and non-monotonic versions', () {
      expect(
        () => MigrationJournalEntry.start(version: 0, startedAt: now),
        throwsArgumentError,
      );
      final completed = MigrationJournalEntry.start(
        version: 1,
        startedAt: now,
      ).markCompleted(at: now);
      expect(
        () => completed.markFailed(recoveryDetail: 'x', at: now),
        throwsStateError,
      );
    });
  });

  group('FailureState', () {
    test('maps from AppFailure keeping public information only', () {
      final failure = AppFailure.recoverable(
        category: AppFailureCategory.network,
        messageKey: 'foundation.sync.recoverable',
        occurredAt: now,
        technicalCause: 'timeout after 30s',
      );
      final state = FailureState.fromAppFailure(failure);
      expect(state.category, AppFailureCategory.network);
      expect(state.recoverability, FailureRecoverability.recoverable);
      expect(state.userMessageKey, 'foundation.sync.recoverable');
      expect(state.technicalCause, 'timeout after 30s');
    });
  });
}
