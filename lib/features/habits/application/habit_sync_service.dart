import 'dart:async';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_reconciliation.dart';
import 'package:namma_project/features/habits/application/habit_remote_reader.dart';

enum HabitSyncStatus { idle, synchronizing, ready, failed }

final class HabitSyncSnapshot {
  const HabitSyncSnapshot({required this.status, this.lastFailure});
  final HabitSyncStatus status;
  final AppFailure? lastFailure;
}

final class HabitSyncSummary {
  const HabitSyncSummary({required this.outbound, required this.inbound});
  final SyncSummary outbound;
  final HabitReconciliationSummary inbound;
}

/// Sends stable outbox operations, then reads and applies a complete owner
/// snapshot. Every asynchronous boundary is followed by an account check.
final class HabitSyncService {
  HabitSyncService({
    required CloudSessionPort session,
    required ConnectivityPort connectivity,
    required PendingSynchronizationEngine outbound,
    required HabitRemoteReaderPort remoteReader,
    required HabitReconciliationPort reconciler,
  }) : _session = session,
       _connectivity = connectivity,
       _outbound = outbound,
       _remoteReader = remoteReader,
       _reconciler = reconciler {
    _connectivitySubscription = _connectivity.changes.listen((status) {
      if (status == ConnectivityStatus.online) unawaited(synchronize());
    });
    _sessionSubscription = _session.observeSession().listen((snapshot) {
      final account = snapshot.status == CloudSessionStatus.signedIn
          ? snapshot.accountId
          : null;
      if (account != _currentAccountId) {
        _currentAccountId = account;
        _emit(const HabitSyncSnapshot(status: HabitSyncStatus.idle));
      }
      if (account != null &&
          _connectivity.current == ConnectivityStatus.online) {
        unawaited(synchronize());
      }
    });
  }

  final CloudSessionPort _session;
  final ConnectivityPort _connectivity;
  final PendingSynchronizationEngine _outbound;
  final HabitRemoteReaderPort _remoteReader;
  final HabitReconciliationPort _reconciler;
  final StreamController<HabitSyncSnapshot> _snapshots =
      StreamController.broadcast(sync: true);
  late final StreamSubscription<ConnectivityStatus> _connectivitySubscription;
  late final StreamSubscription<CloudSessionSnapshot> _sessionSubscription;
  HabitSyncSnapshot _snapshot = const HabitSyncSnapshot(
    status: HabitSyncStatus.idle,
  );
  String? _currentAccountId;
  Future<AppResult<HabitSyncSummary>>? _activeSync;
  bool _rerun = false;
  bool _disposed = false;

  HabitSyncSnapshot get snapshot => _snapshot;
  Stream<HabitSyncSnapshot> get snapshots => _snapshots.stream;
  Future<AppResult<HabitSyncSummary>> synchronizeOnHabitsEntry() =>
      synchronize();

  Future<AppResult<HabitSyncSummary>> synchronize() {
    if (_activeSync case final active?) {
      _rerun = true;
      return active;
    }
    final future = _drain();
    _activeSync = future;
    return future;
  }

  Future<AppResult<HabitSyncSummary>> _drain() async {
    try {
      late AppResult<HabitSyncSummary> result;
      do {
        _rerun = false;
        result = await _run();
      } while (_rerun && !_disposed);
      return result;
    } finally {
      _activeSync = null;
    }
  }

  Future<AppResult<HabitSyncSummary>> _run() async {
    if (_disposed) return _fail(_failure(AppFailureCategory.configuration));
    _emit(const HabitSyncSnapshot(status: HabitSyncStatus.synchronizing));
    final context = await _session.obtainSyncContext();
    if (context.failureOrNull case final failure?) return _fail(failure);
    final account = context.valueOrNull!.accountId;
    _currentAccountId = account;
    if (_connectivity.current == ConnectivityStatus.offline) {
      return _fail(_failure(AppFailureCategory.network));
    }
    final outbound = await _outbound.synchronize();
    if (!await _stillAccount(account)) {
      return _fail(_failure(AppFailureCategory.authorization));
    }
    if (outbound.failureOrNull case final failure?) return _fail(failure);
    final remote = await _remoteReader.readAll(account);
    if (!await _stillAccount(account)) {
      return _fail(_failure(AppFailureCategory.authorization));
    }
    if (remote.failureOrNull case final failure?) return _fail(failure);
    final inbound = await _reconciler.reconcile(
      accountId: account,
      remote: remote.valueOrNull!,
    );
    if (!await _stillAccount(account)) {
      return _fail(_failure(AppFailureCategory.authorization));
    }
    if (inbound.failureOrNull case final failure?) return _fail(failure);
    final summary = outbound.valueOrNull!;
    if (summary.recoverableFailures > 0 ||
        summary.equalTimestampConflicts > 0 ||
        inbound.valueOrNull!.equalTimestampConflicts > 0) {
      return _fail(_failure(AppFailureCategory.cloud));
    }
    _emit(const HabitSyncSnapshot(status: HabitSyncStatus.ready));
    return AppResult.success(
      HabitSyncSummary(outbound: summary, inbound: inbound.valueOrNull!),
    );
  }

  Future<bool> _stillAccount(String account) async =>
      !_disposed &&
      (await _session.obtainSyncContext()).valueOrNull?.accountId == account;

  AppResult<HabitSyncSummary> _fail(AppFailure failure) {
    _emit(
      HabitSyncSnapshot(status: HabitSyncStatus.failed, lastFailure: failure),
    );
    return AppResult.failure(failure);
  }

  void _emit(HabitSyncSnapshot value) {
    _snapshot = value;
    if (!_snapshots.isClosed) _snapshots.add(value);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _connectivitySubscription.cancel();
    await _sessionSubscription.cancel();
    await _snapshots.close();
  }

  static AppFailure _failure(AppFailureCategory category) =>
      AppFailure.recoverable(
        category: category,
        messageKey: 'habits.sync.failed',
        occurredAt: DateTime.now().toUtc(),
      );
}
