/// Deterministic, non-production fixtures for Habits 004 tests.
///
/// No wall-clock, database, network, or production-account dependency.
library;

/// Stable account partitions for ownership and synchronization tests.
const String kHabitsTestAccountA = '11111111-1111-1111-1111-111111111111';
const String kHabitsTestAccountB = '22222222-2222-2222-2222-222222222222';

/// Stable identities for tests that do not need a generated sequence.
const String kHabitsTestHabitId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String kHabitsTestOtherHabitId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const String kHabitsTestRevisionId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const String kHabitsTestOperationId = 'habits-test-operation-0001';

/// Canonical weekday selections, using Dart's Monday=1 through Sunday=7.
abstract final class HabitsTestSchedules {
  static const Set<int> daily = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  };

  static const Set<int> mondayWednesday = {DateTime.monday, DateTime.wednesday};

  static const Set<int> weekdays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };
}

/// Controlled UTC instant and acting-device offset.
///
/// Changing the offset never changes a previously captured local date.
final class HabitsTestClock {
  HabitsTestClock({
    DateTime? initialUtc,
    Duration localUtcOffset = const Duration(hours: 2),
  }) : _utcNow = initialUtc ?? DateTime.utc(2026, 10, 12, 9),
       _localUtcOffset = localUtcOffset {
    _requireUtc(_utcNow);
    _requireMinuteOffset(_localUtcOffset);
  }

  DateTime _utcNow;
  Duration _localUtcOffset;

  DateTime utcNow() => _utcNow;
  Duration get localUtcOffset => _localUtcOffset;
  int get utcOffsetMinutes => _localUtcOffset.inMinutes;
  DateTime get _localInstant => _utcNow.add(_localUtcOffset);
  int get localWeekday => _localInstant.weekday;

  /// Calendar-only date, independent of the developer machine's time zone.
  String get localDate {
    final local = _localInstant;
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Capture the immutable values used by a day or schedule revision.
  ({String localDate, int utcOffsetMinutes}) captureLocalCalendar() =>
      (localDate: localDate, utcOffsetMinutes: utcOffsetMinutes);

  void advance(Duration duration) {
    _utcNow = _utcNow.add(duration);
  }

  void setUtc(DateTime instant) {
    _requireUtc(instant);
    _utcNow = instant;
  }

  void setLocalUtcOffset(Duration offset) {
    _requireMinuteOffset(offset);
    _localUtcOffset = offset;
  }

  static void _requireUtc(DateTime instant) {
    if (!instant.isUtc) {
      throw ArgumentError.value(instant, 'instant', 'must be UTC');
    }
  }

  static void _requireMinuteOffset(Duration offset) {
    if (offset.inMicroseconds % Duration.microsecondsPerMinute != 0) {
      throw ArgumentError.value(
        offset,
        'localUtcOffset',
        'must use whole minutes',
      );
    }
  }
}

/// Repeatable IDs for separate Habit, revision, outbox and conflict records.
final class HabitsTestIds {
  int _habitCounter = 0;
  int _revisionCounter = 0;
  int _operationCounter = 0;
  int _conflictCounter = 0;

  String nextHabitId() => _uuid(0x8004, ++_habitCounter);
  String nextRevisionId() => _uuid(0x8005, ++_revisionCounter);
  String nextOperationId() =>
      'habits-test-operation-${(++_operationCounter).toString().padLeft(4, '0')}';
  String nextConflictId() => _uuid(0x8006, ++_conflictCounter);

  String _uuid(int variant, int sequence) {
    final group = variant.toRadixString(16).padLeft(4, '0');
    final suffix = sequence.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-4000-$group-$suffix';
  }
}

/// Failure checkpoint for a fake or transactional test store.
///
/// Call [checkpoint] after a row write and before its outbox write to exercise
/// rollback. The future Habit repository port is deliberately not invented.
final class HabitsTestFailingStore {
  int? _failAtCheckpoint;
  int _checkpointCount = 0;

  int get checkpointCount => _checkpointCount;

  void failAtCheckpoint(int number) {
    if (number < 1) {
      throw ArgumentError.value(number, 'number', 'must be positive');
    }
    _checkpointCount = 0;
    _failAtCheckpoint = number;
  }

  void checkpoint() {
    _checkpointCount += 1;
    if (_checkpointCount == _failAtCheckpoint) {
      _failAtCheckpoint = null;
      throw StateError('injected Habits test store failure');
    }
  }

  void reset() {
    _checkpointCount = 0;
    _failAtCheckpoint = null;
  }
}
