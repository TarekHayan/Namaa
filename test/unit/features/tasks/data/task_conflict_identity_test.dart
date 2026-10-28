import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/sync/synchronization_coordinator.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/data/task_reconciler.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/tasks_test_support.dart';

/// One real clash, seen first by inbound reconciliation and then by outbound
/// dispatch, must leave exactly one visible conflict record.
void main() {
  const codec = TaskPayloadCodec();
  late TemporaryDatabasePath path;
  late FoundationDatabase database;
  late DriftTaskRepository repository;
  late DriftLocalStore localStore;

  setUp(() async {
    path = TemporaryDatabasePath();
    database = await FoundationDatabase.openEncrypted(
      path: path.allocate(),
      key: List<int>.generate(32, (i) => i + 140),
    );
    repository = DriftTaskRepository(database: database, codec: codec);
    localStore = DriftLocalStore(database);
  });

  tearDown(() async {
    await database.close();
    path.dispose();
  });

  test(
    'server-formatted remote JSON and codec JSON give one conflict record',
    () async {
      final synced = Task.create(
        id: kTasksTestTaskId,
        accountId: kTasksTestAccountA,
        title: 'Synced',
        scheduledDate: DateTime(2026, 10, 12),
        createdAt: DateTime.utc(2026, 10, 12, 8),
      );
      expect((await repository.applyInboundTask(synced)).failureOrNull, isNull);

      // This device edits offline; its upload fails before it is sent.
      final localEdit = synced.copyWith(
        title: 'Local edit',
        updatedAt: DateTime.utc(2026, 10, 12, 9),
      );
      expect(
        (await repository.commitTask(
          TaskWriteRequest(
            task: localEdit,
            operationId: 'local-edit',
            kind: ChangeKind.update,
            queuedAt: localEdit.updatedAt,
          ),
        )).failureOrNull,
        isNull,
      );

      // Meanwhile another device saved a newer version on the server.
      final otherDevice = synced.copyWith(
        title: 'Other device',
        updatedAt: DateTime.utc(2026, 10, 12, 10),
      );

      final inbound = await TaskReconciler(
        repository: repository,
        localStore: localStore,
        codec: codec,
      ).reconcile(accountId: kTasksTestAccountA, remoteTasks: [otherDevice]);
      expect(inbound.valueOrNull?.conflictsRecorded, 1);

      // The server's stored JSON for the same version: the completion trigger
      // rewrites completionChangedAt as +00:00, and key order is the server's.
      final stored =
          jsonDecode(codec.encode(otherDevice)) as Map<String, dynamic>
            ..['completionChangedAt'] = '2026-10-12T08:00:00+00:00';
      final serverJson = jsonEncode(
        Map.fromEntries(stored.entries.toList().reversed),
      );
      final outbound = await SynchronizationCoordinator(
        localStore: localStore,
        cloudSession: const _Session(),
        cloudSync: _ConflictingServer(
          DispatchVersionConflict(
            remoteVersionTimestamp: otherDevice.updatedAt,
            remotePayload: serverJson,
          ),
        ),
      ).synchronize();

      expect(outbound.failureOrNull, isNull);
      expect(outbound.valueOrNull?.conflictsRecorded, 1);
      expect(
        await database.rawScalar('SELECT count(*) FROM conflict_records'),
        1,
      );
      expect(
        (await localStore.readPendingChanges(kTasksTestAccountA)).valueOrNull,
        isEmpty,
        reason: 'the conflicted upload is finalized, not retried',
      );
    },
  );
}

final class _Session implements CloudSessionPort {
  const _Session();

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      const AppResult.success(CloudSyncContext(accountId: kTasksTestAccountA));
}

final class _ConflictingServer implements CloudSyncPort {
  const _ConflictingServer(this.outcome);

  final DispatchOutcome outcome;

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async => AppResult.success(outcome);

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async => const AppResult.success(null);
}
