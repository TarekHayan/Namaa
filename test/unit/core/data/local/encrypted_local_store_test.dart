import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/values/foundation_sync_state.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import '../../../../support/foundation_test_support.dart';

/// Fixed test key; never a real credential. The production key comes from
/// the Credential Vault before database opening.
final _testKey = List<int>.generate(32, (i) => 0x20 + i);

void main() {
  late TemporaryDatabasePath tempPath;

  setUp(() {
    tempPath = TemporaryDatabasePath();
  });
  tearDown(() => tempPath.dispose());

  Future<DriftLocalStore> openStore() async {
    final db = await FoundationDatabase.openEncrypted(
      path: tempPath.allocate(),
      key: _testKey,
    );
    return DriftLocalStore(db);
  }

  PendingChangeRequest pendingRequest(
    String operationId, {
    ChangeKind kind = ChangeKind.create,
    String recordId = 'probe-1',
  }) => PendingChangeRequest(
    operationId: operationId,
    accountId: 'account-1',
    entityType: 'foundation_record',
    entityId: recordId,
    kind: kind,
    serializedChange: '{"v":1}',
    createdAt: DateTime.utc(2026, 9, 6),
    versionTimestamp: DateTime.utc(2026, 9, 6),
  );

  group('encrypted open/restart', () {
    test('data survives a close and reopen with the same key', () async {
      final store = await openStore();
      await store.savePreference('locale', 'ar');
      await store.commitLocalChange(
        LocalRecordChange(
          recordId: 'probe-1',
          accountId: 'account-1',
          payload: 'payload-1',
          versionTimestamp: DateTime.utc(2026, 9, 6),
        ),
        pendingRequest('op-1'),
      );
      final path = store.database.resolvedPath;
      await store.database.close();

      final reopened = await FoundationDatabase.openEncrypted(
        path: path,
        key: _testKey,
      );
      final reopenedStore = DriftLocalStore(reopened);
      final pref = await reopenedStore.readPreference('locale');
      expect(pref.valueOrNull, 'ar');
      final pending = await reopenedStore.readPendingChanges('account-1');
      expect(pending.valueOrNull, hasLength(1));
      expect(pending.valueOrNull!.first.operationId, 'op-1');
      await reopened.close();
    });

    test(
      'a wrong key fails the open without an unencrypted fallback',
      () async {
        final store = await openStore();
        final path = store.database.resolvedPath;
        await store.database.close();

        final wrongKey = List<int>.generate(32, (i) => 0xA0 + i);
        await expectLater(
          FoundationDatabase.openEncrypted(path: path, key: wrongKey),
          throwsA(isA<AppFailure>()),
        );
      },
    );
  });

  group('atomic local-record/outbox commit with create, update, and delete', () {
    test('create commits local record and outbox item atomically', () async {
      final store = await openStore();
      final result = await store.commitLocalChange(
        LocalRecordChange(
          recordId: 'probe-1',
          accountId: 'account-1',
          payload: 'payload-1',
          versionTimestamp: DateTime.utc(2026, 9, 6),
        ),
        pendingRequest('op-1'),
      );

      expect(result.failureOrNull, isNull);
      expect(await store.database.localRecordCount('probe-1'), 1);
      final pending = await store.readPendingChanges('account-1');
      expect(pending.valueOrNull, hasLength(1));
      expect(pending.valueOrNull!.first.kind, ChangeKind.create);
      await store.database.close();
    });

    test(
      'update updates existing local record and creates outbox item atomically',
      () async {
        final store = await openStore();
        // First create the record.
        await store.commitLocalChange(
          LocalRecordChange(
            recordId: 'probe-1',
            accountId: 'account-1',
            payload: 'payload-v1',
            versionTimestamp: DateTime.utc(2026, 9, 6),
          ),
          pendingRequest('op-create'),
        );

        // Now update it.
        final updateResult = await store.commitLocalChange(
          LocalRecordChange(
            recordId: 'probe-1',
            accountId: 'account-1',
            payload: 'payload-v2',
            versionTimestamp: DateTime.utc(2026, 9, 6, 1),
          ),
          pendingRequest('op-update', kind: ChangeKind.update),
        );

        expect(updateResult.failureOrNull, isNull);
        expect(await store.database.localRecordCount('probe-1'), 1);
        final pending = await store.readPendingChanges('account-1');
        expect(pending.valueOrNull, hasLength(2));
        expect(pending.valueOrNull!.last.kind, ChangeKind.update);
        await store.database.close();
      },
    );

    test(
      'update of non-existent record fails and rolls back transaction',
      () async {
        final store = await openStore();
        final result = await store.commitLocalChange(
          LocalRecordChange(
            recordId: 'non-existent',
            accountId: 'account-1',
            payload: 'payload-v1',
            versionTimestamp: DateTime.utc(2026, 9, 6),
          ),
          pendingRequest(
            'op-fail',
            kind: ChangeKind.update,
            recordId: 'non-existent',
          ),
        );

        expect(result.failureOrNull, isNotNull);
        expect(await store.database.localRecordCount('non-existent'), 0);
        final pending = await store.readPendingChanges('account-1');
        expect(pending.valueOrNull, isEmpty);
        await store.database.close();
      },
    );

    test(
      'delete removes local record and creates outbox item atomically',
      () async {
        final store = await openStore();
        await store.commitLocalChange(
          LocalRecordChange(
            recordId: 'probe-1',
            accountId: 'account-1',
            payload: 'payload-1',
            versionTimestamp: DateTime.utc(2026, 9, 6),
          ),
          pendingRequest('op-1'),
        );
        expect(await store.database.localRecordCount('probe-1'), 1);

        final deleteResult = await store.commitLocalChange(
          LocalRecordChange(
            recordId: 'probe-1',
            accountId: 'account-1',
            payload: '',
            versionTimestamp: DateTime.utc(2026, 9, 6, 2),
          ),
          pendingRequest('op-del', kind: ChangeKind.delete),
        );

        expect(deleteResult.failureOrNull, isNull);
        // Local record is removed/tombstoned
        expect(await store.database.localRecordCount('probe-1'), 0);
        final pending = await store.readPendingChanges('account-1');
        expect(pending.valueOrNull, hasLength(2));
        expect(pending.valueOrNull!.last.kind, ChangeKind.delete);
        await store.database.close();
      },
    );

    test(
      'a failed commit changes neither visible state nor the outbox',
      () async {
        final store = await openStore();
        final request = pendingRequest('op-1');
        await store.commitLocalChange(
          LocalRecordChange(
            recordId: 'probe-1',
            accountId: 'account-1',
            payload: 'payload-1',
            versionTimestamp: DateTime.utc(2026, 9, 6),
          ),
          request,
        );

        // Same operation ID and record ID: the transaction must fail as a
        // whole, leaving one record and one outbox entry.
        final duplicate = await store.commitLocalChange(
          LocalRecordChange(
            recordId: 'probe-1',
            accountId: 'account-1',
            payload: 'payload-2',
            versionTimestamp: DateTime.utc(2026, 9, 6),
          ),
          request,
        );
        expect(duplicate.failureOrNull, isNotNull);
        expect(await store.database.localRecordCount('probe-1'), 1);
        final pending = await store.readPendingChanges('account-1');
        expect(pending.valueOrNull, hasLength(1));
        await store.database.close();
      },
    );

    test('an acknowledged operation cannot return to pending', () async {
      final store = await openStore();
      await store.commitLocalChange(
        LocalRecordChange(
          recordId: 'probe-1',
          accountId: 'account-1',
          payload: 'payload-1',
          versionTimestamp: DateTime.utc(2026, 9, 6),
        ),
        pendingRequest('op-1'),
      );
      await store.acknowledgeChange('op-1', 'ack-1');

      final pending = await store.readPendingChanges('account-1');
      expect(pending.valueOrNull, isEmpty);
      await store.database.close();
    });
  });

  group('atomic conflict finalization', () {
    test(
      'recordConflictAndFinalize persists conflict and marks operation conflicted atomically',
      () async {
        final store = await openStore();
        await store.commitLocalChange(
          LocalRecordChange(
            recordId: 'probe-1',
            accountId: 'account-1',
            payload: 'payload-1',
            versionTimestamp: DateTime.utc(2026, 9, 6),
          ),
          pendingRequest('op-1'),
        );

        final conflict = ConflictRecordInput(
          conflictId: 'conflict-1',
          accountId: 'account-1',
          entityType: 'foundation_record',
          entityId: 'probe-1',
          activeVersion: RecordVersionInput(
            source: VersionSource.local,
            versionTimestamp: DateTime.utc(2026, 9, 6, 2),
            payload: 'payload-local',
          ),
          retainedVersion: RecordVersionInput(
            source: VersionSource.remote,
            versionTimestamp: DateTime.utc(2026, 9, 6, 1),
            payload: 'payload-remote',
          ),
          detectedAt: DateTime.utc(2026, 9, 6, 3),
        );

        final result = await store.recordConflictAndFinalize(
          conflict: conflict,
          operationId: 'op-1',
        );
        expect(result.failureOrNull, isNull);

        // The operation is no longer pending: conflicted operations are never dispatched again.
        final pending = await store.readPendingChanges('account-1');
        expect(pending.valueOrNull, isEmpty);

        // Conflict record is persisted.
        final row = await (store.database.select(
          store.database.conflictRecords,
        )..where((t) => t.conflictId.equals('conflict-1'))).getSingleOrNull();
        expect(row, isNotNull);
        expect(row!.activePayload, 'payload-local');
        expect(row.retainedPayload, 'payload-remote');
        final activeRecord = await (store.database.select(
          store.database.localRecords,
        )..where((t) => t.recordId.equals('probe-1'))).getSingle();
        expect(activeRecord.payload, 'payload-local');
        expect(activeRecord.syncState, FoundationSyncState.acknowledged);
        await store.database.close();
      },
    );

    test(
      'remote winner replaces the active local record while retaining the local version',
      () async {
        final store = await openStore();
        final localTimestamp = DateTime.utc(2026, 9, 6);
        await store.commitLocalChange(
          LocalRecordChange(
            recordId: 'probe-remote-wins',
            accountId: 'account-1',
            payload: 'payload-local',
            versionTimestamp: localTimestamp,
          ),
          PendingChangeRequest(
            operationId: 'op-remote-wins',
            accountId: 'account-1',
            entityType: 'foundation_record',
            entityId: 'probe-remote-wins',
            kind: ChangeKind.create,
            serializedChange: 'payload-local',
            createdAt: localTimestamp,
            versionTimestamp: localTimestamp,
          ),
        );
        final conflict = ConflictRecordInput(
          conflictId: 'conflict-remote-wins',
          accountId: 'account-1',
          entityType: 'foundation_record',
          entityId: 'probe-remote-wins',
          activeVersion: RecordVersionInput(
            source: VersionSource.remote,
            versionTimestamp: DateTime.utc(2026, 9, 6, 2),
            payload: 'payload-remote',
          ),
          retainedVersion: RecordVersionInput(
            source: VersionSource.local,
            versionTimestamp: localTimestamp,
            payload: 'payload-local',
          ),
          detectedAt: DateTime.utc(2026, 9, 6, 3),
        );

        final result = await store.recordConflictAndFinalize(
          conflict: conflict,
          operationId: 'op-remote-wins',
        );
        expect(result.failureOrNull, isNull);
        final activeRecord = await (store.database.select(
          store.database.localRecords,
        )..where((t) => t.recordId.equals('probe-remote-wins'))).getSingle();
        expect(activeRecord.payload, 'payload-remote');
        expect(activeRecord.versionTimestamp, DateTime.utc(2026, 9, 6, 2));
        expect(activeRecord.syncState, FoundationSyncState.acknowledged);
        await store.database.close();
      },
    );

    test(
      'recordConflictAndFinalize failure on missing operation rolls back without orphan conflict record',
      () async {
        final store = await openStore();
        final conflict = ConflictRecordInput(
          conflictId: 'conflict-missing',
          accountId: 'account-1',
          entityType: 'foundation_record',
          entityId: 'probe-1',
          activeVersion: RecordVersionInput(
            source: VersionSource.local,
            versionTimestamp: DateTime.utc(2026, 9, 6, 2),
            payload: 'payload-local',
          ),
          retainedVersion: RecordVersionInput(
            source: VersionSource.remote,
            versionTimestamp: DateTime.utc(2026, 9, 6, 1),
            payload: 'payload-remote',
          ),
          detectedAt: DateTime.utc(2026, 9, 6, 3),
        );

        // Missing operation ID: transaction must fail and roll back.
        final result = await store.recordConflictAndFinalize(
          conflict: conflict,
          operationId: 'non-existent-op',
        );
        expect(result.failureOrNull, isNotNull);

        // No orphan conflict record was persisted!
        final row =
            await (store.database.select(store.database.conflictRecords)
                  ..where((t) => t.conflictId.equals('conflict-missing')))
                .getSingleOrNull();
        expect(row, isNull);
        await store.database.close();
      },
    );
  });

  group('durable preference storage', () {
    test('save then read returns the stored value', () async {
      final store = await openStore();
      await store.savePreference('locale', 'en');
      final read = await store.readPreference('locale');
      expect(read.failureOrNull, isNull);
      expect(read.valueOrNull, 'en');
      await store.database.close();
    });

    test('an absent preference reads as null, not a failure', () async {
      final store = await openStore();
      final read = await store.readPreference('appearance');
      expect(read.valueOrNull, isNull);
      await store.database.close();
    });
  });
}
