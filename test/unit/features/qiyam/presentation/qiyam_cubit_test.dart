import 'dart:async';

import 'package:fake_async/fake_async.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/qiyam/application/qiyam_clock_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_night_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/application/qiyam_supplications_port.dart';
import 'package:namma_project/features/qiyam/application/save_qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_supplication.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_cubit.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_state.dart';

/// T044: the QiyamCubit (contracts/adhkar-qiyam-application.md): the Yes
/// defaults (4 rak'ahs, Witr on), the note debounced by 400 ms and flushed
/// when the screen is left, a refresh at Maghrib and on resume, the
/// stale-generation guard, and a celebration only on the first Yes.
Future<void> drain() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  final now = DateTime.utc(2026, 11, 11, 3);
  final nextBoundary = DateTime.utc(2026, 11, 11, 16, 50);

  late FakeClock clock;
  late FakeNightPort nightPort;
  late FakeRepository repository;
  late FakeCommands commands;

  QiyamNightState availableState([String nightDate = '2026-11-11']) =>
      QiyamNightState(
        scheduleState: QiyamScheduleState.available,
        nightDate: nightDate,
        lastThirdUtc: DateTime.utc(2026, 11, 11, 1, 40),
        editable: true,
        nextBoundaryUtc: nextBoundary,
        zoneId: 'UTC',
        zoneOffsetMinutes: 0,
      );

  QiyamNightRecord record(
    String nightDate, {
    bool performed = true,
    int? rakahs = 4,
    bool witr = true,
    String? note,
  }) => QiyamNightRecord(
    accountId: 'owner',
    nightDate: nightDate,
    recordId: 'record:$nightDate',
    performed: performed,
    rakahs: performed ? rakahs : null,
    witr: performed ? witr : false,
    startTime: performed ? '01:00' : null,
    endTime: performed ? '02:00' : null,
    note: note,
    recordedZoneId: 'UTC',
    recordedOffsetMinutes: 0,
    createdAt: now,
    updatedAt: now,
    lastAcknowledgedUpdatedAt: null,
  );

  setUp(() {
    clock = FakeClock(now);
    nightPort = FakeNightPort(availableState());
    repository = FakeRepository();
    commands = FakeCommands();
  });

  QiyamCubit buildCubit() => QiyamCubit(
    ownerId: 'owner',
    nightPort: nightPort,
    repository: repository,
    supplications: FakeSupplications(),
    commands: commands,
    clock: clock,
  );

  test('load resolves the night and watches the current night', () async {
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    final state = cubit.state;
    expect(state.loading, isFalse);
    expect(state.night?.nightDate, '2026-11-11');
    expect(state.night?.editable, isTrue);
    expect(state.form, isNull, reason: 'the form appears only after Yes');
    expect(repository.watchedNights.single, '2026-11-11');
    await cubit.close();
  });

  test(
    'Yes presents the defaults (4 rak\'ahs, Witr on) and saves them',
    () async {
      final cubit = buildCubit();
      await cubit.load();
      await drain();
      commands.outcome = const QiyamNightSaved(firstPerformed: true);
      await cubit.answerYes();
      await drain();
      expect(cubit.state.form?.performed, isTrue);
      expect(cubit.state.form?.rakahs, 4);
      expect(cubit.state.form?.witr, isTrue);
      final draft = commands.drafts.single;
      expect(draft.performed, isTrue);
      expect(draft.rakahs, 4);
      expect(draft.witr, isTrue);
      expect(commands.capturedNights.single, '2026-11-11');
      await cubit.close();
    },
  );

  test('the first Yes celebrates and a later Yes does not', () async {
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    commands.outcome = const QiyamNightSaved(firstPerformed: true);
    await cubit.answerYes();
    await drain();
    expect(cubit.state.celebration, isTrue);
    commands.outcome = const QiyamNightSaved(firstPerformed: false);
    await cubit.answerYes();
    await drain();
    expect(cubit.state.celebration, isFalse);
    await cubit.close();
  });

  test('No saves the cleared draft with no details', () async {
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    commands.outcome = const QiyamNightSaved(firstPerformed: false);
    await cubit.answerNo();
    await drain();
    final draft = commands.drafts.single;
    expect(draft.performed, isFalse);
    expect(draft.rakahs, isNull);
    expect(draft.witr, isFalse);
    expect(draft.startTime, isNull);
    expect(draft.endTime, isNull);
    expect(draft.note, isNull);
    expect(cubit.state.form?.performed, isFalse);
    await cubit.close();
  });

  test('an existing performed record prefills the form after load', () async {
    repository.emit(record('2026-11-11', rakahs: 8, note: 'kept'));
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    expect(cubit.state.record?.note, 'kept');
    expect(cubit.state.form?.rakahs, 8);
    expect(cubit.state.form?.note, 'kept');
    expect(cubit.state.form?.performed, isTrue);
    await cubit.close();
  });

  test('selecting a rak\'ah chip saves immediately', () async {
    repository.emit(record('2026-11-11'));
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    commands.outcome = const QiyamNightSaved(firstPerformed: false);
    await cubit.selectRakahs(11);
    await drain();
    expect(commands.drafts.single.rakahs, 11);
    expect(cubit.state.actionStatus, QiyamActionStatus.saved);
    await cubit.close();
  });

  test('the note is debounced by 400 ms and flushed when leaving', () {
    FakeAsync().run((async) {
      repository.emit(record('2026-11-11'));
      final cubit = buildCubit();
      var loaded = false;
      cubit.load().then((_) => loaded = true);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(loaded, isTrue);
      commands.outcome = const QiyamNightSaved(firstPerformed: false);
      cubit.updateNote('a quiet night');
      async.elapse(const Duration(milliseconds: 399));
      async.flushMicrotasks();
      expect(commands.drafts, isEmpty, reason: 'not yet debounced');
      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(commands.drafts.single.note, 'a quiet night');
      // A pending note is flushed immediately when the screen is left.
      cubit.updateNote('edited once more');
      async.elapse(const Duration(milliseconds: 100));
      async.flushMicrotasks();
      cubit.flushPendingNote();
      async.flushMicrotasks();
      expect(commands.drafts.last.note, 'edited once more');
      cubit.close();
    });
  });

  test('closing the screen with a pending note saves it', () {
    FakeAsync().run((async) {
      repository.emit(record('2026-11-11'));
      final cubit = buildCubit();
      cubit.load();
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      commands.outcome = const QiyamNightSaved(firstPerformed: false);
      cubit.updateNote('left before the debounce');
      async.elapse(const Duration(milliseconds: 100));
      async.flushMicrotasks();
      expect(commands.drafts, isEmpty);
      cubit.close();
      async.flushMicrotasks();
      expect(commands.drafts.single.note, 'left before the debounce');
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(commands.drafts, hasLength(1), reason: 'no second save');
    });
  });

  test('a plain resume keeps the unsaved note in the form', () async {
    repository.emit(record('2026-11-11'));
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    cubit.updateNote('not saved yet');
    await cubit.resume();
    await drain();
    expect(cubit.state.form?.note, 'not saved yet');
    expect(commands.drafts, isEmpty);
    // Leaving the screen saves the still-pending note.
    commands.outcome = const QiyamNightSaved(firstPerformed: false);
    await cubit.close();
    expect(commands.drafts.single.note, 'not saved yet');
  });

  test('exactly one boundary timer is scheduled and it re-resolves', () {
    FakeAsync().run((async) {
      final cubit = buildCubit();
      var loaded = false;
      cubit.load().then((_) => loaded = true);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(loaded, isTrue);
      expect(async.pendingTimers, hasLength(1));
      final resolvesBefore = nightPort.resolves;
      async.elapse(nextBoundary.difference(now));
      async.flushMicrotasks();
      expect(nightPort.resolves, greaterThan(resolvesBefore));
      async.flushMicrotasks();
      cubit.close();
    });
  });

  test('resume re-resolves the night', () async {
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    final resolvesBefore = nightPort.resolves;
    await cubit.resume();
    expect(nightPort.resolves, resolvesBefore + 1);
    await cubit.close();
  });

  test('a nightChanged outcome refreshes to the new night and resets the '
      'form', () async {
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    commands.outcome = const QiyamNightSaved(firstPerformed: false);
    await cubit.answerYes();
    await drain();
    expect(cubit.state.form, isNotNull);
    commands.outcome = const QiyamNightChanged();
    nightPort.state = availableState('2026-11-12');
    await cubit.answerYes();
    await drain();
    expect(cubit.state.actionStatus, QiyamActionStatus.nightChanged);
    expect(cubit.state.night?.nightDate, '2026-11-12');
    expect(repository.watchedNights.last, '2026-11-12');
    expect(
      cubit.state.form?.rakahs,
      isNull,
      reason: 'the new night starts without a performed form',
    );
    await cubit.close();
  });

  test(
    'a locked outcome shows locked feedback without a saved flash',
    () async {
      final cubit = buildCubit();
      await cubit.load();
      await drain();
      commands.outcome = const QiyamRecordingLocked();
      await cubit.answerYes();
      await drain();
      expect(cubit.state.actionStatus, QiyamActionStatus.locked);
      await cubit.close();
    },
  );

  test(
    'a validation failure surfaces failed feedback with its message key',
    () async {
      final cubit = buildCubit();
      await cubit.load();
      await drain();
      commands.failure = AppFailure.recoverable(
        category: AppFailureCategory.validation,
        messageKey: 'qiyam.night.invalid_time',
        occurredAt: now,
      );
      await cubit.answerYes();
      await drain();
      expect(cubit.state.actionStatus, QiyamActionStatus.failed);
      expect(cubit.state.failureMessageKey, 'qiyam.night.invalid_time');
      await cubit.close();
    },
  );

  test('an unavailable schedule locks the tracker without commands', () async {
    nightPort.state = QiyamNightState(
      scheduleState: QiyamScheduleState.unavailable,
      nightDate: null,
      lastThirdUtc: null,
      editable: false,
      nextBoundaryUtc: null,
      zoneId: null,
      zoneOffsetMinutes: null,
    );
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    expect(cubit.state.recordingLocked, isTrue);
    await cubit.answerYes();
    await drain();
    expect(commands.drafts, isEmpty);
    await cubit.close();
  });

  test(
    'a stale night resolution from an earlier generation is discarded',
    () async {
      final gate = Completer<void>();
      nightPort.gate = gate;
      final cubit = buildCubit();
      final firstLoad = cubit.load();
      await drain();
      // The second resolution finishes first with a different night.
      nightPort.gate = null;
      nightPort.state = availableState('2026-11-12');
      await cubit.resume();
      await drain();
      expect(cubit.state.night?.nightDate, '2026-11-12');
      gate.complete();
      await firstLoad;
      await drain();
      expect(
        cubit.state.night?.nightDate,
        '2026-11-12',
        reason: 'the stale generation never overwrites the newer one',
      );
      await cubit.close();
    },
  );

  test('a record for the watched night updates the state', () async {
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    repository.emit(record('2026-11-11', performed: false));
    await drain();
    expect(cubit.state.record?.performed, isFalse);
    expect(cubit.state.form?.performed, isFalse);
    await cubit.close();
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
  Completer<void>? gate;
  int resolves = 0;

  @override
  Future<AppResult<QiyamNightState>> resolve({
    required String ownerId,
    required DateTime nowUtc,
  }) async {
    resolves++;
    final pending = gate;
    if (pending != null) await pending.future;
    return AppResult.success(state);
  }
}

final class FakeRepository implements QiyamRepository {
  final _controller = StreamController<QiyamNightRecord?>.broadcast();
  final watchedNights = <String>[];
  QiyamNightRecord? current;

  void emit(QiyamNightRecord? value) {
    current = value;
    _controller.add(value);
  }

  @override
  Stream<QiyamNightRecord?> watchNight({
    required String accountId,
    required String nightDate,
  }) {
    watchedNights.add(nightDate);
    return _controller.stream.map((row) {
      if (row == null || row.nightDate != nightDate) return null;
      return row;
    });
  }

  @override
  Future<AppResult<QiyamNightRecord?>> readFresh({
    required String accountId,
    required String nightDate,
  }) async =>
      AppResult.success(current?.nightDate == nightDate ? current : null);

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

final class FakeCommands implements QiyamCommandRunner {
  Object? outcome;
  AppFailure? failure;
  final drafts = <QiyamNightDraft>[];
  final capturedNights = <String>[];

  @override
  Future<AppResult<QiyamCommandOutcome>> execute({
    required String capturedNight,
    required QiyamNightDraft draft,
  }) async {
    capturedNights.add(capturedNight);
    drafts.add(draft);
    final failure = this.failure;
    if (failure != null) return AppResult.failure(failure);
    return AppResult.success(outcome! as QiyamCommandOutcome);
  }
}

final class FakeSupplications implements QiyamSupplicationsPort {
  const FakeSupplications();

  @override
  Future<AppResult<List<QiyamSupplication>>> supplications(
    String ownerId,
  ) async => const AppResult.success([]);
}
