/// The Foundation synchronization status Cubit.
///
/// Calls the synchronization use case through the Foundation contract; it
/// never accesses Drift, Supabase, or secure storage directly
/// (contracts/application-boundaries.md, Presentation State Contract).
library;

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/features/foundation/application/foundation_use_cases.dart';

import 'foundation_state.dart';

class SynchronizationCubit extends Cubit<SyncStatusState> {
  SynchronizationCubit({
    required SynchronizePendingUseCase synchronize,
    required ConnectivityPort connectivity,
  }) : _synchronize = synchronize,
       _connectivity = connectivity,
       super(const SyncIdle());

  final SynchronizePendingUseCase _synchronize;
  final ConnectivityPort _connectivity;

  StreamSubscription<ConnectivityStatus>? _subscription;
  bool _running = false;

  /// Starts listening for connectivity returns and runs one initial pass.
  void start() {
    if (_subscription != null) {
      return;
    }
    unawaited(synchronizeNow());
    _subscription = _connectivity.changes.listen((status) {
      if (status == ConnectivityStatus.online && !_running) {
        unawaited(synchronizeNow());
      }
    });
  }

  /// Runs one synchronization pass and maps its outcome onto the status.
  Future<void> synchronizeNow() async {
    if (_running || isClosed) {
      return;
    }
    _running = true;
    emit(const SyncInProgress());
    try {
      final result = await _synchronize();
      if (isClosed) {
        return;
      }
      final failure = result.failureOrNull;
      if (failure != null) {
        emit(
          const SyncRecoverableFailure(messageKey: kMessageKeySyncRecoverable),
        );
        return;
      }
      final summary = result.valueOrNull!;
      if (summary.recoverableFailures > 0) {
        emit(SyncRetryWaiting(pendingCount: summary.recoverableFailures));
      } else {
        emit(const SyncIdle());
      }
    } finally {
      _running = false;
    }
  }

  @override
  Future<void> close() async {
    final cancellation = _subscription?.cancel();
    _subscription = null;
    // Start closing the Cubit synchronously so no connectivity callback can
    // emit while subscription cancellation completes asynchronously.
    final blocClosing = super.close();
    await cancellation;
    await blocClosing;
  }
}
