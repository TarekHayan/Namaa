import 'dart:async';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import 'adhkar_inbound_sync_port.dart';
import 'my_adhkar_inbound_sync_port.dart';

final class AdhkarSyncSummary {
  const AdhkarSyncSummary({required this.outbound, required this.inbound});
  final SyncSummary outbound;
  final AdhkarInboundSummary inbound;
}

/// The Adhkar owner scope sends durable operations before importing pages.
/// This service is domain-scoped: a failure here never fails or delays
/// Tasks, Habits, Maps or Prayer sync, and never shows in the global sync
/// status (Phase 6, isolation). The My Adhkar inbound pass runs in the same
/// service, independently of the Adhkar import: a My Adhkar failure fails
/// this domain's pass but never stops the Adhkar import and never reaches
/// the other domains (T095).
final class AdhkarSyncService {
  AdhkarSyncService({
    required CloudSessionPort session,
    required ConnectivityPort connectivity,
    required PendingSynchronizationEngine outbound,
    required AdhkarInboundSyncPort inbound,
    MyAdhkarInboundSyncPort? myAdhkarInbound,
  }) : _session = session,
       _connectivity = connectivity,
       _outbound = outbound,
       _inbound = inbound,
       _myAdhkarInbound = myAdhkarInbound {
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
  final AdhkarInboundSyncPort _inbound;
  final MyAdhkarInboundSyncPort? _myAdhkarInbound;
  late final StreamSubscription<ConnectivityStatus> _connectivitySubscription;
  late final StreamSubscription<CloudSessionSnapshot> _sessionSubscription;
  String? _owner;
  int _generation = 0;
  bool _disposed = false;
  bool _rerun = false;
  Future<AppResult<AdhkarSyncSummary>>? _active;

  Future<AppResult<AdhkarSyncSummary>> synchronize() {
    if (_active case final active?) {
      _rerun = true;
      return active;
    }
    final future = _drain();
    _active = future;
    return future;
  }

  Future<AppResult<AdhkarSyncSummary>> _drain() async {
    try {
      late AppResult<AdhkarSyncSummary> result;
      do {
        _rerun = false;
        result = await _run();
      } while (_rerun && !_disposed);
      return result;
    } finally {
      _active = null;
    }
  }

  Future<AppResult<AdhkarSyncSummary>> _run() async {
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
    // The My Adhkar import runs in the same service but independently of
    // the Adhkar import: each has its own failure, so a My Adhkar failure
    // never stops the Adhkar import (nor the reverse), and the pass is
    // reported as one recoverable failure when either one failed.
    AppResult<MyAdhkarInboundSummary>? myInbound;
    if (_myAdhkarInbound case final port?) {
      myInbound = await port.receive(
        accountId: owner,
        isCurrentScope: () =>
            !_disposed && _generation == generation && _owner == owner,
      );
      if (!await _stillOwner(owner, generation)) {
        return AppResult.failure(_failure(AppFailureCategory.authorization));
      }
    }
    if (inbound.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    if (myInbound?.failureOrNull != null) {
      return AppResult.failure(_failure(AppFailureCategory.cloud));
    }
    final summary = outbound.valueOrNull!;
    if (summary.recoverableFailures > 0 ||
        summary.equalTimestampConflicts > 0) {
      return AppResult.failure(_failure(AppFailureCategory.cloud));
    }
    return AppResult.success(
      AdhkarSyncSummary(outbound: summary, inbound: inbound.valueOrNull!),
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
        messageKey: 'adhkar.sync.failed',
        occurredAt: DateTime.now().toUtc(),
      );
}
