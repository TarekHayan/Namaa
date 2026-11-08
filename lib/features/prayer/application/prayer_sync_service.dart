import 'dart:async';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import 'prayer_inbound_sync_port.dart';

final class PrayerSyncSummary {
  const PrayerSyncSummary({required this.outbound, required this.inbound});
  final SyncSummary outbound;
  final PrayerInboundSummary inbound;
}

/// The Prayer owner scope sends durable operations before importing pages.
/// Network failures never block local status updates or device preferences.
final class PrayerSyncService {
  PrayerSyncService({
    required CloudSessionPort session,
    required ConnectivityPort connectivity,
    required PendingSynchronizationEngine outbound,
    required PrayerInboundSyncPort inbound,
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
  final PrayerInboundSyncPort _inbound;
  late final StreamSubscription<ConnectivityStatus> _connectivitySubscription;
  late final StreamSubscription<CloudSessionSnapshot> _sessionSubscription;
  String? _owner;
  int _generation = 0;
  bool _disposed = false;
  bool _rerun = false;
  Future<AppResult<PrayerSyncSummary>>? _active;

  Future<AppResult<PrayerSyncSummary>> synchronize() {
    if (_active case final active?) {
      _rerun = true;
      return active;
    }
    final future = _drain();
    _active = future;
    return future;
  }

  Future<AppResult<PrayerSyncSummary>> _drain() async {
    try {
      late AppResult<PrayerSyncSummary> result;
      do {
        _rerun = false;
        result = await _run();
      } while (_rerun && !_disposed);
      return result;
    } finally {
      _active = null;
    }
  }

  Future<AppResult<PrayerSyncSummary>> _run() async {
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
      PrayerSyncSummary(outbound: summary, inbound: inbound.valueOrNull!),
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
        messageKey: 'prayer.sync.failed',
        occurredAt: DateTime.now().toUtc(),
      );
}
