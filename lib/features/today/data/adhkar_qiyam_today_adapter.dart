import 'dart:async';

import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/application/adhkar_streak_service.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/qiyam/application/qiyam_clock_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_night_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';

import '../application/today_adhkar_qiyam_port.dart';
import '../domain/today_adhkar_qiyam_reference.dart';

/// Builds the read-only Today reference over the Adhkar/Qiyam application
/// APIs only — never their Drift tables (T056). The day and night are
/// resolved once per subscription; every change of the day's counts or the
/// night's record rebuilds the whole reference. When the Prayer schedule is
/// unavailable nothing is invented: the counts read 0/0, the streaks stay
/// null and tonight is locked (owner decision, 2026-11-10).
final class AdhkarQiyamTodayAdapter implements TodayAdhkarQiyamPort {
  const AdhkarQiyamTodayAdapter({
    required AdhkarTimesPort times,
    required AdhkarClockPort clock,
    required AdhkarCatalogPort catalog,
    required AdhkarRepository adhkarRepository,
    required AdhkarStreakService adhkarStreaks,
    required QiyamNightPort nightPort,
    required QiyamClockPort qiyamClock,
    required QiyamRepository qiyamRepository,
  }) : _times = times,
       _clock = clock,
       _catalog = catalog,
       _adhkar = adhkarRepository,
       _adhkarStreaks = adhkarStreaks,
       _nightPort = nightPort,
       _qiyamClock = qiyamClock,
       _qiyam = qiyamRepository;

  final AdhkarTimesPort _times;
  final AdhkarClockPort _clock;
  final AdhkarCatalogPort _catalog;
  final AdhkarRepository _adhkar;
  final AdhkarStreakService _adhkarStreaks;
  final QiyamNightPort _nightPort;
  final QiyamClockPort _qiyamClock;
  final QiyamRepository _qiyam;

  @override
  Stream<TodayAdhkarQiyamReference> watch(String ownerId) {
    // One time sample per subscription: Today's dashboard re-subscribes on
    // resume, and a change of day or night arrives through T058's wiring.
    // The counts and record watches only signal changes; every rebuild
    // reads fresh values so an emission never carries a stale snapshot.
    AdhkarClockState? clockState;
    AppResult<QiyamNightState>? nightState;

    // A change arriving mid-build is folded in by one further rebuild: the
    // rebuild reads fresh values, so the last emission always carries the
    // latest state (a dropped change would leave the reference stale).
    var rebuildQueued = false;
    Future<void> scheduleRebuild(
      StreamController<TodayAdhkarQiyamReference> out,
    ) async {
      if (rebuildQueued) return;
      rebuildQueued = true;
      try {
        while (true) {
          rebuildQueued = false;
          final reference = await _build(ownerId, clockState, nightState!);
          out.add(reference);
          if (!rebuildQueued) return;
        }
      } finally {
        rebuildQueued = false;
      }
    }

    final subscriptions = <StreamSubscription<void>>[];
    late final StreamController<TodayAdhkarQiyamReference> controller;
    controller = StreamController<TodayAdhkarQiyamReference>(
      onListen: () async {
        clockState = (await _times.resolve(
          ownerId,
          _clock.nowUtc(),
        )).valueOrNull;
        nightState = await _nightPort.resolve(
          ownerId: ownerId,
          nowUtc: _qiyamClock.nowUtc(),
        );
        final resolvedClock = clockState;
        final adhkarAvailable =
            resolvedClock != null &&
            resolvedClock.scheduleState != AdhkarScheduleState.unavailable;
        final night = nightState?.valueOrNull;
        final qiyamAvailable =
            night != null &&
            night.scheduleState != QiyamScheduleState.unavailable;
        final adhkarDay = adhkarAvailable ? resolvedClock.day : null;
        final nightDate = qiyamAvailable ? night.nightDate : null;
        if (adhkarDay != null) {
          subscriptions.add(
            _adhkar
                .watchDay(accountId: ownerId, adhkarDay: adhkarDay)
                .listen((_) => unawaited(scheduleRebuild(controller))),
          );
        }
        if (nightDate != null) {
          subscriptions.add(
            _qiyam
                .watchNight(accountId: ownerId, nightDate: nightDate)
                .listen((_) => unawaited(scheduleRebuild(controller))),
          );
        }
        await scheduleRebuild(controller);
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        subscriptions.clear();
      },
    );
    return controller.stream;
  }

  Future<TodayAdhkarQiyamReference> _build(
    String ownerId,
    AdhkarClockState? clockState,
    AppResult<QiyamNightState> nightState,
  ) async {
    // Adhkar side. FR-005 item semantics, the same as AdhkarState:
    // completed counts the items at their target; total counts the list's
    // items. A failed read raises its flag instead of masquerading as zero
    // progress (Phase 6 review finding 2).
    final adhkarAvailable =
        clockState != null &&
        clockState.scheduleState != AdhkarScheduleState.unavailable;
    final day = adhkarAvailable ? clockState.day : null;
    var morningCompleted = 0;
    var eveningCompleted = 0;
    var morningTotal = 0;
    var eveningTotal = 0;
    var adhkarLoadFailed = false;
    int? adhkarStreak;
    TodayAdhkarPeriod? period;
    if (adhkarAvailable && day != null) {
      final catalogResult = await _catalog.snapshot(ownerId);
      final catalog = catalogResult.valueOrNull;
      if (catalog == null) {
        adhkarLoadFailed = true;
      } else {
        final morningCountsResult = await _readCounts(ownerId, day, 'morning');
        final eveningCountsResult = await _readCounts(ownerId, day, 'evening');
        final morningCounts = morningCountsResult.valueOrNull;
        final eveningCounts = eveningCountsResult.valueOrNull;
        if (morningCounts == null || eveningCounts == null) {
          adhkarLoadFailed = true;
        } else {
          for (final item in catalog.itemsOf(AdhkarList.morning)) {
            if (_countOf(morningCounts, item.itemId) >= item.target) {
              morningCompleted++;
            }
          }
          morningTotal = catalog.itemsOf(AdhkarList.morning).length;
          for (final item in catalog.itemsOf(AdhkarList.evening)) {
            if (_countOf(eveningCounts, item.itemId) >= item.target) {
              eveningCompleted++;
            }
          }
          eveningTotal = catalog.itemsOf(AdhkarList.evening).length;
        }
      }
      final streakResult = await _adhkarStreaks.streak(
        ownerId: ownerId,
        today: day,
      );
      adhkarStreak = streakResult.valueOrNull;
      if (streakResult.failureOrNull != null) {
        adhkarLoadFailed = true;
      }
      period = switch (clockState.period) {
        AdhkarPeriod.morning => TodayAdhkarPeriod.morning,
        AdhkarPeriod.evening => TodayAdhkarPeriod.evening,
        AdhkarPeriod.unrestricted => TodayAdhkarPeriod.unrestricted,
        null => null,
      };
    }

    // Qiyam side.
    final night = nightState.valueOrNull;
    final qiyamAvailable =
        night != null && night.scheduleState != QiyamScheduleState.unavailable;
    var tonight = TodayQiyamTonight.locked;
    var qiyamLoadFailed = false;
    int? qiyamStreak;
    if (qiyamAvailable && night.nightDate != null) {
      final recordResult = await _qiyam.readFresh(
        accountId: ownerId,
        nightDate: night.nightDate!,
      );
      final record = recordResult.valueOrNull;
      if (recordResult.failureOrNull != null) {
        qiyamLoadFailed = true;
      } else {
        tonight = record == null
            ? TodayQiyamTonight.unanswered
            : (record.performed ? TodayQiyamTonight.yes : TodayQiyamTonight.no);
      }
      final streakResult = await _qiyam.streak(
        accountId: ownerId,
        currentNight: night.nightDate!,
      );
      qiyamStreak = streakResult.valueOrNull;
      if (streakResult.failureOrNull != null) {
        qiyamLoadFailed = true;
      }
    }

    return TodayAdhkarQiyamReference(
      ownerId: ownerId,
      scheduleUnavailable: !adhkarAvailable,
      adhkarLoadFailed: adhkarLoadFailed,
      morningCompleted: morningCompleted,
      morningTotal: morningTotal,
      eveningCompleted: eveningCompleted,
      eveningTotal: eveningTotal,
      period: period,
      qiyamLoadFailed: qiyamLoadFailed,
      tonight: tonight,
      adhkarStreak: adhkarStreak,
      qiyamStreak: qiyamStreak,
    );
  }

  Future<AppResult<List<AdhkarCountRecord>>> _readCounts(
    String ownerId,
    String day,
    String list,
  ) => _adhkar.readListCounts(accountId: ownerId, adhkarDay: day, list: list);

  int _countOf(List<AdhkarCountRecord> counts, String itemId) {
    for (final row in counts) {
      if (row.itemId == itemId) return row.count;
    }
    return 0;
  }
}
