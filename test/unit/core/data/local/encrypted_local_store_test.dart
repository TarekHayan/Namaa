import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/sync_versions.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/values/foundation_sync_state.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import '../../../../support/foundation_test_support.dart';

/// Fixed test key; never a real credential. The production key comes from
/// the Credential Vault before database opening.
final _testKey = List<int>.generate(32, (i) => 0x20 + i);
const _minute = Duration(minutes: 1);

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
    test(
      'acknowledgement rebases only the next pending edit durably',
      () async {
        final store = await openStore();
        final t = DateTime.utc(2026, 9, 6);
        for (var i = 0; i < 3; i++) {
          final version = t.add(Duration(minutes: i));
          final result = await store.commitLocalChange(
            LocalRecordChange(
              recordId: 'probe-1',
              accountId: 'account-1',
              payload: 'payload-$i',
              versionTimestamp: version,
            ),
            PendingChangeRequest(
              operationId: 'op-$i',
              accountId: 'account-1',
              entityType: 'foundation_record',
              entityId: 'probe-1',
              kind: i == 0 ? ChangeKind.create : ChangeKind.update,
              serializedChange: 'payload-$i',
              createdAt: version,
              versionTimestamp: version,
            ),
          );
          expect(result.failureOrNull, isNull);
        }
        final serverVersion = t.add(const Duration(seconds: 30));
        final acknowledged = await store.acknowledgeChange(
          'op-0',
          'receipt-0',
          serverVersion,
        );
        expect(acknowledged.failureOrNull, isNull);
        final pending = (await store.readPendingChanges(
          'account-1',
        )).valueOrNull!;
        expect(pending.map((row) => row.operationId), ['op-1', 'op-2']);
        expect(pending.first.baseUpdatedAt, serverVersion);
        expect(pending.last.baseUpdatedAt, isNull);
        await store.database.close();
      },
    );

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
      await store.acknowledgeChange('op-1', 'ack-1', DateTime.utc(2026, 9, 6));

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

    Future<void> queueTaskEdit(
      DriftLocalStore store,
      String operationId,
      DateTime version, {
      DateTime? base,
    }) => store.database
        .into(store.database.pendingChanges)
        .insert(
          PendingChangesCompanion.insert(
            operationId: operationId,
            accountId: 'account-1',
            entityType: 'task',
            entityId: 'task-1',
            kind: ChangeKind.update,
            state: PendingChangeState.pending,
            serializedChange: '{"v":"$operationId"}',
            createdAt: version,
            versionTimestamp: version,
            baseUpdatedAt: Value(base),
          ),
        );

    ConflictRecordInput taskConflict({
      required DateTime activeAt,
      required DateTime retainedAt,
      required String activePayload,
    }) => ConflictRecordInput(
      conflictId: syncConflictId(
        accountId: 'account-1',
        entityType: 'task',
        entityId: 'task-1',
        activeAt: activeAt,
        retainedAt: retainedAt,
        activePayload: activePayload,
        retainedPayload: 'payload-local',
      ),
      accountId: 'account-1',
      entityType: 'task',
      entityId: 'task-1',
      activeVersion: RecordVersionInput(
        source: VersionSource.remote,
        versionTimestamp: activeAt,
        payload: activePayload,
      ),
      retainedVersion: RecordVersionInput(
        source: VersionSource.local,
        versionTimestamp: retainedAt,
        payload: '{"v":"op-1"}',
      ),
      detectedAt: DateTime.utc(2026, 9, 6, 3),
    );

    test(
      'a conflicted edit rebases the next queued edit on the server winner',
      () async {
        final store = await openStore();
        final t = DateTime.utc(2026, 9, 6);
        await queueTaskEdit(store, 'op-1', t, base: t.subtract(_minute));
        await queueTaskEdit(store, 'op-2', t.add(_minute), base: t);
        final remoteWinner = t.add(const Duration(seconds: 30));

        final result = await store.recordConflictAndFinalize(
          conflict: taskConflict(
            activeAt: remoteWinner,
            retainedAt: t,
            activePayload: '{"v":"remote"}',
          ),
          operationId: 'op-1',
        );

        expect(result.failureOrNull, isNull);
        final pending = (await store.readPendingChanges(
          'account-1',
        )).valueOrNull!;
        expect(pending.map((row) => row.operationId), ['op-2']);
        // op-2 was built on the losing op-1 version; the server now holds the
        // remote winner, so that is what op-2 must be compared against.
        expect(pending.single.baseUpdatedAt, remoteWinner);
        await store.database.close();
      },
    );

    test('the same clash seen inbound then outbound is stored once', () async {
      final store = await openStore();
      final t = DateTime.utc(2026, 9, 6);
      await queueTaskEdit(store, 'op-1', t, base: t.subtract(_minute));
      final remoteWinner = t.add(const Duration(seconds: 30));

      // Inbound reconciliation encodes the remote through the codec...
      final inbound = await store.recordConflict(
        taskConflict(
          activeAt: remoteWinner,
          retainedAt: t,
          activePayload: '{"v":"remote"}',
        ),
      );
      // ...outbound dispatch receives the server's JSON for the same version.
      final outbound = await store.recordConflictAndFinalize(
        conflict: taskConflict(
          activeAt: remoteWinner,
          retainedAt: t,
          activePayload: '{ "v": "remote" }',
        ),
        operationId: 'op-1',
      );

      expect(inbound.failureOrNull, isNull);
      expect(outbound.failureOrNull, isNull);
      expect(
        await store.database.rawScalar('SELECT count(*) FROM conflict_records'),
        1,
      );
      expect(
        (await store.readPendingChanges('account-1')).valueOrNull,
        isEmpty,
      );
      await store.database.close();
    });

    test(
      'equal timestamps with different contents retain both clashes',
      () async {
        final store = await openStore();
        final t = DateTime.utc(2026, 9, 6);
        final first = taskConflict(
          activeAt: t,
          retainedAt: t,
          activePayload: '{"v":"first"}',
        );
        final second = taskConflict(
          activeAt: t,
          retainedAt: t,
          activePayload: '{"v":"second"}',
        );

        expect(first.conflictId, isNot(second.conflictId));
        expect((await store.recordConflict(first)).failureOrNull, isNull);
        expect((await store.recordConflict(second)).failureOrNull, isNull);
        expect(
          await store.database.rawScalar(
            'SELECT count(*) FROM conflict_records',
          ),
          2,
        );
        await store.database.close();
      },
    );

    test('a conflict id reused for different versions is rejected', () async {
      final store = await openStore();
      final t = DateTime.utc(2026, 9, 6);
      final first = taskConflict(
        activeAt: t.add(_minute),
        retainedAt: t,
        activePayload: '{"v":"remote"}',
      );
      expect((await store.recordConflict(first)).failureOrNull, isNull);

      final reused = ConflictRecordInput(
        conflictId: first.conflictId,
        accountId: first.accountId,
        entityType: first.entityType,
        entityId: first.entityId,
        activeVersion: RecordVersionInput(
          source: VersionSource.remote,
          versionTimestamp: t.add(const Duration(hours: 1)),
          payload: '{"v":"other"}',
        ),
        retainedVersion: first.retainedVersion,
        detectedAt: first.detectedAt,
      );

      expect((await store.recordConflict(reused)).failureOrNull, isNotNull);
      await store.database.close();
    });
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
