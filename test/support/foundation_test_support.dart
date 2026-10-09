/// Deterministic test helpers for Foundation unit and integration tests:
/// a controllable clock, a controllable connectivity probe, and temporary
/// encrypted-database paths.
///
/// These helpers exist so time, network, and filesystem locations never make
/// a Foundation test flaky or dependent on machine state.
library;

import 'dart:async';
import 'dart:io';

/// A deterministic, manually advanced clock for tests.
class TestClock {
  TestClock({DateTime? initialInstant})
    : _instant = (initialInstant ?? DateTime.utc(2026)).toUtc();

  DateTime _instant;

  /// Current deterministic UTC instant.
  DateTime now() => _instant;

  /// Advances the clock by [duration].
  void advance(Duration duration) {
    _instant = _instant.add(duration);
  }

  /// Moves the clock to [instant] if it is later than the current instant.
  void setTo(DateTime instant) {
    final utc = instant.toUtc();
    if (utc.isAfter(_instant)) {
      _instant = utc;
    }
  }
}

/// Connection states the fake connectivity probe can report.
enum TestConnectivityStatus { offline, online }

/// A manually controlled connectivity probe.
///
/// Foundation synchronization logic must react to connectivity transitions
/// without depending on a real network stack; tests drive transitions
/// explicitly through [set].
class TestConnectivityProbe {
  final StreamController<TestConnectivityStatus> _controller =
      StreamController<TestConnectivityStatus>.broadcast();

  TestConnectivityStatus _status = TestConnectivityStatus.offline;

  /// Current status.
  TestConnectivityStatus get status => _status;

  /// Broadcast stream of connectivity transitions.
  Stream<TestConnectivityStatus> get stream => _controller.stream;

  /// Sets the status and notifies listeners on a transition.
  void set(TestConnectivityStatus newStatus) {
    if (newStatus == _status) {
      return;
    }
    _status = newStatus;
    _controller.add(newStatus);
  }

  /// Convenience transition to online.
  void goOnline() => set(TestConnectivityStatus.online);

  /// Convenience transition to offline.
  void goOffline() => set(TestConnectivityStatus.offline);

  /// Closes the underlying stream; call in test teardown.
  Future<void> dispose() => _controller.close();
}

/// Allocates temporary database paths for encrypted Local Store tests.
///
/// Each [allocate] call creates a unique directory under the system temp
/// directory; [dispose] deletes it. Callers open their Drift database at
/// [databaseFile]; the surrounding directory is removed on cleanup so all
/// sidecar files (journal, WAL, cipher material) disappear with it.
class TemporaryDatabasePath {
  Directory? _directory;

  /// Allocates a unique temporary directory and returns the database file
  /// path to open inside it.
  String allocate() {
    _directory = Directory.systemTemp.createTempSync('namaa_foundation_db_');
    return <String>[
      _directory!.path,
      'foundation_encrypted.db',
    ].join(Platform.pathSeparator);
  }

  /// The directory backing the last [allocate] call.
  Directory? get directory => _directory;

  /// Deletes the temporary directory and everything in it. Safe to call
  /// twice.
  void dispose() {
    final dir = _directory;
    _directory = null;
    if (dir != null && dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }
}
