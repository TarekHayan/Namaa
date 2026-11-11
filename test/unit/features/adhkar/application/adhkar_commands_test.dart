import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_commands.dart';
import 'package:namma_project/features/adhkar/application/adhkar_identity_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';

/// T026: the IncrementDhikr and ResetDhikr commands (contracts/
/// adhkar-qiyam-application.md): day and period guards at submission, the
/// at-target no-op, the counting lock while the schedule is unavailable,
/// and a single `now` sample per command.
void main() {
  final now = DateTime.utc(2026, 11, 10, 9);

  late FakeClock clock;
  late FakeTimesPort times;
  late FakeCatalog catalog;
  late FakeRepository repository;
  late AdhkarCommands commands;

  setUp(() {
    clock = FakeClock(now);
    times = FakeTimesPort(
      AdhkarClockState(
        scheduleState: AdhkarScheduleState.available,
        day: '2026-11-10',
        period: AdhkarPeriod.morning,
        nextBoundaryUtc: DateTime.utc(2026, 11, 10, 16, 50),
        morningCountable: true,
        eveningCountable: false,
        fajrUtc: DateTime.utc(2026, 11, 10, 4, 30),
        maghribUtc: DateTime.utc(2026, 11, 10, 16, 50),
        zoneId: 'UTC',
      ),
    );
    catalog = FakeCatalog();
    repository = FakeRepository();
    commands = AdhkarCommands(
      ownerId: 'owner',
      times: times,
      catalog: catalog,
      repository: repository,
      commits: repository,
      clock: clock,
      identity: const FakeIdentity(),
    );
  });

  test('an increment counts once and carries the approved set for '
      'completion', () async {
    repository.seed('owner', '2026-11-10', 'm2', 3);
    final outcome = await commands.increment(
      capturedDay: '2026-11-10',
      itemId: 'm1',
    );
    final incremented = outcome.valueOrNull as AdhkarIncremented;
    expect(incremented.newCount, 1);
    // The morning approved set is m1:1, m2:3; m1 at 1 of 1 completes it.
    expect(incremented.setCompleted, isTrue);
    final request = repository.requests.single;
    expect(request.listItems.map((i) => i.itemId), ['m1', 'm2']);
    expect(request.updatedAt, now, reason: 'now is sampled once and stamped');
    expect(request.setAwardSourceId, 'set:2026-11-10:morning');
  });

  test('an increment below the full set does not complete it', () async {
    final outcome = await commands.increment(
      capturedDay: '2026-11-10',
      itemId: 'm2',
    );
    expect((outcome.valueOrNull as AdhkarIncremented).setCompleted, isFalse);
  });

  test(
    'the prior count is continued and the version stays monotonic',
    () async {
      repository
        ..seededUpdatedAt = now
        ..seed('owner', '2026-11-10', 'm2', 2);
      final outcome = await commands.increment(
        capturedDay: '2026-11-10',
        itemId: 'm2',
      );
      expect((outcome.valueOrNull as AdhkarIncremented).newCount, 3);
      final request = repository.requests.single;
      expect(request.updatedAt, now.add(const Duration(microseconds: 1)));
      expect(request.expectedCurrentVersion, now);
    },
  );

  test(
    'an item at its target is the at-target no-op without a commit',
    () async {
      repository.seed('owner', '2026-11-10', 'm1', 1);
      final outcome = await commands.increment(
        capturedDay: '2026-11-10',
        itemId: 'm1',
      );
      expect(outcome.valueOrNull, isA<AdhkarAtTarget>());
      expect(repository.requests, isEmpty);
    },
  );

  test(
    'a list outside its period is rejected with its start instant',
    () async {
      final outcome = await commands.increment(
        capturedDay: '2026-11-10',
        itemId: 'e1',
      );
      final outside = outcome.valueOrNull as AdhkarOutsidePeriod;
      expect(outside.startsAtUtc, DateTime.utc(2026, 11, 10, 16, 50));
      expect(repository.requests, isEmpty);
    },
  );

  test('a stale captured day is rejected', () async {
    final outcome = await commands.increment(
      capturedDay: '2026-11-09',
      itemId: 'm1',
    );
    expect(outcome.valueOrNull, isA<AdhkarDayChanged>());
    expect(repository.requests, isEmpty);
  });

  test(
    'an unavailable schedule locks counting instead of guessing a day',
    () async {
      times.state = const AdhkarClockState(
        scheduleState: AdhkarScheduleState.unavailable,
        day: null,
        period: null,
        nextBoundaryUtc: null,
        morningCountable: false,
        eveningCountable: false,
        fajrUtc: null,
        maghribUtc: null,
        zoneId: null,
      );
      final outcome = await commands.increment(
        capturedDay: '2026-11-10',
        itemId: 'm1',
      );
      expect(outcome.valueOrNull, isA<AdhkarCountingLocked>());
      expect(repository.requests, isEmpty);
    },
  );

  test('a reset is allowed outside the period and writes zero', () async {
    final outcome = await commands.reset(
      capturedDay: '2026-11-10',
      itemId: 'e1',
    );
    expect(outcome.valueOrNull, isA<AdhkarReset>());
    expect(repository.requests.single.newCount, 0);
  });

  test('a reset on another day is rejected', () async {
    final outcome = await commands.reset(
      capturedDay: '2026-11-08',
      itemId: 'm1',
    );
    expect(outcome.valueOrNull, isA<AdhkarDayChanged>());
    expect(repository.requests, isEmpty);
  });

  test('a read failure propagates instead of counting from zero', () async {
    repository.readFailure = AppFailure.recoverable(
      category: AppFailureCategory.persistence,
      messageKey: 'test.readFailed',
      occurredAt: now,
    );
    final outcome = await commands.increment(
      capturedDay: '2026-11-10',
      itemId: 'm1',
    );
    expect(outcome.failureOrNull!.messageKey, 'test.readFailed');
    expect(repository.requests, isEmpty);
  });

  test('now is sampled exactly once per command', () async {
    await commands.increment(capturedDay: '2026-11-10', itemId: 'm1');
    expect(clock.samples, 1);
    clock.samples = 0;
    await commands.reset(capturedDay: '2026-11-10', itemId: 'm1');
    expect(clock.samples, 1);
  });

  test('a times-port failure propagates without a commit', () async {
    times.failure = AppFailure.recoverable(
      category: AppFailureCategory.persistence,
      messageKey: 'test.timesFailed',
      occurredAt: now,
    );
    final outcome = await commands.increment(
      capturedDay: '2026-11-10',
      itemId: 'm1',
    );
    expect(outcome.failureOrNull, isNotNull);
    expect(repository.requests, isEmpty);
  });
}

final class FakeClock implements AdhkarClockPort {
  FakeClock(this._now);

  final DateTime _now;
  int samples = 0;

  @override
  DateTime nowUtc() {
    samples++;
    return _now;
  }
}

final class FakeTimesPort implements AdhkarTimesPort {
  FakeTimesPort(this.state);

  AdhkarClockState state;
  AppFailure? failure;

  @override
  Future<AppResult<AdhkarClockState>> resolve(
    String ownerId,
    DateTime nowUtc,
  ) async {
    final error = failure;
    if (error != null) {
      return AppResult.failure(error);
    }
    return AppResult.success(state);
  }
}

final class FakeCatalog implements AdhkarCatalogPort {
  @override
  Future<AppResult<AdhkarCatalog>> snapshot(String ownerId) async =>
      AppResult.success(
        AdhkarCatalog.fromJson(const {
          'catalog_version': 1,
          'items': [
            {
              'item_id': 'm1',
              'list': 'morning',
              'position': 1,
              'target': 1,
              'text_ar': 'test m1',
              'translation_en': 'test m1',
              'virtue_ar': 'test virtue m1',
              'virtue_en': 'test virtue m1',
              'reference_ar': 'test ref m1',
              'reference_en': 'test ref m1',
              'approved': true,
            },
            {
              'item_id': 'm2',
              'list': 'morning',
              'position': 2,
              'target': 3,
              'text_ar': 'test m2',
              'translation_en': 'test m2',
              'virtue_ar': 'test virtue m2',
              'virtue_en': 'test virtue m2',
              'reference_ar': 'test ref m2',
              'reference_en': 'test ref m2',
              'approved': true,
            },
            {
              'item_id': 'e1',
              'list': 'evening',
              'position': 1,
              'target': 1,
              'text_ar': 'test e1',
              'translation_en': 'test e1',
              'virtue_ar': 'test virtue e1',
              'virtue_en': 'test virtue e1',
              'reference_ar': 'test ref e1',
              'reference_en': 'test ref e1',
              'approved': true,
            },
          ],
          'qiyam_supplications': <Map<String, Object?>>[],
        }),
      );
}

final class FakeRepository implements AdhkarRepository, AdhkarCountCommitPort {
  final requests = <AdhkarCommitRequest>[];
  final _counts = <String, int>{};

  DateTime seededUpdatedAt = DateTime.utc(2026, 11, 10, 8);

  void seed(String accountId, String day, String itemId, int count) {
    _counts['$accountId|$day|$itemId'] = count;
  }

  AppFailure? readFailure;

  @override
  Future<AppResult<AdhkarCountRecord?>> readFresh({
    required String accountId,
    required String adhkarDay,
    required String itemId,
  }) async {
    final error = readFailure;
    if (error != null) {
      return AppResult.failure(error);
    }
    final count = _counts['$accountId|$adhkarDay|$itemId'];
    return AppResult.success(
      count == null
          ? null
          : AdhkarCountRecord(
              accountId: accountId,
              adhkarDay: adhkarDay,
              itemId: itemId,
              recordId: 'rec',
              catalogVersion: 1,
              list: 'morning',
              count: count,
              createdAt: seededUpdatedAt,
              updatedAt: seededUpdatedAt,
              lastAcknowledgedUpdatedAt: null,
            ),
    );
  }

  @override
  Future<AppResult<void>> writeCount(
    AdhkarCountRecord record, {
    required String operationId,
    required bool queueForSync,
    required bool hadPrior,
  }) async {
    _counts['${record.accountId}|${record.adhkarDay}|${record.itemId}'] =
        record.count;
    return const AppResult.success(null);
  }

  @override
  Future<AppResult<AdhkarCommitOutcome>> commit(AdhkarCommitRequest request) {
    requests.add(request);
    // The real unit of work writes the count inside the transaction before
    // evaluating set completion; the fake mirrors that.
    _counts['${request.accountId}|${request.adhkarDay}|${request.itemId}'] =
        request.newCount;
    final setCompleted = request.listItems.every(
      (item) =>
          (_counts['${request.accountId}|${request.adhkarDay}|${item.itemId}'] ??
              0) >=
          item.target,
    );
    return Future.value(
      AppResult.success(
        AdhkarCommitOutcome(
          wroteCount: true,
          newCount: request.newCount,
          setCompleted: setCompleted,
          awardInserted: false,
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class FakeIdentity implements AdhkarIdentityPort {
  const FakeIdentity();

  @override
  String itemRecordId(String adhkarDay, String itemId) =>
      'rec/$adhkarDay/$itemId';

  @override
  String setAwardSourceId(String adhkarDay, String list) =>
      'set:$adhkarDay:$list';
}
