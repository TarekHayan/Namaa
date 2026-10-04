/// Connectivity observation port implementation without a network package.
///
/// The Foundation reports connectivity as online by default; the adapter
/// exposes manual control so tests and platform-validation runs (T064) can
/// drive transitions deterministically. A real OS connectivity binding is a
/// platform-validation deliverable, not a Domain concern.
library;

import 'dart:async';

import 'package:namma_project/core/application/ports/foundation_ports.dart';

/// Default connectivity adapter: starts online, transitions are manual.
class DefaultConnectivityPort implements ConnectivityPort {
  ConnectivityStatus _status = ConnectivityStatus.online;

  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  @override
  ConnectivityStatus get current => _status;

  @override
  Stream<ConnectivityStatus> get changes => _controller.stream;

  /// Forces a status transition and notifies listeners on change.
  void set(ConnectivityStatus status) {
    if (status == _status) {
      return;
    }
    _status = status;
    _controller.add(status);
  }

  Future<void> dispose() => _controller.close();
}
