import 'dart:async';

import 'package:fake_async/fake_async.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_commands.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_cubit.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_state.dart';

/// T029: the AdhkarCubit (contracts/adhkar-qiyam-application.md): the initial
/// tab follows the period, one boundary timer plus a refresh on resume, a
/// one-shot celebration per completed set, and per-item pending/saved/failed
/// feedback. Results that arrive after the cubit closed are dropped.
Future<void> drain() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  final now = DateTime.utc(2026, 11, 10, 9);
  final nextBoundary = DateTime.utc(2026, 11, 10, 16, 50);

  late FakeClock clock;
  late FakeTimesPort times;
  late FakeCatalog catalog;
  late FakeRepository repository;
  late FakeCommands commands;

  AdhkarCubit buildCubit() => AdhkarCubit(
    ownerId: 'owner',
    times: times,
    catalog: catalog,
    repository: repository,
    commands: commands,
    clock: clock,
  );

  setUp(() {
    clock = FakeClock(now);
    times = FakeTimesPort(
      AdhkarClockState(
        scheduleState: AdhkarScheduleState.available,
        day: '2026-11-10',
        period: AdhkarPeriod.morning,
        nextBoundaryUtc: nextBoundary,
        morningCountable: true,
        eveningCountable: false,
        fajrUtc: DateTime.utc(2026, 11, 10, 4, 30),
        maghribUtc: DateTime.utc(2026, 11, 10, 16, 50),
        zoneId: 'UTC',
      ),
    );
    catalog = FakeCatalog();
    repository = FakeRepository();
    commands = FakeCommands();
  });

  test('the initial load selects the tab for the current period and loads '
      'the day counts', () async {
    repository.dayCounts = [
      AdhkarCountRecord(
        accountId: 'owner',
        adhkarDay: '2026-11-10',
        itemId: 'm1',
        recordId: 'rec',
        catalogVersion: 1,
        list: 'morning',
        count: 2,
        createdAt: now,
        updatedAt: now,
        lastAcknowledgedUpdatedAt: null,
      ),
    ];
    final cubit = buildCubit();
    await cubit.load();
    await drain();
    final state = cubit.state;
    expect(state.catalog?.version, 1);
    expect(state.clock?.day, '2026-11-10');
    expect(state.selectedTab, AdhkarTab.morning);
    expect(state.counts, {'m1': 2});
    expect(state.streak, 0);
    await cubit.close();
  });

  test('the selected tab follows an Evening period clock', () async {
    times.state = AdhkarClockState(
      scheduleState: AdhkarScheduleState.available,
      day: '2026-11-10',
      period: AdhkarPeriod.evening,
      nextBoundaryUtc: DateTime.utc(2026, 11, 11, 4, 29),
      morningCountable: false,
      eveningCountable: true,
      fajrUtc: DateTime.utc(2026, 11, 10, 4, 30),
      maghribUtc: DateTime.utc(2026, 11, 10, 16, 50),
      zoneId: 'UTC',
    );
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.selectedTab, AdhkarTab.evening);
    await cubit.close();
  });

  test('an unavailable schedule keeps the screen but locks counting', () async {
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
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.clock?.scheduleState, AdhkarScheduleState.unavailable);
    expect(cubit.state.countingLocked, isTrue);
    await cubit.close();
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
      final resolvesBefore = times.resolves;
      async.elapse(nextBoundary.difference(now));
      async.flushMicrotasks();
      expect(times.resolves, greaterThan(resolvesBefore));
      async.flushMicrotasks();
      cubit.close();
    });
  });

  test('resume re-resolves the clock', () async {
    final cubit = buildCubit();
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    final resolvesBefore = times.resolves;
    await cubit.resume();
    expect(times.resolves, resolvesBefore + 1);
    await cubit.close();
  });

  test('an increment shows pending then saved feedback and updates the '
      'count', () async {
    commands.outcome = const AdhkarIncremented(
      newCount: 3,
      setCompleted: false,
    );
    final cubit = buildCubit();
    final emissions = <AdhkarState>[];
    final sub = cubit.stream.listen(emissions.add);
    await cubit.load();
    emissions.clear();
    await cubit.increment('m2', '2026-11-10');
    await drain();
    expect(
      emissions.any((s) => s.itemStatus['m2'] == AdhkarActionStatus.pending),
      isTrue,
    );
    expect(emissions.last.itemStatus['m2'], AdhkarActionStatus.saved);
    expect(emissions.last.counts['m2'], 3);
    await cubit.close();
    await sub.cancel();
  });

  test('a failed command surfaces failed feedback for the item', () async {
    commands.failure = AppFailure.recoverable(
      category: AppFailureCategory.validation,
      messageKey: 'adhkar.count.stale_count',
      occurredAt: now,
    );
    final cubit = buildCubit();
    final emissions = <AdhkarState>[];
    final sub = cubit.stream.listen(emissions.add);
    await cubit.load();
    emissions.clear();
    await cubit.increment('m1', '2026-11-10');
    await drain();
    expect(
      emissions.any((s) => s.itemStatus['m1'] == AdhkarActionStatus.pending),
      isTrue,
    );
    expect(emissions.last.itemStatus['m1'], AdhkarActionStatus.failed);
    await cubit.close();
    await sub.cancel();
  });

  test('a completed set emits the celebration exactly once', () async {
    commands.outcome = const AdhkarIncremented(newCount: 1, setCompleted: true);
    final cubit = buildCubit();
    final emissions = <AdhkarState>[];
    final sub = cubit.stream.listen(emissions.add);
    await cubit.load();
    emissions.clear();
    await cubit.increment('m1', '2026-11-10');
    await drain();
    // One-shot = one TRANSITION into the celebration; later states carry it
    // until the next command starts.
    var celebrations = 0;
    for (var i = 0; i < emissions.length; i++) {
      final now = emissions[i].celebration;
      if (now != null && (i == 0 || emissions[i - 1].celebration == null)) {
        celebrations++;
      }
    }
    expect(celebrations, 1);
    expect(
      emissions.last.celebration,
      AdhkarTab.morning,
      reason: 'the celebration persists until the next command',
    );
    await cubit.close();
    await sub.cancel();
  });

  test('results that arrive after the cubit closed are dropped', () async {
    final cubit = buildCubit();
    final emissions = <AdhkarState>[];
    final sub = cubit.stream.listen(emissions.add);
    final loading = cubit.load();
    await cubit.close();
    await loading;
    await Future<void>.delayed(Duration.zero);
    final lastEmitted = emissions.isEmpty ? null : emissions.last;
    expect(
      lastEmitted?.loading ?? true,
      isNot(isFalse),
      reason: 'no post-close loading-completed state is required',
    );
    await sub.cancel();
  });
}

final class FakeClock implements AdhkarClockPort {
  FakeClock(this._now);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}

final class FakeTimesPort implements AdhkarTimesPort {
  FakeTimesPort(this.state);

  AdhkarClockState state;
  var resolves = 0;

  @override
  Future<AppResult<AdhkarClockState>> resolve(
    String ownerId,
    DateTime nowUtc,
  ) async {
    resolves++;
    return AppResult.success(state);
  }
}

final class FakeCatalog implements AdhkarCatalogPort {
  @override
  Future<AppResult<AdhkarCatalogSnapshot>> snapshot(String ownerId) async =>
      AppResult.success(
        const AdhkarCatalogSnapshot(
          version: 1,
          items: [
            AdhkarCatalogItemSnapshot(
              itemId: 'm1',
              list: 'morning',
              position: 1,
              target: 1,
              textAr: 'test m1',
              translationEn: 'test m1',
              virtueAr: 'test virtue m1',
              virtueEn: 'test virtue m1',
              referenceAr: 'test ref m1',
              referenceEn: 'test ref m1',
            ),
            AdhkarCatalogItemSnapshot(
              itemId: 'm2',
              list: 'morning',
              position: 2,
              target: 3,
              textAr: 'test m2',
              translationEn: 'test m2',
              virtueAr: 'test virtue m2',
              virtueEn: 'test virtue m2',
              referenceAr: 'test ref m2',
              referenceEn: 'test ref m2',
            ),
            AdhkarCatalogItemSnapshot(
              itemId: 'e1',
              list: 'evening',
              position: 1,
              target: 1,
              textAr: 'test e1',
              translationEn: 'test e1',
              virtueAr: 'test virtue e1',
              virtueEn: 'test virtue e1',
              referenceAr: 'test ref e1',
              referenceEn: 'test ref e1',
            ),
          ],
        ),
      );
}

final class FakeRepository implements AdhkarRepository {
  final _controller = StreamController<List<AdhkarCountRecord>>.broadcast();
  List<AdhkarCountRecord> dayCounts = const [];

  @override
  Stream<List<AdhkarCountRecord>> watchDay({
    required String accountId,
    required String adhkarDay,
  }) async* {
    yield dayCounts;
    yield* _controller.stream;
  }

  void emitCounts(List<AdhkarCountRecord> rows) => _controller.add(rows);

  @override
  Future<AppResult<Set<String>>> fullyCompletedDays({
    required String accountId,
    required String lastDay,
    required int maxLookBackDays,
  }) async => AppResult.success(const <String>{});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class FakeCommands implements AdhkarCommandRunner {
  AdhkarCommandOutcome? outcome;
  AppFailure? failure;

  @override
  Future<AppResult<AdhkarCommandOutcome>> increment({
    required String capturedDay,
    required String itemId,
  }) async => _result();

  @override
  Future<AppResult<AdhkarCommandOutcome>> reset({
    required String capturedDay,
    required String itemId,
  }) async => _result();

  AppResult<AdhkarCommandOutcome> _result() {
    final error = failure;
    if (error != null) {
      return AppResult.failure(error);
    }
    return AppResult.success(outcome!);
  }
}
