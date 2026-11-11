import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_commands.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_streak.dart';

import 'adhkar_state.dart';

/// The Adhkar screen state holder (contracts/adhkar-qiyam-application.md):
/// it loads the catalog, the clock and the day counts, selects the tab for
/// the current period, schedules ONE timer for the next boundary (plus a
/// refresh on resume), and reports per-item command feedback. A completed
/// set emits a one-shot celebration. Nothing is emitted after close.
final class AdhkarCubit extends Cubit<AdhkarState> {
  AdhkarCubit({
    required String ownerId,
    required AdhkarTimesPort times,
    required AdhkarCatalogPort catalog,
    required AdhkarRepository repository,
    required AdhkarCommandRunner commands,
    required AdhkarClockPort clock,
  }) : _ownerId = ownerId,
       _times = times,
       _catalog = catalog,
       _repository = repository,
       _commands = commands,
       _clock = clock,
       super(const AdhkarState());

  final String _ownerId;
  final AdhkarTimesPort _times;
  final AdhkarCatalogPort _catalog;
  final AdhkarRepository _repository;
  final AdhkarCommandRunner _commands;
  final AdhkarClockPort _clock;

  Timer? _boundaryTimer;
  StreamSubscription<List<AdhkarCountRecord>>? _countsSubscription;
  String? _watchedDay;
  AdhkarPeriod? _lastPeriod;
  bool _disposed = false;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final catalog = await _catalog.snapshot(_ownerId);
    if (_disposed) return;
    if (catalog.valueOrNull case final snapshot?) {
      emit(state.copyWith(catalog: snapshot));
    }
    await _refreshClock();
    if (_disposed) return;
    unawaited(_refreshStreak());
    emit(state.copyWith(loading: false, clearCelebration: true));
  }

  /// Re-resolves the clock when the app resumes (contract lifecycle).
  Future<void> resume() => _refreshClock();

  void selectTab(AdhkarTab tab) {
    if (state.selectedTab != tab) {
      emit(state.copyWith(selectedTab: tab));
    }
  }

  Future<void> increment(String itemId, String capturedDay) =>
      _runCommand(itemId, capturedDay, isIncrement: true);

  Future<void> reset(String itemId, String capturedDay) =>
      _runCommand(itemId, capturedDay, isIncrement: false);

  Future<void> _runCommand(
    String itemId,
    String capturedDay, {
    required bool isIncrement,
  }) async {
    if (state.countingLocked) return;
    // Judge the list's completion before the command runs: the day's counts
    // stream can deliver the new row before the command returns, which would
    // hide the completion change that gates the streak refresh.
    final list = state.catalog?.item(itemId)?.list;
    final wasComplete = _listComplete(list, state.counts);
    emit(
      state.copyWith(
        itemStatus: {...state.itemStatus, itemId: AdhkarActionStatus.pending},
        clearCelebration: true,
      ),
    );
    final result = isIncrement
        ? await _commands.increment(capturedDay: capturedDay, itemId: itemId)
        : await _commands.reset(capturedDay: capturedDay, itemId: itemId);
    if (_disposed) return;
    if (result.failureOrNull != null) {
      emit(
        state.copyWith(
          itemStatus: {...state.itemStatus, itemId: AdhkarActionStatus.failed},
          clearCelebration: true,
        ),
      );
      return;
    }
    final outcome = result.valueOrNull;
    if (outcome is AdhkarDayChanged) {
      // The Adhkar day rolled over (device midnight in unrestricted mode):
      // re-resolve, re-subscribe to the new day and select the period's tab.
      await _refreshClock();
      if (_disposed) return;
      final statuses = Map.of(state.itemStatus)..remove(itemId);
      emit(
        state.copyWith(
          itemStatus: statuses,
          clearCelebration: true,
          clearOutsidePeriod: true,
        ),
      );
      return;
    }
    if (outcome is AdhkarCountingLocked) {
      emit(
        state.copyWith(
          itemStatus: {...state.itemStatus, itemId: AdhkarActionStatus.locked},
          clearCelebration: true,
          clearOutsidePeriod: true,
        ),
      );
      return;
    }
    if (outcome is AdhkarOutsidePeriod) {
      emit(
        state.copyWith(
          itemStatus: {
            ...state.itemStatus,
            itemId: AdhkarActionStatus.outsidePeriod,
          },
          outsidePeriodStartsAtUtc: outcome.startsAtUtc,
          clearCelebration: true,
        ),
      );
      return;
    }
    if (outcome is AdhkarAtTarget) {
      // The item simply stays completed; no feedback flash.
      final statuses = Map.of(state.itemStatus)..remove(itemId);
      emit(
        state.copyWith(
          itemStatus: statuses,
          clearCelebration: true,
          clearOutsidePeriod: true,
        ),
      );
      return;
    }
    final counts = Map.of(state.counts);
    var setCompleted = false;
    if (outcome is AdhkarIncremented) {
      counts[itemId] = outcome.newCount;
      setCompleted = outcome.setCompleted;
    } else if (outcome is AdhkarReset) {
      counts[itemId] = 0;
    }
    final isComplete = _listComplete(list, counts);
    // The celebration stays on the state until the next command starts
    // (one-shot per completion, not auto-cleared) so the UI can render it.
    final celebration = setCompleted
        ? (list == AdhkarList.evening ? AdhkarTab.evening : AdhkarTab.morning)
        : null;
    emit(
      state.copyWith(
        counts: counts,
        itemStatus: {...state.itemStatus, itemId: AdhkarActionStatus.saved},
        celebration: celebration,
        clearOutsidePeriod: true,
      ),
    );
    // The walk is cheap but not free: refresh only when a list's completion
    // state actually changed (Phase 3 review finding 4). A day change
    // refreshes through _refreshClock.
    if (isComplete != wasComplete) {
      unawaited(_refreshStreak());
    }
  }

  Future<void> _refreshClock() async {
    final clockState = await _times.resolve(_ownerId, _clock.nowUtc());
    if (_disposed) return;
    if (clockState.failureOrNull != null) {
      // Keep the last known clock; the notice stays until the port recovers.
      return;
    }
    final resolved = clockState.valueOrNull!;
    final previousDay = state.clock?.day;
    emit(state.copyWith(clock: resolved));
    // The period's tab is selected on first load and when the period (or the
    // day) actually changes; a plain resume inside the same period keeps the
    // user's tab choice (Phase 3 review finding 8).
    final periodChanged = _lastPeriod != resolved.period;
    final dayChanged = previousDay != resolved.day;
    if (_lastPeriod == null || periodChanged || dayChanged) {
      if (resolved.period == AdhkarPeriod.morning) {
        emit(state.copyWith(selectedTab: AdhkarTab.morning));
      } else if (resolved.period == AdhkarPeriod.evening) {
        emit(state.copyWith(selectedTab: AdhkarTab.evening));
      }
    }
    _lastPeriod = resolved.period;
    _boundaryTimer?.cancel();
    final next = resolved.nextBoundaryUtc;
    if (next != null) {
      final delay = next.difference(_clock.nowUtc());
      if (delay > Duration.zero) {
        _boundaryTimer = Timer(delay, _refreshClock);
      }
    } else if (resolved.scheduleState == AdhkarScheduleState.setupRequired) {
      // Unrestricted mode: one timer to the next device midnight so the day
      // rolls over while the screen is open.
      final localNow = _clock.nowUtc().toLocal();
      final nextMidnight = DateTime(
        localNow.year,
        localNow.month,
        localNow.day + 1,
      );
      final delay = nextMidnight.difference(localNow);
      if (delay > Duration.zero) {
        _boundaryTimer = Timer(delay, _refreshClock);
      }
    }
    if (resolved.day != null && resolved.day != _watchedDay) {
      _watchedDay = resolved.day;
      unawaited(_countsSubscription?.cancel());
      _countsSubscription = _repository
          .watchDay(accountId: _ownerId, adhkarDay: resolved.day!)
          .listen((rows) {
            if (_disposed) return;
            emit(
              state.copyWith(
                counts: {for (final row in rows) row.itemId: row.count},
              ),
            );
          });
    }
    if (previousDay != resolved.day) {
      unawaited(_refreshStreak());
    }
  }

  Future<void> _refreshStreak() async {
    final today = state.clock?.day;
    final catalog = state.catalog;
    if (today == null || catalog == null) return;
    final completed = await _repository.fullyCompletedDays(
      accountId: _ownerId,
      lastDay: today,
      maxLookBackDays: 3650,
      catalogVersion: catalog.version,
      morningItems: _listItems(catalog, AdhkarList.morning),
      eveningItems: _listItems(catalog, AdhkarList.evening),
    );
    if (_disposed) return;
    final days = completed.valueOrNull;
    if (days == null) return;
    final streak = adhkarStreak(
      completions: {
        for (final day in days.completed)
          day: const AdhkarDayCompletion(
            morningComplete: true,
            eveningComplete: true,
          ),
      },
      today: today,
    );
    emit(state.copyWith(streak: streak));
  }

  List<AdhkarListItem> _listItems(AdhkarCatalog catalog, AdhkarList list) =>
      catalog
          .itemsOf(list)
          .map(
            (item) => AdhkarListItem(itemId: item.itemId, target: item.target),
          )
          .toList(growable: false);

  /// Whether [list] was complete for the current day with [counts].
  bool _listComplete(AdhkarList? list, Map<String, int> counts) {
    if (list == null) return false;
    final catalog = state.catalog;
    if (catalog == null) return false;
    return catalog
        .itemsOf(list)
        .every((item) => (counts[item.itemId] ?? 0) >= item.target);
  }

  @override
  Future<void> close() async {
    _disposed = true;
    _boundaryTimer?.cancel();
    // The cancel is not awaited: awaiting an async* generator subscription
    // from inside a widget-test zone deadlocks here (the generator's
    // finalization needs an event-loop turn that close does not get).
    // The _disposed guard rejects any late emission instead.
    unawaited(_countsSubscription?.cancel());
    await super.close();
  }
}
