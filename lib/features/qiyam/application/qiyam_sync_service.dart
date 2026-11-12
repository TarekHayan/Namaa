import 'dart:async';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import 'qiyam_inbound_sync_port.dart';

final class QiyamSyncSummary {
  const QiyamSyncSummary({required this.outbound, required this.inbound});
  final SyncSummary outbound;
  final QiyamInboundSummary inbound;
}

/// The Qiyam owner scope sends durable operations before importing pages.
/// Domain-scoped exactly like the Adhkar service: a failure here never
/// affects another domain's sync or the global status.
final class QiyamSyncService {
  QiyamSyncService({
    required CloudSessionPort session,
    required ConnectivityPort connectivity,
    required PendingSynchronizationEngine outbound,
    required QiyamInboundSyncPort inbound,
  }) : _session = session,
       _connectivity = connectivity,
       _outbound = outbound,
       _inbound = inbound {
    _connectivitySubscription = _connectivity.changes.listen((status) {
      if (status == ConnectivityStatus.online) unawaited(synchronize());
    });
    _sessionSubscription = _session.observeSession().listen((snapshot) {
      final next = snapshot.status == CloudSessionStatus.signedIn
          ? snapshot.accountId
          : null;
      if (next != _owner) {
        _owner = next;
        _generation++;
      }
      if (next != null && _connectivity.current == ConnectivityStatus.online) {
        unawaited(synchronize());
      }
    });
  }

  final CloudSessionPort _session;
  final ConnectivityPort _connectivity;
  final PendingSynchronizationEngine _outbound;
  final QiyamInboundSyncPort _inbound;
  late final StreamSubscription<ConnectivityStatus> _connectivitySubscription;
  late final StreamSubscription<CloudSessionSnapshot> _sessionSubscription;
  String? _owner;
  int _generation = 0;
  bool _disposed = false;
  bool _rerun = false;
  Future<AppResult<QiyamSyncSummary>>? _active;

  Future<AppResult<QiyamSyncSummary>> synchronize() {
    if (_active case final active?) {
      _rerun = true;
      return active;
    }
    final future = _drain();
    _active = future;
    return future;
  }

  Future<AppResult<QiyamSyncSummary>> _drain() async {
    try {
      late AppResult<QiyamSyncSummary> result;
      do {
        _rerun = false;
        result = await _run();
      } while (_rerun && !_disposed);
      return result;
    } finally {
      _active = null;
    }
  }

  Future<AppResult<QiyamSyncSummary>> _run() async {
    if (_disposed || _connectivity.current == ConnectivityStatus.offline) {
      return AppResult.failure(_failure(AppFailureCategory.network));
    }
    final context = await _session.obtainSyncContext();
    if (context.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final owner = context.valueOrNull!.accountId;
    if (_owner != owner) {
      _owner = owner;
      _generation++;
    }
    final generation = _generation;
    final outbound = await _outbound.synchronize();
    if (!await _stillOwner(owner, generation)) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    if (outbound.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final inbound = await _inbound.receive(
      accountId: owner,
      isCurrentScope: () =>
          !_disposed && _generation == generation && _owner == owner,
    );
    if (!await _stillOwner(owner, generation)) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    if (inbound.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final summary = outbound.valueOrNull!;
    if (summary.recoverableFailures > 0 ||
        summary.equalTimestampConflicts > 0) {
      return AppResult.failure(_failure(AppFailureCategory.cloud));
    }
    return AppResult.success(
      QiyamSyncSummary(outbound: summary, inbound: inbound.valueOrNull!),
    );
  }

  Future<bool> _stillOwner(String owner, int generation) async =>
      !_disposed &&
      generation == _generation &&
      (await _session.obtainSyncContext()).valueOrNull?.accountId == owner;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    await _connectivitySubscription.cancel();
    await _sessionSubscription.cancel();
  }

  static AppFailure _failure(AppFailureCategory category) =>
      AppFailure.recoverable(
        category: category,
        messageKey: 'qiyam.sync.failed',
        occurredAt: DateTime.now().toUtc(),
      );
}
