import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_reconciliation.dart';
import 'package:namma_project/features/tasks/application/task_remote_reader.dart';
import 'package:namma_project/features/tasks/application/task_sync_service.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

void main() {
  test(
    'ready snapshot retains a warning when outbound changes remain',
    () async {
      final session = _Session('account-a');
      final connectivity = _Connectivity();
      final outbound = _Outbound(
        (_) async => AppResult<SyncSummary>.success(_summary(failures: 1)),
      );
      final reader = _Reader();
      final service = TaskSyncService(
        session: session,
        connectivity: connectivity,
        outbound: outbound,
        remoteReader: reader,
        reconciler: _Reconciler(),
      );
      addTearDown(() async {
        await service.dispose();
        await session.close();
        await connectivity.close();
      });

      final result = await service.synchronize();

      expect(result.failureOrNull, isNull);
      expect(service.snapshot.status, TaskInitialSyncStatus.ready);
      expect(service.snapshot.lastFailure, isNotNull);
      expect(reader.accounts, <String>['account-a']);
    },
  );

  test(
    'account switch during an active pass reruns only for new owner',
    () async {
      final session = _Session('account-a');
      final connectivity = _Connectivity();
      final firstPass = Completer<AppResult<SyncSummary>>();
      final outbound = _Outbound(
        (pass) => pass == 1
            ? firstPass.future
            : Future.value(AppResult<SyncSummary>.success(_summary())),
      );
      final reader = _Reader();
      final service = TaskSyncService(
        session: session,
        connectivity: connectivity,
        outbound: outbound,
        remoteReader: reader,
        reconciler: _Reconciler(),
      );
      addTearDown(() async {
        await service.dispose();
        await session.close();
        await connectivity.close();
      });

      final active = service.synchronize();
      await Future<void>.delayed(Duration.zero);
      session.switchTo('account-b');
      firstPass.complete(AppResult<SyncSummary>.success(_summary()));
      final result = await active;

      expect(result.failureOrNull, isNull);
      expect(outbound.passes, 2);
      expect(reader.accounts, <String>['account-b']);
      expect(service.snapshot.status, TaskInitialSyncStatus.ready);
      expect(service.snapshot.lastFailure, isNull);
    },
  );
}

SyncSummary _summary({int failures = 0}) => SyncSummary(
  acknowledged: 0,
  conflictsRecorded: 0,
  equalTimestampConflicts: 0,
  recoverableFailures: failures,
);

final class _Session implements CloudSessionPort {
  _Session(this.accountId);

  String? accountId;
  final _changes = StreamController<CloudSessionSnapshot>.broadcast(sync: true);

  void switchTo(String id) {
    accountId = id;
    _changes.add(
      CloudSessionSnapshot(status: CloudSessionStatus.signedIn, accountId: id),
    );
  }

  Future<void> close() => _changes.close();

  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => _changes.stream;

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async {
    final id = accountId;
    if (id == null) {
      return AppResult<CloudSyncContext>.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.authorization,
          messageKey: 'tasks.auth.sign_in_required',
          occurredAt: DateTime.utc(2026, 10, 8),
        ),
      );
    }
    return AppResult<CloudSyncContext>.success(CloudSyncContext(accountId: id));
  }
}

final class _Connectivity implements ConnectivityPort {
  final _changes = StreamController<ConnectivityStatus>.broadcast(sync: true);

  @override
  ConnectivityStatus get current => ConnectivityStatus.online;

  @override
  Stream<ConnectivityStatus> get changes => _changes.stream;

  Future<void> close() => _changes.close();
}

final class _Outbound implements PendingSynchronizationEngine {
  _Outbound(this._run);

  final Future<AppResult<SyncSummary>> Function(int pass) _run;
  int passes = 0;

  @override
  Future<AppResult<SyncSummary>> synchronize() => _run(++passes);
}

final class _Reader implements TaskRemoteReaderPort {
  final List<String> accounts = [];

  @override
  Future<AppResult<List<Task>>> readAllTasks(String accountId) async {
    accounts.add(accountId);
    return AppResult<List<Task>>.success(const <Task>[]);
  }
}

final class _Reconciler implements TaskReconciliationPort {
  @override
  Future<AppResult<TaskReconciliationSummary>> reconcile({
    required String accountId,
    required List<Task> remoteTasks,
  }) async => AppResult<TaskReconciliationSummary>.success(
    const TaskReconciliationSummary(
      imported: 0,
      conflictsRecorded: 0,
      equalTimestampConflicts: 0,
    ),
  );
}
