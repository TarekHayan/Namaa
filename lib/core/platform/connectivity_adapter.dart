import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';

/// Real connectivity adapter using `connectivity_plus`.
class ConnectivityAdapter implements ConnectivityPort {
  ConnectivityAdapter(this._connectivity) {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      // connectivity_plus 7.x returns a List<ConnectivityResult>.
      // If the list is empty, we consider it offline. If it contains only
      // ConnectivityResult.none, it's offline. Otherwise, it's online.
      final isOnline =
          results.isNotEmpty &&
          !results.every((r) => r == ConnectivityResult.none);

      final newStatus = isOnline
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;

      if (newStatus != _status) {
        _status = newStatus;
        _controller.add(newStatus);
      }
    });

    // Initialize current status asynchronously. We start offline until proven online.
    _connectivity.checkConnectivity().then((results) {
      final isOnline =
          results.isNotEmpty &&
          !results.every((r) => r == ConnectivityResult.none);
      final newStatus = isOnline
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;
      if (newStatus != _status) {
        _status = newStatus;
        _controller.add(newStatus);
      }
    });
  }

  final Connectivity _connectivity;
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityStatus _status = ConnectivityStatus.offline;

  @override
  ConnectivityStatus get current => _status;

  @override
  Stream<ConnectivityStatus> get changes => _controller.stream;

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }
}
