/// Connectivity-triggered synchronization orchestration.
///
/// The runner subscribes to the Connectivity port, runs one durable
/// synchronization pass immediately at start and on every transition to
/// online, and publishes each pass outcome. Neither the UI nor Domain
/// depends on network SDK types
/// (specs/001-namaa-foundation/research.md, decision 2).
library;

import 'dart:async';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';

export 'package:namma_project/core/domain/failures/app_failure.dart'
    show AppFailure;

/// The outcome of one runner pass, for status presentation.
final class SyncRunOutcome {
  const SyncRunOutcome({this.summary, this.failure});

  final SyncSummary? summary;

  /// Non-null when the pass failed as a whole.
  final AppFailure? failure;

  bool get isRecoverableFailure => failure?.recoverable ?? false;
}

/// Orchestrates connectivity-triggered retries.
class SynchronizationRunner {
  SynchronizationRunner({
    required PendingSynchronizationEngine engine,
    required ConnectivityPort connectivity,
  }) : _engine = engine,
       _connectivity = connectivity;

  final PendingSynchronizationEngine _engine;
  final ConnectivityPort _connectivity;

  final StreamController<SyncRunOutcome> _outcomes =
      StreamController<SyncRunOutcome>.broadcast();

  StreamSubscription<ConnectivityStatus>? _subscription;
  bool _running = false;
  bool _disposed = false;

  /// Broadcast stream of pass outcomes.
  Stream<SyncRunOutcome> get outcomes => _outcomes.stream;

  /// Starts listening: one immediate pass, then a pass on every online
  /// transition.
  void start() {
    if (_disposed || _subscription != null) {
      return;
    }
    unawaited(synchronizeOnce());
    _subscription = _connectivity.changes.listen((status) {
      if (status == ConnectivityStatus.online && !_running) {
        unawaited(synchronizeOnce());
      }
    });
  }

  /// Runs exactly one synchronization pass.
  Future<void> synchronizeOnce() async {
    if (_running || _disposed) {
      return;
    }
    _running = true;
    try {
      final result = await _engine.synchronize();
      if (_disposed) {
        return;
      }
      _outcomes.add(
        result.failureOrNull == null
            ? SyncRunOutcome(summary: result.valueOrNull)
            : SyncRunOutcome(failure: result.failureOrNull),
      );
    } finally {
      _running = false;
    }
  }

  /// Stops listening and closes the outcome stream.
  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    _subscription = null;
    await _outcomes.close();
  }
}
