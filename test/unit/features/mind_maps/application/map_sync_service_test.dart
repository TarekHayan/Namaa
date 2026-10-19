import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/application/map_reconciliation.dart';
import 'package:namma_project/features/mind_maps/application/map_remote_reader.dart';
import 'package:namma_project/features/mind_maps/application/map_sync_service.dart';

import '../../../../support/mind_maps_test_support.dart';

void main() {
  test(
    'outbound precedes all inbound and ready follows reconciliation',
    () async {
      final log = <String>[];
      final session = _Session(kMindMapsTestAccountA);
      final service = _service(session, log);
      addTearDown(service.dispose);
      expect(service.snapshot.status, MapSyncStatus.idle);
      expect((await service.synchronize()).failureOrNull, isNull);
      expect(log, ['outbound', 'read', 'reconcile']);
      expect(service.snapshot.status, MapSyncStatus.ready);
    },
  );

  test('changed account after outbound blocks remote read', () async {
    final log = <String>[];
    final session = _Session(kMindMapsTestAccountA);
    final outbound = _Outbound(log)
      ..onSync = () => session.owner = kMindMapsTestAccountB;
    final service = MapSyncService(
      session: session,
      connectivity: const _Connectivity(),
      outbound: outbound,
      remoteReader: _Reader(log),
      reconciler: _Reconciler(log),
    );
    addTearDown(service.dispose);
    expect(
      (await service.synchronize()).failureOrNull?.category,
      AppFailureCategory.authorization,
    );
    expect(log, ['outbound']);
    expect(service.snapshot.status, MapSyncStatus.failed);
  });

  test('changed account after page read blocks reconciliation', () async {
    final log = <String>[];
    final session = _Session(kMindMapsTestAccountA);
    final reader = _Reader(log)
      ..onRead = () => session.owner = kMindMapsTestAccountB;
    final service = MapSyncService(
      session: session,
      connectivity: const _Connectivity(),
      outbound: _Outbound(log),
      remoteReader: reader,
      reconciler: _Reconciler(log),
    );
    addTearDown(service.dispose);
    expect(
      (await service.synchronize()).failureOrNull?.category,
      AppFailureCategory.authorization,
    );
    expect(log, ['outbound', 'read']);
  });

  test('changed account after reconciliation never reports ready', () async {
    final log = <String>[];
    final session = _Session(kMindMapsTestAccountA);
    final reconciler = _Reconciler(log)
      ..onReconcile = () => session.owner = kMindMapsTestAccountB;
    final service = MapSyncService(
      session: session,
      connectivity: const _Connectivity(),
      outbound: _Outbound(log),
      remoteReader: _Reader(log),
      reconciler: reconciler,
    );
    addTearDown(service.dispose);
    expect(
      (await service.synchronize()).failureOrNull?.category,
      AppFailureCategory.authorization,
    );
    expect(log, ['outbound', 'read', 'reconcile']);
    expect(service.snapshot.status, MapSyncStatus.failed);
  });

  test('failed complete pass stays retryable and imports nothing', () async {
    final log = <String>[];
    final reader = _Reader(log)..fail = true;
    final service = MapSyncService(
      session: _Session(kMindMapsTestAccountA),
      connectivity: const _Connectivity(),
      outbound: _Outbound(log),
      remoteReader: reader,
      reconciler: _Reconciler(log),
    );
    addTearDown(service.dispose);
    expect((await service.synchronize()).failureOrNull, isNotNull);
    expect(log, ['outbound', 'read']);
    expect(service.snapshot.status, MapSyncStatus.failed);
    reader.fail = false;
    expect((await service.synchronize()).failureOrNull, isNull);
    expect(log, ['outbound', 'read', 'outbound', 'read', 'reconcile']);
    expect(service.snapshot.status, MapSyncStatus.ready);
  });
}

MapSyncService _service(_Session session, List<String> log) => MapSyncService(
  session: session,
  connectivity: const _Connectivity(),
  outbound: _Outbound(log),
  remoteReader: _Reader(log),
  reconciler: _Reconciler(log),
);

final class _Session implements CloudSessionPort {
  _Session(this.owner);
  String owner;
  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);
  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();
  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult.success(CloudSyncContext(accountId: owner));
}

final class _Connectivity implements ConnectivityPort {
  const _Connectivity();
  @override
  ConnectivityStatus get current => ConnectivityStatus.online;
  @override
  Stream<ConnectivityStatus> get changes => const Stream.empty();
}

final class _Outbound implements PendingSynchronizationEngine {
  _Outbound(this.log);
  final List<String> log;
  void Function()? onSync;
  @override
  Future<AppResult<SyncSummary>> synchronize() async {
    log.add('outbound');
    onSync?.call();
    return const AppResult.success(
      SyncSummary(
        acknowledged: 1,
        conflictsRecorded: 0,
        equalTimestampConflicts: 0,
        recoverableFailures: 0,
      ),
    );
  }
}

final class _Reader implements MapRemoteReaderPort {
  _Reader(this.log);
  final List<String> log;
  bool fail = false;
  void Function()? onRead;
  @override
  Future<AppResult<MapRemoteSnapshot>> readAll(String ownerId) async {
    log.add('read');
    onRead?.call();
    if (fail) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.cloud,
          messageKey: 'mind_maps.sync.failed',
          occurredAt: DateTime.utc(2026, 10, 18),
        ),
      );
    }
    return AppResult.success(
      MapRemoteSnapshot(
        maps: [],
        nodes: [],
        parentSlots: [],
        sideLinks: [],
        conflicts: [],
      ),
    );
  }
}

final class _Reconciler implements MapReconciliationPort {
  _Reconciler(this.log);
  final List<String> log;
  void Function()? onReconcile;
  @override
  Future<AppResult<MapReconciliationSummary>> reconcile({
    required String ownerId,
    required MapRemoteSnapshot remote,
  }) async {
    log.add('reconcile');
    onReconcile?.call();
    return const AppResult.success(
      MapReconciliationSummary(
        imported: 0,
        conflictsRecorded: 0,
        equalTimestampConflicts: 0,
      ),
    );
  }
}
