import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_reconciliation.dart';
import 'package:namma_project/features/habits/application/habit_remote_reader.dart';
import 'package:namma_project/features/habits/application/habit_sync_service.dart';

import '../../../../support/habits_test_support.dart';

void main() {
  test('outbound precedes complete inbound, then ready', () async {
    final log = <String>[];
    final session = _Session(kHabitsTestAccountA);
    final reader = _Reader(log);
    final reconciler = _Reconciler(log);
    final service = HabitSyncService(
      session: session,
      connectivity: const _Connectivity(),
      outbound: _Outbound(log),
      remoteReader: reader,
      reconciler: reconciler,
    );
    addTearDown(service.dispose);
    expect((await service.synchronize()).failureOrNull, isNull);
    expect(log, ['outbound', 'read', 'reconcile']);
    expect(service.snapshot.status, HabitSyncStatus.ready);
    expect(reconciler.account, kHabitsTestAccountA);
  });

  test(
    'account switch during remote read skips reconciliation and ready',
    () async {
      final log = <String>[];
      final session = _Session(kHabitsTestAccountA);
      final reader = _Reader(log)
        ..onRead = () => session.account = kHabitsTestAccountB;
      final service = HabitSyncService(
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
      expect(service.snapshot.status, HabitSyncStatus.failed);
    },
  );

  test('account switch after outbound skips every inbound read', () async {
    final log = <String>[];
    final session = _Session(kHabitsTestAccountA);
    final outbound = _Outbound(log)
      ..onSync = () => session.account = kHabitsTestAccountB;
    final service = HabitSyncService(
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
    expect(service.snapshot.status, HabitSyncStatus.failed);
  });

  test('account switch after reconciliation cannot report ready', () async {
    final log = <String>[];
    final session = _Session(kHabitsTestAccountA);
    final reconciler = _Reconciler(log)
      ..onReconcile = () => session.account = kHabitsTestAccountB;
    final service = HabitSyncService(
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
    expect(service.snapshot.status, HabitSyncStatus.failed);
  });

  test('failed page cannot apply a partial snapshot or report ready', () async {
    final log = <String>[];
    final reader = _Reader(log)..fail = true;
    final service = HabitSyncService(
      session: _Session(kHabitsTestAccountA),
      connectivity: const _Connectivity(),
      outbound: _Outbound(log),
      remoteReader: reader,
      reconciler: _Reconciler(log),
    );
    addTearDown(service.dispose);
    expect((await service.synchronize()).failureOrNull, isNotNull);
    expect(log, ['outbound', 'read']);
    expect(service.snapshot.status, HabitSyncStatus.failed);
  });
}

final class _Session implements CloudSessionPort {
  _Session(this.account);
  String account;
  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);
  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();
  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult.success(CloudSyncContext(accountId: account));
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

final class _Reader implements HabitRemoteReaderPort {
  _Reader(this.log);
  final List<String> log;
  bool fail = false;
  void Function()? onRead;
  @override
  Future<AppResult<HabitRemoteSnapshot>> readAll(String accountId) async {
    log.add('read');
    onRead?.call();
    if (fail) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.cloud,
          messageKey: 'habits.sync.failed',
          occurredAt: DateTime.utc(2026, 10, 12),
        ),
      );
    }
    return AppResult.success(HabitRemoteSnapshot(habits: [], days: []));
  }
}

final class _Reconciler implements HabitReconciliationPort {
  _Reconciler(this.log);
  final List<String> log;
  String? account;
  void Function()? onReconcile;
  @override
  Future<AppResult<HabitReconciliationSummary>> reconcile({
    required String accountId,
    required HabitRemoteSnapshot remote,
  }) async {
    log.add('reconcile');
    account = accountId;
    onReconcile?.call();
    return const AppResult.success(
      HabitReconciliationSummary(
        imported: 0,
        conflictsRecorded: 0,
        equalTimestampConflicts: 0,
      ),
    );
  }
}
