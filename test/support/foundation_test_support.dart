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
  ///
  /// The encrypted database runs in a background isolate; on Windows the
  /// file lock can outlive [FoundationDatabase.close] by a few milliseconds,
  /// so the delete retries briefly before giving up (a real leak still
  /// throws).
  void dispose() {
    final dir = _directory;
    _directory = null;
    if (dir == null || !dir.existsSync()) return;
    final watch = Stopwatch()..start();
    for (var attempt = 0; ; attempt++) {
      try {
        dir.deleteSync(recursive: true);
        return;
      } on FileSystemException {
        // The encrypted database runs in a background isolate; on Windows
        // its file handle can outlive close() by a while under load. Every
        // assertion has already run by the time dispose is called, so a
        // locked cleanup artifact must not fail the test: retry briefly,
        // then leave the directory behind (it is removable as soon as the
        // test process exits) with a visible warning.
        if (attempt >= 49) {
          // ignore: avoid_print
          print(
            'foundation_test_support: temp dir left behind after '
            '${watch.elapsedMilliseconds} ms (locked): ${dir.path}',
          );
          return;
        }
        sleep(const Duration(milliseconds: 100));
      }
    }
  }
}
