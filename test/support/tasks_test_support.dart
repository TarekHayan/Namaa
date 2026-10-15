/// Deterministic, non-production fixtures shared by Namaa Tasks tests.
///
/// Nothing in this file reads the wall clock, opens a network connection, or
/// contains a real account credential. Tests opt into every state explicitly.
library;

import 'dart:async';

import 'package:namma_project/core/application/ports/foundation_ports.dart';

/// Stable account partitions for ownership and isolation tests.
const String kTasksTestAccountA = '11111111-1111-1111-1111-111111111111';
const String kTasksTestAccountB = '22222222-2222-2222-2222-222222222222';

/// Stable identifiers for tests that do not need an ID sequence.
const String kTasksTestTaskId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String kTasksTestOperationId = 'tasks-test-operation-0001';

/// A clock whose UTC instant and local calendar offset are controlled by the
/// test. The explicit offset avoids depending on the developer machine's time
/// zone when checking Today and overdue projections.
final class TasksTestClock {
  TasksTestClock({
    DateTime? initialUtc,
    this.localUtcOffset = const Duration(hours: 2),
  }) : _utcNow = initialUtc ?? DateTime.utc(2026, 10, 8, 9) {
    if (!_utcNow.isUtc) {
      throw ArgumentError.value(initialUtc, 'initialUtc', 'must be UTC');
    }
  }

  DateTime _utcNow;

  /// Fixed offset used to derive the deterministic local calendar date.
  final Duration localUtcOffset;

  DateTime utcNow() => _utcNow;

  /// Calendar-only local date for Today/overdue tests.
  DateTime localDate() {
    final local = _utcNow.add(localUtcOffset);
    return DateTime(local.year, local.month, local.day);
  }

  void advance(Duration duration) {
    _utcNow = _utcNow.add(duration);
  }

  void setUtc(DateTime instant) {
    if (!instant.isUtc) {
      throw ArgumentError.value(instant, 'instant', 'must be UTC');
    }
    _utcNow = instant;
  }
}

/// Repeatable Task and outbox ID source for tests.
///
/// A fresh instance always produces the same sequence. Production code must
/// use its real collision-resistant ID generator instead.
final class TasksTestIds {
  int _taskCounter = 0;
  int _operationCounter = 0;

  String nextTaskId() {
    _taskCounter += 1;
    final suffix = _taskCounter.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-4000-8000-$suffix';
  }

  String nextOperationId() {
    _operationCounter += 1;
    return 'tasks-test-operation-${_operationCounter.toString().padLeft(4, '0')}';
  }
}

/// Manually controlled Foundation connectivity port for Tasks tests.
final class TasksTestConnectivity implements ConnectivityPort {
  TasksTestConnectivity({
    ConnectivityStatus initialStatus = ConnectivityStatus.offline,
  }) : _current = initialStatus;

  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast(sync: true);
  ConnectivityStatus _current;

  @override
  ConnectivityStatus get current => _current;

  @override
  Stream<ConnectivityStatus> get changes => _controller.stream;

  void set(ConnectivityStatus status) {
    if (status == _current) {
      return;
    }
    _current = status;
    _controller.add(status);
  }

  void goOnline() => set(ConnectivityStatus.online);

  void goOffline() => set(ConnectivityStatus.offline);

  Future<void> dispose() => _controller.close();
}
