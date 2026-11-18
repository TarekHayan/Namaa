import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/qiyam/application/qiyam_clock_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_identity_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_night_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/application/save_qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';

/// T041: the SaveQiyamNight command (contracts/adhkar-qiyam-application.md):
/// the night guard at submission, each typed validation failure, the
/// `saved(firstPerformed)` mapping, and a single `now` sample per command.
/// No command path can write to a night other than the resolved one.
void main() {
  final now = DateTime.utc(2026, 11, 11, 3);

  late FakeClock clock;
  late FakeNightPort nightPort;
  late FakeRepository repository;
  late SaveQiyamNight command;

  QiyamNightState availableState([String nightDate = '2026-11-11']) =>
      QiyamNightState(
        scheduleState: QiyamScheduleState.available,
        nightDate: nightDate,
        lastThirdUtc: DateTime.utc(2026, 11, 11, 1, 40),
        editable: true,
        nextBoundaryUtc: DateTime.utc(2026, 11, 11, 16, 50),
        zoneId: 'UTC',
        zoneOffsetMinutes: 0,
      );

  setUp(() {
    clock = FakeClock(now);
    nightPort = FakeNightPort(availableState());
    repository = FakeRepository();
    command = SaveQiyamNight(
      ownerId: 'owner',
      nightPort: nightPort,
      repository: repository,
      commits: repository,
      clock: clock,
      identity: const FakeIdentity(),
    );
  });

  const performedDraft = QiyamNightDraft(
    performed: true,
    rakahs: 8,
    witr: true,
    startTime: '01:00',
    endTime: '02:00',
  );

  test(
    'a performed Yes saves the resolved night with firstPerformed',
    () async {
      final outcome = await command.execute(
        capturedNight: '2026-11-11',
        draft: performedDraft,
      );
      final saved = outcome.valueOrNull as QiyamNightSaved;
      expect(saved.firstPerformed, isTrue);

      final request = repository.requests.single;
      expect(request.accountId, 'owner');
      expect(request.nightDate, '2026-11-11');
      expect(request.recordId, 'record:2026-11-11');
      expect(request.performed, isTrue);
      expect(request.rakahs, 8);
      expect(request.witr, isTrue);
      expect(request.startTime, '01:00');
      expect(request.endTime, '02:00');
      expect(request.recordedZoneId, 'UTC');
      expect(request.recordedOffsetMinutes, 0);
      expect(request.updatedAt, now, reason: 'now is sampled once and stamped');
      expect(request.operationId, startsWith('qiyam-'));
      expect(request.expectedCurrentVersion, isNull);
      expect(request.acknowledgedBase, isNull);
      expect(request.queueForSync, isTrue);
    },
  );

  test('the debug preview queues nothing for upload', () async {
    final preview = SaveQiyamNight(
      ownerId: 'owner',
      nightPort: nightPort,
      repository: repository,
      commits: repository,
      clock: clock,
      identity: const FakeIdentity(),
      queueForSync: false,
    );
    final outcome = await preview.execute(
      capturedNight: '2026-11-11',
      draft: performedDraft,
    );
    expect(outcome.valueOrNull, isA<QiyamNightSaved>());
    expect(repository.requests.single.queueForSync, isFalse);
  });

  test('an already-awarded Yes maps to firstPerformed false', () async {
    repository.commitOutcome = const QiyamSaveOutcome(
      wroteRecord: true,
      awardInserted: false,
    );
    final outcome = await command.execute(
      capturedNight: '2026-11-11',
      draft: performedDraft,
    );
    expect((outcome.valueOrNull as QiyamNightSaved).firstPerformed, isFalse);
  });

  test('the prior record keeps the version monotonic', () async {
    repository.seed(
      QiyamNightRecord(
        accountId: 'owner',
        nightDate: '2026-11-11',
        recordId: 'record:2026-11-11',
        performed: true,
        rakahs: 4,
        witr: true,
        startTime: '00:30',
        endTime: '01:30',
        note: null,
        recordedZoneId: 'UTC',
        recordedOffsetMinutes: 0,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now,
        lastAcknowledgedUpdatedAt: now.subtract(const Duration(minutes: 30)),
      ),
    );
    const draft = QiyamNightDraft(
      performed: true,
      rakahs: 4,
      witr: true,
      startTime: '01:00',
      endTime: '02:00',
    );
    final outcome = await command.execute(
      capturedNight: '2026-11-11',
      draft: draft,
    );
    expect(outcome.valueOrNull, isA<QiyamNightSaved>());
    final request = repository.requests.single;
    expect(request.updatedAt, now.add(const Duration(microseconds: 1)));
    expect(request.expectedCurrentVersion, now);
    expect(request.acknowledgedBase, now.subtract(const Duration(minutes: 30)));
  });

  test('a stale captured night is rejected without a commit', () async {
    final outcome = await command.execute(
      capturedNight: '2026-11-10',
      draft: performedDraft,
    );
    expect(outcome.valueOrNull, isA<QiyamNightChanged>());
    expect(repository.requests, isEmpty);
  });

  test('an unavailable schedule locks recording instead of guessing', () async {
    nightPort.state = QiyamNightState(
      scheduleState: QiyamScheduleState.unavailable,
      nightDate: null,
      lastThirdUtc: null,
      editable: false,
      nextBoundaryUtc: null,
      zoneId: null,
      zoneOffsetMinutes: null,
    );
    final outcome = await command.execute(
      capturedNight: '2026-11-11',
      draft: performedDraft,
    );
    expect(outcome.valueOrNull, isA<QiyamRecordingLocked>());
    expect(repository.requests, isEmpty);
  });

  test('a save under setupRequired uses the device zone context', () async {
    nightPort.state = QiyamNightState(
      scheduleState: QiyamScheduleState.setupRequired,
      nightDate: '2026-11-10',
      lastThirdUtc: null,
      editable: true,
      nextBoundaryUtc: DateTime.utc(2026, 11, 11, 10),
      zoneId: 'UTC+02:00',
      zoneOffsetMinutes: 120,
    );
    final outcome = await command.execute(
      capturedNight: '2026-11-10',
      draft: performedDraft,
    );
    expect(outcome.valueOrNull, isA<QiyamNightSaved>());
    final request = repository.requests.single;
    expect(request.nightDate, '2026-11-10');
    expect(request.recordId, 'record:2026-11-10');
    expect(request.recordedZoneId, 'UTC+02:00');
    expect(request.recordedOffsetMinutes, 120);
  });

  test('an invalid rak\'ah count is rejected with a typed failure', () async {
    final outcome = await command.execute(
      capturedNight: '2026-11-11',
      draft: const QiyamNightDraft(
        performed: true,
        rakahs: 3,
        witr: true,
        startTime: '01:00',
        endTime: '02:00',
      ),
    );
    expect(outcome.failureOrNull!.messageKey, 'qiyam.night.invalid_rakahs');
    expect(outcome.failureOrNull!.category, AppFailureCategory.validation);
    expect(repository.requests, isEmpty);
  });

  test('an invalid time is rejected with a typed failure', () async {
    final outcome = await command.execute(
      capturedNight: '2026-11-11',
      draft: const QiyamNightDraft(
        performed: true,
        rakahs: 8,
        witr: true,
        startTime: '25:00',
        endTime: '02:00',
      ),
    );
    expect(outcome.failureOrNull!.messageKey, 'qiyam.night.invalid_time');
    expect(repository.requests, isEmpty);
  });

  test('an over-long note is rejected with a typed failure', () async {
    final outcome = await command.execute(
      capturedNight: '2026-11-11',
      draft: QiyamNightDraft(
        performed: true,
        rakahs: 8,
        witr: true,
        startTime: '01:00',
        endTime: '02:00',
        note: 'n' * 501,
      ),
    );
    expect(outcome.failureOrNull!.messageKey, 'qiyam.night.note_too_long');
    expect(repository.requests, isEmpty);
  });

  test('details with No are rejected with a typed failure', () async {
    final outcome = await command.execute(
      capturedNight: '2026-11-11',
      draft: const QiyamNightDraft(performed: false, rakahs: 2),
    );
    expect(
      outcome.failureOrNull!.messageKey,
      'qiyam.night.not_performed_details',
    );
    expect(repository.requests, isEmpty);
  });

  test('a read failure propagates instead of writing a blind row', () async {
    repository.readFailure = AppFailure.recoverable(
      category: AppFailureCategory.persistence,
      messageKey: 'test.readFailed',
      occurredAt: now,
    );
    final outcome = await command.execute(
      capturedNight: '2026-11-11',
      draft: performedDraft,
    );
    expect(outcome.failureOrNull!.messageKey, 'test.readFailed');
    expect(repository.requests, isEmpty);
  });

  test('a commit failure propagates', () async {
    repository.commitFailure = AppFailure.recoverable(
      category: AppFailureCategory.persistence,
      messageKey: 'test.commitFailed',
      occurredAt: now,
    );
    final outcome = await command.execute(
      capturedNight: '2026-11-11',
      draft: performedDraft,
    );
    expect(outcome.failureOrNull!.messageKey, 'test.commitFailed');
  });

  test('a night-port failure propagates without a commit', () async {
    nightPort.failure = AppFailure.recoverable(
      category: AppFailureCategory.persistence,
      messageKey: 'test.nightFailed',
      occurredAt: now,
    );
    final outcome = await command.execute(
      capturedNight: '2026-11-11',
      draft: performedDraft,
    );
    expect(outcome.failureOrNull!.messageKey, 'test.nightFailed');
    expect(repository.requests, isEmpty);
  });

  test('now is sampled exactly once per command', () async {
    await command.execute(capturedNight: '2026-11-11', draft: performedDraft);
    expect(clock.samples, 1);
  });

  test('no path writes a night other than the resolved one', () async {
    // A prior record exists for the previous night only; the save targets
    // the resolved night and starts from no prior version.
    repository.seed(
      QiyamNightRecord(
        accountId: 'owner',
        nightDate: '2026-11-10',
        recordId: 'record:2026-11-10',
        performed: false,
        rakahs: null,
        witr: false,
        startTime: null,
        endTime: null,
        note: null,
        recordedZoneId: 'UTC',
        recordedOffsetMinutes: 0,
        createdAt: DateTime.utc(2026, 11, 10, 20),
        updatedAt: DateTime.utc(2026, 11, 10, 20),
        lastAcknowledgedUpdatedAt: null,
      ),
    );
    final outcome = await command.execute(
      capturedNight: '2026-11-11',
      draft: performedDraft,
    );
    expect(outcome.valueOrNull, isA<QiyamNightSaved>());
    final request = repository.requests.single;
    expect(request.nightDate, '2026-11-11');
    expect(request.expectedCurrentVersion, isNull);
  });
}

final class FakeClock implements QiyamClockPort {
  FakeClock(this.value);

  DateTime value;
  int samples = 0;

  @override
  DateTime nowUtc() {
    samples++;
    return value;
  }
}

final class FakeNightPort implements QiyamNightPort {
  FakeNightPort(this.state);

  QiyamNightState state;
  AppFailure? failure;

  @override
  Future<AppResult<QiyamNightState>> resolve({
    required String ownerId,
    required DateTime nowUtc,
  }) async {
    final failure = this.failure;
    if (failure != null) return AppResult.failure(failure);
    return AppResult.success(state);
  }
}

final class FakeRepository implements QiyamRepository, QiyamNightCommitPort {
  QiyamNightRecord? prior;
  AppFailure? readFailure;
  AppFailure? commitFailure;
  QiyamSaveOutcome commitOutcome = const QiyamSaveOutcome(
    wroteRecord: true,
    awardInserted: true,
  );
  final List<QiyamSaveRequest> requests = [];

  void seed(QiyamNightRecord record) => prior = record;

  @override
  Future<AppResult<QiyamNightRecord?>> readFresh({
    required String accountId,
    required String nightDate,
  }) async {
    final failure = readFailure;
    if (failure != null) return AppResult.failure(failure);
    final stored = prior;
    if (stored == null ||
        stored.accountId != accountId ||
        stored.nightDate != nightDate) {
      return const AppResult.success(null);
    }
    return AppResult.success(stored);
  }

  @override
  Future<AppResult<QiyamSaveOutcome>> commit(QiyamSaveRequest request) async {
    final failure = commitFailure;
    if (failure != null) return AppResult.failure(failure);
    requests.add(request);
    return AppResult.success(commitOutcome);
  }

  @override
  Stream<QiyamNightRecord?> watchNight({
    required String accountId,
    required String nightDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<int>> streak({
    required String accountId,
    required String currentNight,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<QiyamHistoryPage>> history({
    required String accountId,
    required String before,
    int limit = 30,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> writeNight(
    QiyamNightRecord record, {
    required String operationId,
    required bool queueForSync,
    required bool hadPrior,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) {
    throw UnimplementedError();
  }
}

final class FakeIdentity implements QiyamIdentityPort {
  const FakeIdentity();

  @override
  String nightRecordId(String nightDate) => 'record:$nightDate';
}
