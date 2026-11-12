import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/application/adhkar_streak_service.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_state.dart';
import 'package:namma_project/features/qiyam/application/qiyam_clock_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_night_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';
import 'package:namma_project/features/today/application/today_adhkar_qiyam_port.dart';
import 'package:namma_project/features/today/data/adhkar_qiyam_today_adapter.dart';
import 'package:namma_project/features/today/domain/today_adhkar_qiyam_reference.dart';

/// T055: the Today port over the Adhkar/Qiyam application APIs. It exposes
/// Morning x/N, Evening x/N, the current period, tonight's Qiyam state and
/// both derived streaks — read-only, and honestly "unavailable" when the
/// Prayer schedule is down: no day or night is ever invented (owner
/// decision, 2026-11-10). Tonight's explicit "No" does not zero the streak;
/// the walk reuses the existing services (owner decision, 2026-11-12).
void main() {
  final now = DateTime.utc(2026, 11, 12, 9);

  final clockState = AdhkarClockState(
    scheduleState: AdhkarScheduleState.available,
    day: '2026-11-12',
    period: AdhkarPeriod.morning,
    nextBoundaryUtc: DateTime.utc(2026, 11, 12, 16, 50),
    morningCountable: true,
    eveningCountable: false,
    fajrUtc: DateTime.utc(2026, 11, 12, 4, 30),
    maghribUtc: DateTime.utc(2026, 11, 12, 16, 50),
    zoneId: 'Africa/Cairo',
  );

  final nightState = QiyamNightState(
    scheduleState: QiyamScheduleState.available,
    nightDate: '2026-11-12',
    lastThirdUtc: DateTime.utc(2026, 11, 12, 1, 40),
    editable: true,
    nextBoundaryUtc: DateTime.utc(2026, 11, 12, 16, 51),
    zoneId: 'Africa/Cairo',
    zoneOffsetMinutes: 120,
  );

  late FakeAdhkarRepository adhkarRepository;
  late FakeQiyamRepository qiyamRepository;
  late FakeAdhkarTimesPort times;
  late FakeQiyamNightPort nightPort;
  late FakeCatalog catalog;
  late TodayAdhkarQiyamPort port;

  AdhkarCountRecord count(String itemId, String list, int count) =>
      AdhkarCountRecord(
        accountId: 'owner',
        adhkarDay: '2026-11-12',
        itemId: itemId,
        recordId: 'record:$itemId',
        catalogVersion: 1,
        list: list,
        count: count,
        createdAt: now,
        updatedAt: now,
        lastAcknowledgedUpdatedAt: null,
      );

  QiyamNightRecord nightRecord(bool performed) => QiyamNightRecord(
    accountId: 'owner',
    nightDate: '2026-11-12',
    recordId: 'record:night',
    performed: performed,
    rakahs: performed ? 4 : null,
    witr: performed,
    startTime: performed ? '01:00' : null,
    endTime: performed ? '02:00' : null,
    note: null,
    recordedZoneId: 'Africa/Cairo',
    recordedOffsetMinutes: 120,
    createdAt: now,
    updatedAt: now,
    lastAcknowledgedUpdatedAt: null,
  );

  setUp(() {
    adhkarRepository = FakeAdhkarRepository();
    qiyamRepository = FakeQiyamRepository();
    times = FakeAdhkarTimesPort(AppResult.success(clockState));
    nightPort = FakeQiyamNightPort(nightState);
    catalog = FakeCatalog();
    final service = AdhkarStreakService(
      repository: adhkarRepository,
      catalog: catalog,
    );
    port = AdhkarQiyamTodayAdapter(
      times: times,
      clock: FakeAdhkarClock(now),
      catalog: catalog,
      adhkarRepository: adhkarRepository,
      adhkarStreaks: service,
      nightPort: nightPort,
      qiyamClock: FakeQiyamClock(now),
      qiyamRepository: qiyamRepository,
    );
  });

  Future<TodayAdhkarQiyamReference> firstReference() async =>
      await port.watch('owner').first;

  test(
    'exposes Morning x/N, Evening x/N, the period and both streaks',
    () async {
      adhkarRepository
        ..seed(count('m1', 'morning', 1))
        ..seed(count('m2', 'morning', 1))
        ..seed(count('e3', 'evening', 10))
        ..completeDays = {'2026-11-11', '2026-11-10'};
      qiyamRepository
        ..streakToReturn = 3
        ..seedNight = nightRecord(true);

      final reference = await firstReference();
      expect(reference.scheduleUnavailable, isFalse);
      // FR-005 item semantics, the same as AdhkarState: completed
      // counts items at their target; total counts the list's items.
      expect(reference.morningCompleted, 1, reason: 'm1 at target');
      expect(reference.morningTotal, 3);
      expect(reference.eveningCompleted, 1, reason: 'e3 at target');
      expect(reference.eveningTotal, 3);
      expect(reference.adhkarLoadFailed, isFalse);
      expect(reference.qiyamLoadFailed, isFalse);
      expect(reference.period, TodayAdhkarPeriod.morning);
      expect(reference.tonight, TodayQiyamTonight.yes);
      expect(reference.adhkarStreak, 2);
      expect(reference.qiyamStreak, 3);
    },
  );

  test('the x/N values equal the Adhkar screen for the same catalog '
      'and counts (SC-006)', () async {
    adhkarRepository
      ..seed(count('m1', 'morning', 1))
      ..seed(count('m2', 'morning', 3))
      ..seed(count('m3', 'morning', 2))
      ..seed(count('e1', 'evening', 0))
      ..seed(count('e2', 'evening', 3))
      ..completeDays = const {};
    final reference = await firstReference();

    final catalog = (await FakeCatalog().snapshot('owner')).valueOrNull!;
    final screenState = AdhkarState(
      catalog: catalog,
      counts: {
        for (final row in adhkarRepository.seeded) row.itemId: row.count,
      },
    );
    expect(
      reference.morningCompleted,
      screenState.completedOf(AdhkarList.morning),
    );
    expect(reference.morningTotal, screenState.totalOf(AdhkarList.morning));
    expect(
      reference.eveningCompleted,
      screenState.completedOf(AdhkarList.evening),
    );
    expect(reference.eveningTotal, screenState.totalOf(AdhkarList.evening));
    // The concrete values, so a silent change of either side is visible.
    expect(reference.morningCompleted, 2);
    expect(reference.morningTotal, 3);
    expect(reference.eveningCompleted, 1);
    expect(reference.eveningTotal, 3);
  });

  test(
    'an unanswered night is unanswered and an explicit "No" is no',
    () async {
      adhkarRepository.completeDays = const {};
      final unanswered = await firstReference();
      expect(unanswered.tonight, TodayQiyamTonight.unanswered);

      qiyamRepository.seedNight = nightRecord(false);
      final no = await firstReference();
      expect(no.tonight, TodayQiyamTonight.no);
    },
  );

  test('the reference rebuilds when the counts or the record change', () async {
    adhkarRepository.seed(count('m1', 'morning', 1));
    final emissions = <TodayAdhkarQiyamReference>[];
    // ignore: avoid_print
    print('T: before listen');
    final subscription = port.watch('owner').listen(emissions.add);
    await pump();
    // ignore: avoid_print
    print('T: after first pump, emissions=${emissions.length}');
    adhkarRepository.seed(count('m2', 'morning', 3));
    final answered = nightRecord(true);
    qiyamRepository
      ..seedNight = answered
      ..emit(answered);
    await pump();
    // ignore: avoid_print
    print('T: after second pump, emissions=${emissions.length}');
    await pump();
    expect(emissions, hasLength(greaterThanOrEqualTo(3)));
    expect(emissions.first.morningCompleted, 1, reason: 'm1 at target');
    expect(
      emissions.last.morningCompleted,
      2,
      reason: 'm1 and m2 at their targets are two completed items',
    );
    expect(emissions.last.tonight, TodayQiyamTonight.yes);
    await subscription.cancel();
  });

  test('an unavailable schedule locks both sides without inventing a day or '
      'a night', () async {
    times.state = AppResult.failure(
      AppFailure.recoverable(
        category: AppFailureCategory.persistence,
        messageKey: 'adhkar.times.unavailable',
        occurredAt: now,
      ),
    );
    nightPort.state = QiyamNightState(
      scheduleState: QiyamScheduleState.unavailable,
      nightDate: null,
      lastThirdUtc: null,
      editable: false,
      nextBoundaryUtc: null,
      zoneId: null,
      zoneOffsetMinutes: null,
    );
    final reference = await firstReference();
    expect(reference.scheduleUnavailable, isTrue);
    expect(
      reference.adhkarLoadFailed,
      isFalse,
      reason: 'an unavailable schedule is not a failed read',
    );
    expect(reference.qiyamLoadFailed, isFalse);
    expect(reference.period, isNull);
    expect(reference.morningCompleted, 0);
    expect(reference.morningTotal, 0);
    expect(reference.eveningCompleted, 0);
    expect(reference.eveningTotal, 0);
    expect(reference.adhkarStreak, isNull, reason: 'no day to walk from');
    expect(reference.qiyamStreak, isNull, reason: 'no night to walk from');
    expect(reference.tonight, TodayQiyamTonight.locked);
    expect(adhkarRepository.watchDayRequests, isEmpty);
    expect(qiyamRepository.watchedNights, isEmpty);
  });

  test('a failed catalog read is a failure, never zero progress', () async {
    catalog.fails = true;
    final reference = await firstReference();
    expect(reference.adhkarLoadFailed, isTrue);
    expect(reference.adhkarStreak, isNull, reason: 'never a fabricated 0');
    expect(reference.qiyamLoadFailed, isFalse);
  });

  test('a failed counts read is a failure, never zero progress', () async {
    adhkarRepository.countsFail = true;
    final reference = await firstReference();
    expect(reference.adhkarLoadFailed, isTrue);
    expect(reference.qiyamLoadFailed, isFalse);
  });

  test('a failed streak read is a failure, never a streak of 0', () async {
    adhkarRepository.streakFails = true;
    final reference = await firstReference();
    expect(reference.adhkarLoadFailed, isTrue);
    expect(reference.adhkarStreak, isNull);
  });

  test('a failed night record read is a failure, never unanswered', () async {
    qiyamRepository.recordFails = true;
    final reference = await firstReference();
    expect(reference.qiyamLoadFailed, isTrue);
    expect(reference.adhkarLoadFailed, isFalse);
  });

  test(
    'a failed night streak read is a failure, never a streak of 0',
    () async {
      qiyamRepository.streakFails = true;
      final reference = await firstReference();
      expect(reference.qiyamLoadFailed, isTrue);
      expect(reference.qiyamStreak, isNull);
    },
  );

  test('without a saved schedule the device day and night still show, '
      'countable and editable', () async {
    times.state = AppResult.success(
      AdhkarClockState(
        scheduleState: AdhkarScheduleState.setupRequired,
        day: '2026-11-12',
        period: AdhkarPeriod.unrestricted,
        nextBoundaryUtc: DateTime.utc(2026, 11, 13, 12),
        morningCountable: true,
        eveningCountable: true,
        fajrUtc: null,
        maghribUtc: null,
        zoneId: 'Africa/Cairo',
      ),
    );
    nightPort.state = QiyamNightState(
      scheduleState: QiyamScheduleState.setupRequired,
      nightDate: '2026-11-12',
      lastThirdUtc: null,
      editable: true,
      nextBoundaryUtc: DateTime.utc(2026, 11, 13, 12),
      zoneId: 'Africa/Cairo',
      zoneOffsetMinutes: 120,
    );
    adhkarRepository.seed(count('m1', 'morning', 1));
    final reference = await firstReference();
    expect(reference.scheduleUnavailable, isFalse);
    expect(reference.period, TodayAdhkarPeriod.unrestricted);
    expect(reference.morningCompleted, 1);
    expect(reference.tonight, TodayQiyamTonight.unanswered);
    expect(reference.adhkarStreak, 0);
    expect(reference.qiyamStreak, 0);
  });
}

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 10));

final class FakeAdhkarClock implements AdhkarClockPort {
  FakeAdhkarClock(this._now);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}

final class FakeQiyamClock implements QiyamClockPort {
  FakeQiyamClock(this._now);

  final DateTime _now;

  @override
  DateTime nowUtc() => _now;
}

final class FakeAdhkarTimesPort implements AdhkarTimesPort {
  FakeAdhkarTimesPort(this.state);

  AppResult<AdhkarClockState> state;

  @override
  Future<AppResult<AdhkarClockState>> resolve(
    String ownerId,
    DateTime nowUtc,
  ) async => state;
}

final class FakeQiyamNightPort implements QiyamNightPort {
  FakeQiyamNightPort(this.state);

  QiyamNightState state;

  @override
  Future<AppResult<QiyamNightState>> resolve({
    required String ownerId,
    required DateTime nowUtc,
  }) async => AppResult.success(state);
}

final class FakeCatalog implements AdhkarCatalogPort {
  bool fails = false;

  @override
  Future<AppResult<AdhkarCatalog>> snapshot(String ownerId) async {
    if (fails) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'adhkar.catalog.failed',
          occurredAt: DateTime.utc(2026, 11, 12, 9),
        ),
      );
    }
    return AppResult.success(_buildCatalog());
  }

  AdhkarCatalog _buildCatalog() => AdhkarCatalog.fromJson(const {
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
        'item_id': 'm3',
        'list': 'morning',
        'position': 3,
        'target': 10,
        'text_ar': 'test m3',
        'translation_en': 'test m3',
        'virtue_ar': 'test virtue m3',
        'virtue_en': 'test virtue m3',
        'reference_ar': 'test ref m3',
        'reference_en': 'test ref m3',
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
      {
        'item_id': 'e2',
        'list': 'evening',
        'position': 2,
        'target': 3,
        'text_ar': 'test e2',
        'translation_en': 'test e2',
        'virtue_ar': 'test virtue e2',
        'virtue_en': 'test virtue e2',
        'reference_ar': 'test ref e2',
        'reference_en': 'test ref e2',
        'approved': true,
      },
      {
        'item_id': 'e3',
        'list': 'evening',
        'position': 3,
        'target': 10,
        'text_ar': 'test e3',
        'translation_en': 'test e3',
        'virtue_ar': 'test virtue e3',
        'virtue_en': 'test virtue e3',
        'reference_ar': 'test ref e3',
        'reference_en': 'test ref e3',
        'approved': true,
      },
    ],
    'qiyam_supplications': [
      {
        'id': 's1',
        'text_ar': 'test supplication s1',
        'source_ar': 'test source s1',
        'source_en': 'test source s1',
        'approved': true,
      },
      {
        'id': 's2',
        'text_ar': 'test supplication s2',
        'source_ar': 'test source s2',
        'source_en': 'test source s2',
        'approved': true,
      },
    ],
  });
}

final class FakeAdhkarRepository implements AdhkarRepository {
  final _controller = StreamController<List<AdhkarCountRecord>>.broadcast();
  final seeded = <AdhkarCountRecord>[];
  final watchDayRequests = <String>[];
  Set<String> completeDays = const {};
  bool countsFail = false;
  bool streakFails = false;

  void seed(AdhkarCountRecord record) {
    seeded
      ..removeWhere(
        (row) =>
            row.adhkarDay == record.adhkarDay && row.itemId == record.itemId,
      )
      ..add(record);
    _controller.add(List.unmodifiable(seeded));
  }

  @override
  Stream<List<AdhkarCountRecord>> watchDay({
    required String accountId,
    required String adhkarDay,
  }) {
    watchDayRequests.add(adhkarDay);
    return _controller.stream.map(
      (rows) => rows.where((row) => row.adhkarDay == adhkarDay).toList(),
    );
  }

  @override
  Future<AppResult<List<AdhkarCountRecord>>> readListCounts({
    required String accountId,
    required String adhkarDay,
    required String list,
  }) async {
    if (countsFail) return AppResult.failure(_storeFailure());
    return AppResult.success(
      seeded
          .where((row) => row.adhkarDay == adhkarDay && row.list == list)
          .toList(),
    );
  }

  @override
  Future<AppResult<AdhkarCompletedDays>> fullyCompletedDays({
    required String accountId,
    required String lastDay,
    required int maxLookBackDays,
    required int catalogVersion,
    required List<AdhkarListItem> morningItems,
    required List<AdhkarListItem> eveningItems,
  }) async {
    if (streakFails) return AppResult.failure(_storeFailure());
    return AppResult.success(
      AdhkarCompletedDays(completed: completeDays, unjudgeable: const {}),
    );
  }

  AppFailure _storeFailure() => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: 'adhkar.count.store_failed',
    occurredAt: DateTime.utc(2026, 11, 12, 9),
  );

  @override
  Future<AppResult<AdhkarCountRecord?>> readFresh({
    required String accountId,
    required String adhkarDay,
    required String itemId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> writeCount(
    AdhkarCountRecord record, {
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

final class FakeQiyamRepository implements QiyamRepository {
  final _controller = StreamController<QiyamNightRecord?>.broadcast();
  final watchedNights = <String>[];
  QiyamNightRecord? seedNight;
  int streakToReturn = 0;
  bool recordFails = false;
  bool streakFails = false;

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

  void emit(QiyamNightRecord? value) => _controller.add(value);

  @override
  Future<AppResult<QiyamNightRecord?>> readFresh({
    required String accountId,
    required String nightDate,
  }) async {
    if (recordFails) return AppResult.failure(_storeFailure());
    return AppResult.success(
      seedNight?.nightDate == nightDate ? seedNight : null,
    );
  }

  AppFailure _storeFailure() => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: 'qiyam.night.store_failed',
    occurredAt: DateTime.utc(2026, 11, 12, 9),
  );

  @override
  Future<AppResult<int>> streak({
    required String accountId,
    required String currentNight,
  }) async {
    if (streakFails) return AppResult.failure(_storeFailure());
    return AppResult.success(streakToReturn);
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
