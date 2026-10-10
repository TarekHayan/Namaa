import 'dart:async';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_reconciliation.dart';
import 'package:namma_project/features/tasks/application/task_remote_reader.dart';

enum TaskInitialSyncStatus { idle, synchronizing, ready, failed }

final class TaskSyncSnapshot {
  const TaskSyncSnapshot({required this.status, this.lastFailure});

  final TaskInitialSyncStatus status;
  final AppFailure? lastFailure;

  bool get initialSyncComplete => status == TaskInitialSyncStatus.ready;
}

final class TaskSyncSummary {
  const TaskSyncSummary({required this.outbound, required this.inbound});

  final SyncSummary outbound;
  final TaskReconciliationSummary inbound;
}

/// Coordinates an outbound outbox pass followed by a complete authenticated
/// inbound Task snapshot on sign-in, reconnect, or Tasks entry.
final class TaskSyncService {
  TaskSyncService({
    required CloudSessionPort session,
    required ConnectivityPort connectivity,
    required PendingSynchronizationEngine outbound,
    required TaskRemoteReaderPort remoteReader,
    required TaskReconciliationPort reconciler,
  }) : _session = session,
       _connectivity = connectivity,
       _outbound = outbound,
       _remoteReader = remoteReader,
       _reconciler = reconciler {
    _connectivitySubscription = _connectivity.changes.listen((status) {
      if (status == ConnectivityStatus.online) {
        unawaited(synchronize());
      }
    });
    _sessionSubscription = _session.observeSession().listen((snapshot) {
      final accountId = snapshot.status == CloudSessionStatus.signedIn
          ? snapshot.accountId
          : null;
      if (accountId != _currentAccountId) {
        _currentAccountId = accountId;
        _readyAccountId = null;
        _emit(const TaskSyncSnapshot(status: TaskInitialSyncStatus.idle));
      }
      if (snapshot.status == CloudSessionStatus.signedIn &&
          _connectivity.current == ConnectivityStatus.online) {
        unawaited(synchronize());
      }
    });
  }

  final CloudSessionPort _session;
  final ConnectivityPort _connectivity;
  final PendingSynchronizationEngine _outbound;
  final TaskRemoteReaderPort _remoteReader;
  final TaskReconciliationPort _reconciler;
  final StreamController<TaskSyncSnapshot> _snapshots =
      StreamController<TaskSyncSnapshot>.broadcast(sync: true);

  late final StreamSubscription<ConnectivityStatus> _connectivitySubscription;
  late final StreamSubscription<CloudSessionSnapshot> _sessionSubscription;
  TaskSyncSnapshot _snapshot = const TaskSyncSnapshot(
    status: TaskInitialSyncStatus.idle,
  );
  String? _readyAccountId;
  String? _currentAccountId;
  bool _rerunRequested = false;
  Future<AppResult<TaskSyncSummary>>? _activeSync;
  bool _disposed = false;

  TaskSyncSnapshot get snapshot => _snapshot;
  Stream<TaskSyncSnapshot> get snapshots => _snapshots.stream;

  Future<AppResult<TaskSyncSummary>> synchronizeOnTasksEntry() => synchronize();

  Future<AppResult<TaskSyncSummary>> synchronize() {
    final active = _activeSync;
    if (active != null) {
      _rerunRequested = true;
      return active;
    }
    final future = _drainSynchronizations();
    _activeSync = future;
    return future;
  }

  Future<AppResult<TaskSyncSummary>> _drainSynchronizations() async {
    try {
      late AppResult<TaskSyncSummary> result;
      do {
        _rerunRequested = false;
        result = await _runSynchronization();
      } while (_rerunRequested && !_disposed);
      return result;
    } finally {
      _activeSync = null;
    }
  }

  Future<AppResult<TaskSyncSummary>> _runSynchronization() async {
    if (_disposed) {
      return AppResult<TaskSyncSummary>.failure(
        _failure(
          AppFailureCategory.configuration,
          'tasks.sync.disposed',
          recoverable: false,
        ),
      );
    }
    _emit(const TaskSyncSnapshot(status: TaskInitialSyncStatus.synchronizing));
    final contextResult = await _session.obtainSyncContext();
    final contextFailure = contextResult.failureOrNull;
    if (contextFailure != null) {
      _emitFailure(contextFailure);
      return AppResult<TaskSyncSummary>.failure(contextFailure);
    }
    final accountId = contextResult.valueOrNull!.accountId;
    if (_currentAccountId != accountId) {
      _currentAccountId = accountId;
      _readyAccountId = null;
    }
    if (_connectivity.current == ConnectivityStatus.offline) {
      final failure = _failure(
        AppFailureCategory.network,
        'tasks.sync.offline',
      );
      _emitFailure(failure);
      return AppResult<TaskSyncSummary>.failure(failure);
    }

    final outboundResult = await _outbound.synchronize();
    if (!await _stillCurrentAccount(accountId)) {
      return _accountChanged();
    }
    final outboundFailure = outboundResult.failureOrNull;
    if (outboundFailure != null) {
      _emitFailure(outboundFailure);
      return AppResult<TaskSyncSummary>.failure(outboundFailure);
    }

    final remoteResult = await _remoteReader.readAllTasks(accountId);
    if (!await _stillCurrentAccount(accountId)) {
      return _accountChanged();
    }
    final remoteFailure = remoteResult.failureOrNull;
    if (remoteFailure != null) {
      _emitFailure(remoteFailure);
      return AppResult<TaskSyncSummary>.failure(remoteFailure);
    }

    final inboundResult = await _reconciler.reconcile(
      accountId: accountId,
      remoteTasks: remoteResult.valueOrNull!,
    );
    if (!await _stillCurrentAccount(accountId)) {
      return _accountChanged();
    }
    final inboundFailure = inboundResult.failureOrNull;
    if (inboundFailure != null) {
      _emitFailure(inboundFailure);
      return AppResult<TaskSyncSummary>.failure(inboundFailure);
    }

    _readyAccountId = accountId;
    final outboundSummary = outboundResult.valueOrNull!;
    final hasOutstandingChanges =
        outboundSummary.recoverableFailures > 0 ||
        outboundSummary.equalTimestampConflicts > 0;
    _emit(
      TaskSyncSnapshot(
        status: TaskInitialSyncStatus.ready,
        lastFailure: hasOutstandingChanges
            ? _failure(AppFailureCategory.cloud, 'tasks.sync.pending')
            : null,
      ),
    );
    return AppResult<TaskSyncSummary>.success(
      TaskSyncSummary(
        outbound: outboundResult.valueOrNull!,
        inbound: inboundResult.valueOrNull!,
      ),
    );
  }

  void _emitFailure(AppFailure failure) {
    _emit(
      TaskSyncSnapshot(
        status: _readyAccountId != null && _readyAccountId == _currentAccountId
            ? TaskInitialSyncStatus.ready
            : TaskInitialSyncStatus.failed,
        lastFailure: failure,
      ),
    );
  }

  Future<bool> _stillCurrentAccount(String accountId) async =>
      (await _session.obtainSyncContext()).valueOrNull?.accountId == accountId;

  AppResult<TaskSyncSummary> _accountChanged() {
    final failure = _failure(
      AppFailureCategory.authorization,
      'tasks.auth.sign_in_required',
    );
    _emitFailure(failure);
    return AppResult<TaskSyncSummary>.failure(failure);
  }

  void _emit(TaskSyncSnapshot value) {
    _snapshot = value;
    if (!_snapshots.isClosed) {
      _snapshots.add(value);
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _connectivitySubscription.cancel();
    await _sessionSubscription.cancel();
    await _snapshots.close();
  }

  static AppFailure _failure(
    AppFailureCategory category,
    String messageKey, {
    bool recoverable = true,
  }) => AppFailure(
    category: category,
    recoverable: recoverable,
    messageKey: messageKey,
    occurredAt: DateTime.now().toUtc(),
  );
}
