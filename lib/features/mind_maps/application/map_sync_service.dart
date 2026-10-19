import 'dart:async';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/application/map_reconciliation.dart';
import 'package:namma_project/features/mind_maps/application/map_remote_reader.dart';

enum MapSyncStatus { idle, synchronizing, ready, failed }

final class MapSyncSnapshot {
  const MapSyncSnapshot({required this.status, this.lastFailure});
  final MapSyncStatus status;
  final AppFailure? lastFailure;
}

final class MapSyncSummary {
  const MapSyncSummary({required this.outbound, required this.inbound});
  final SyncSummary outbound;
  final MapReconciliationSummary inbound;
}

/// Stable outbox first, then one complete owner snapshot. Every await that can
/// touch owner data is followed by a session check.
final class MapSyncService {
  MapSyncService({
    required CloudSessionPort session,
    required ConnectivityPort connectivity,
    required PendingSynchronizationEngine outbound,
    required MapRemoteReaderPort remoteReader,
    required MapReconciliationPort reconciler,
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
      if (account != _currentOwnerId) {
        _currentOwnerId = account;
        _emit(const MapSyncSnapshot(status: MapSyncStatus.idle));
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
  final MapRemoteReaderPort _remoteReader;
  final MapReconciliationPort _reconciler;
  final StreamController<MapSyncSnapshot> _snapshots =
      StreamController.broadcast(sync: true);
  late final StreamSubscription<ConnectivityStatus> _connectivitySubscription;
  late final StreamSubscription<CloudSessionSnapshot> _sessionSubscription;
  MapSyncSnapshot _snapshot = const MapSyncSnapshot(status: MapSyncStatus.idle);
  String? _currentOwnerId;
  Future<AppResult<MapSyncSummary>>? _active;
  bool _rerun = false;
  bool _disposed = false;

  MapSyncSnapshot get snapshot => _snapshot;
  Stream<MapSyncSnapshot> get snapshots => _snapshots.stream;
  Future<AppResult<MapSyncSummary>> synchronizeOnMapsEntry() => synchronize();

  Future<AppResult<MapSyncSummary>> synchronize() {
    if (_active case final current?) {
      _rerun = true;
      return current;
    }
    final result = _drain();
    _active = result;
    return result;
  }

  Future<AppResult<MapSyncSummary>> _drain() async {
    try {
      late AppResult<MapSyncSummary> result;
      do {
        _rerun = false;
        result = await _run();
      } while (_rerun && !_disposed);
      return result;
    } finally {
      _active = null;
    }
  }

  Future<AppResult<MapSyncSummary>> _run() async {
    if (_disposed) return _fail(_failure(AppFailureCategory.configuration));
    _emit(const MapSyncSnapshot(status: MapSyncStatus.synchronizing));
    final context = await _session.obtainSyncContext();
    if (context.failureOrNull case final failure?) return _fail(failure);
    final owner = context.valueOrNull!.accountId;
    _currentOwnerId = owner;
    if (_connectivity.current == ConnectivityStatus.offline) {
      return _fail(_failure(AppFailureCategory.network));
    }
    final outbound = await _outbound.synchronize();
    if (!await _stillOwner(owner)) {
      return _fail(_failure(AppFailureCategory.authorization));
    }
    if (outbound.failureOrNull case final failure?) return _fail(failure);
    final remote = await _remoteReader.readAll(owner);
    if (!await _stillOwner(owner)) {
      return _fail(_failure(AppFailureCategory.authorization));
    }
    if (remote.failureOrNull case final failure?) return _fail(failure);
    final inbound = await _reconciler.reconcile(
      ownerId: owner,
      remote: remote.valueOrNull!,
    );
    if (!await _stillOwner(owner)) {
      return _fail(_failure(AppFailureCategory.authorization));
    }
    if (inbound.failureOrNull case final failure?) return _fail(failure);
    final summary = outbound.valueOrNull!;
    if (summary.recoverableFailures > 0 ||
        summary.equalTimestampConflicts > 0 ||
        inbound.valueOrNull!.equalTimestampConflicts > 0) {
      return _fail(_failure(AppFailureCategory.cloud));
    }
    _emit(const MapSyncSnapshot(status: MapSyncStatus.ready));
    return AppResult.success(
      MapSyncSummary(outbound: summary, inbound: inbound.valueOrNull!),
    );
  }

  Future<bool> _stillOwner(String owner) async =>
      !_disposed &&
      (await _session.obtainSyncContext()).valueOrNull?.accountId == owner;

  AppResult<MapSyncSummary> _fail(AppFailure failure) {
    _emit(MapSyncSnapshot(status: MapSyncStatus.failed, lastFailure: failure));
    return AppResult.failure(failure);
  }

  void _emit(MapSyncSnapshot value) {
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
        messageKey: 'mind_maps.sync.failed',
        occurredAt: DateTime.now().toUtc(),
      );
}
