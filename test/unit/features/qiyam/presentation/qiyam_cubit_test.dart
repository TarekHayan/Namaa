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

  test('load fetches the streak and the first history page for the current '
      'night', () async {
    repository.streakToReturn = 5;
    repository.seededNights['2026-11-10'] = record('2026-11-10');
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    expect(cubit.state.streak, 5);
    expect(repository.streakQueries, 1);
    expect(repository.historyQueries, 1);
    expect(repository.historyBounds.single, '2026-11-11');
    expect(cubit.state.history, hasLength(1));
    expect(cubit.state.history.first.nightDate, '2026-11-10');
    expect(cubit.state.history.first.record?.performed, isTrue);
    expect(cubit.state.historyComplete, isTrue);
    await cubit.close();
  });

  test(
    'history entries show "Not recorded" only between loaded records',
    () async {
      repository.seededNights['2026-11-10'] = record('2026-11-10');
      repository.seededNights['2026-11-09'] = record('2026-11-09');
      repository.seededNights['2026-11-06'] = record('2026-11-06');
      final cubit = buildCubit();
      await cubit.load();
      await drain();
      final dates = [for (final entry in cubit.state.history) entry.nightDate];
      expect(dates, [
        '2026-11-10',
        '2026-11-09',
        '2026-11-08',
        '2026-11-07',
        '2026-11-06',
      ]);
      expect(cubit.state.history[2].record, isNull);
      expect(cubit.state.history[3].record, isNull);
      expect(cubit.state.history[4].record, isNotNull);
      await cubit.close();
    },
  );

  test(
    'a new user sees an empty history with no "Not recorded" rows',
    () async {
      final cubit = buildCubit();
      await cubit.load();
      await drain();
      expect(cubit.state.history, isEmpty);
      expect(cubit.state.historyComplete, isTrue);
      expect(repository.historyQueries, 1);
      await cubit.close();
    },
  );

  test('note, time and rak\'ah edits never refresh the streak or the '
      'history', () async {
    repository.emit(record('2026-11-11'));
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    commands.outcome = const QiyamNightSaved(firstPerformed: false);
    for (var i = 0; i < 10; i++) {
      cubit.updateNote('note $i');
      await drain();
    }
    await cubit.flushPendingNote();
    await drain();
    await cubit.selectRakahs(8);
    await drain();
    await cubit.toggleWitr();
    await drain();
    cubit.updateTimes('01:30', '02:30');
    await drain();
    await cubit.flushPendingNote();
    await drain();
    expect(commands.drafts.length, greaterThanOrEqualTo(3));
    expect(
      repository.streakQueries,
      1,
      reason: 'performed never changed, so the streak is not re-read',
    );
    expect(repository.historyQueries, 1);
    await cubit.close();
  });

  test(
    'a save that changes the stored performed state refreshes the streak',
    () async {
      final cubit = buildCubit();
      await cubit.load();
      await drain();
      expect(repository.streakQueries, 1);
      // Answering No on an unrecorded night stores the explicit "No" but
      // changes no streak input (tonight is skipped either way). The save
      // lands in the store, so the watch delivers the row like production.
      commands.outcome = const QiyamNightSaved(firstPerformed: false);
      await cubit.answerNo();
      await drain();
      repository.emit(record('2026-11-11', performed: false));
      await drain();
      expect(repository.streakQueries, 1, reason: 'unanswered -> No');
      commands.outcome = const QiyamNightSaved(firstPerformed: true);
      await cubit.answerYes();
      await drain();
      repository.emit(record('2026-11-11'));
      await drain();
      expect(repository.streakQueries, 2, reason: 'No -> Yes');
      await cubit.selectRakahs(11);
      await drain();
      expect(
        repository.streakQueries,
        2,
        reason: 'a rak\'ah edit keeps performed true',
      );
      await cubit.close();
    },
  );

  test(
    'a save that succeeds after a failed one still refreshes the streak',
    () async {
      final cubit = buildCubit();
      await cubit.load();
      await drain();
      expect(repository.streakQueries, 1);
      commands.outcome = const QiyamNightSaved(firstPerformed: true);
      commands.failure = AppFailure.recoverable(
        category: AppFailureCategory.persistence,
        messageKey: 'qiyam.night.store_failed',
        occurredAt: now,
      );
      await cubit.answerYes();
      await drain();
      expect(cubit.state.actionStatus, QiyamActionStatus.failed);
      expect(
        repository.streakQueries,
        1,
        reason: 'the failed save stored nothing',
      );
      commands.failure = null;
      await cubit.answerYes();
      await drain();
      expect(
        repository.streakQueries,
        2,
        reason:
            'the stored record went from none to performed, though the '
            'form already said Yes',
      );
      await cubit.close();
    },
  );

  test('the night change refreshes the streak and reloads the history; a '
      'plain resume does neither', () async {
    repository.seededNights['2026-11-11'] = record('2026-11-11');
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    expect(repository.historyBounds.single, '2026-11-11');
    await cubit.resume();
    await drain();
    expect(repository.streakQueries, 1, reason: 'same night: no refresh');
    expect(repository.historyQueries, 1);
    nightPort.state = availableState('2026-11-12');
    await cubit.resume();
    await drain();
    expect(repository.streakQueries, 2);
    expect(repository.historyQueries, 2);
    expect(repository.historyBounds.last, '2026-11-12');
    expect(
      cubit.state.history.first.nightDate,
      '2026-11-11',
      reason: 'the night that just ended opens the new first page',
    );
    await cubit.close();
  });

  test(
    'load more fetches only the next recorded page and stops at the end',
    () async {
      for (var i = 1; i <= 35; i++) {
        final night = _offsetDay('2026-11-11', i);
        repository.seededNights[night] = record(night);
      }
      final cubit = buildCubit();
      await cubit.load();
      await drain();
      expect(repository.historyBounds.single, '2026-11-11');
      expect(cubit.state.history, hasLength(30));
      expect(cubit.state.historyComplete, isFalse);
      await cubit.loadMoreHistory();
      await drain();
      expect(repository.historyQueries, 2);
      expect(repository.historyBounds, ['2026-11-11', '2026-10-12']);
      expect(cubit.state.history, hasLength(35));
      expect(cubit.state.historyComplete, isTrue);
      await cubit.loadMoreHistory();
      await drain();
      expect(
        repository.historyQueries,
        2,
        reason: 'no page is fetched beyond the end',
      );
      await cubit.close();
    },
  );

  test('load more across a gap fills only the nights between loaded '
      'records', () async {
    // Thirty consecutive recorded nights, then a gap, then one older row.
    for (var i = 1; i <= 30; i++) {
      final night = _offsetDay('2026-11-11', i);
      repository.seededNights[night] = record(night);
    }
    final oldest = _offsetDay('2026-11-11', 71);
    repository.seededNights[oldest] = record(oldest);
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    expect(cubit.state.history, hasLength(30));
    expect(cubit.state.historyComplete, isFalse);
    await cubit.loadMoreHistory();
    await drain();
    expect(cubit.state.history, hasLength(71));
    expect(cubit.state.history[30].nightDate, '2026-10-11');
    expect(cubit.state.history[30].record, isNull);
    expect(cubit.state.history[69].nightDate, '2026-09-02');
    expect(cubit.state.history.last.nightDate, '2026-09-01');
    expect(cubit.state.history.last.record, isNotNull);
    expect(cubit.state.historyComplete, isTrue);
    await cubit.close();
  });

  test('a streak or history read failure is shown as a failure, never as 0 '
      'or an empty history', () async {
    repository.failStreak = true;
    repository.failHistory = true;
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    expect(cubit.state.streakFailed, isTrue);
    expect(cubit.state.streak, isNull);
    expect(cubit.state.historyFailed, isTrue);
    expect(cubit.state.history, isEmpty);
    expect(cubit.state.historyComplete, isFalse);
    // "Load more" with no pages yet retries the first page.
    repository.seededNights['2026-11-10'] = record('2026-11-10');
    repository.failHistory = false;
    repository.failStreak = false;
    await cubit.loadMoreHistory();
    await drain();
    expect(cubit.state.history, hasLength(1));
    expect(cubit.state.historyFailed, isFalse);
    await cubit.close();
  });

  test('a stale streak result for a superseded refresh never lands', () async {
    final gate = Completer<void>();
    repository.streakGate = gate;
    final cubit = buildCubit();
    final loading = cubit.load();
    await drain();
    // A newer refresh (the night rolled over) supersedes the gated read.
    repository.streakGate = null;
    repository.streakToReturn = 7;
    nightPort.state = availableState('2026-11-12');
    await cubit.resume();
    await drain();
    expect(cubit.state.streak, 7);
    gate.complete();
    await loading;
    await drain();
    expect(
      cubit.state.streak,
      7,
      reason: 'the stale epoch never overwrites the newer value',
    );
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

  /// The stored rows behind the fake history page, keyed by night date.
  final seededNights = <String, QiyamNightRecord>{};
  int streakQueries = 0;
  int historyQueries = 0;
  final historyBounds = <String>[];
  int streakToReturn = 0;
  bool failStreak = false;
  bool failHistory = false;
  Completer<void>? streakGate;

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
  Future<AppResult<int>> streak({
    required String accountId,
    required String currentNight,
  }) async {
    streakQueries++;
    final gate = streakGate;
    if (gate != null) await gate.future;
    if (failStreak) return AppResult.failure(_storageFailure());
    return AppResult.success(streakToReturn);
  }

  @override
  Future<AppResult<QiyamHistoryPage>> history({
    required String accountId,
    required String before,
    int limit = 30,
  }) async {
    historyQueries++;
    historyBounds.add(before);
    if (failHistory) return AppResult.failure(_storageFailure());
    // The real keyset over recorded rows: up to the limit rows strictly
    // before the bound, newest first, one row more telling hasMore.
    final matching =
        seededNights.values
            .where((row) => row.nightDate.compareTo(before) < 0)
            .toList()
          ..sort((a, b) => b.nightDate.compareTo(a.nightDate));
    final hasMore = matching.length > limit;
    return AppResult.success(
      QiyamHistoryPage(
        records: hasMore ? matching.sublist(0, limit) : matching,
        hasMore: hasMore,
      ),
    );
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

AppFailure _storageFailure() => AppFailure.recoverable(
  category: AppFailureCategory.persistence,
  messageKey: 'qiyam.night.store_failed',
  occurredAt: DateTime.utc(2026, 11, 11, 3),
);

String _offsetDay(String before, int backDays) {
  final date = DateTime.utc(
    int.parse(before.substring(0, 4)),
    int.parse(before.substring(5, 7)),
    int.parse(before.substring(8, 10)),
  ).subtract(Duration(days: backDays));
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
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
