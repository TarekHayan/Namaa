import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_commands.dart';
import 'package:namma_project/features/adhkar/application/adhkar_repository.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
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
    final counts = Map.of(state.counts);
    var setCompleted = false;
    if (outcome is AdhkarIncremented) {
      counts[itemId] = outcome.newCount;
      setCompleted = outcome.setCompleted;
    }
    // The celebration stays on the state until the next command starts
    // (one-shot per completion, not auto-cleared) so the UI can render it.
    final celebration = setCompleted
        ? (state.catalog?.item(itemId)?.list == 'evening'
              ? AdhkarTab.evening
              : AdhkarTab.morning)
        : null;
    emit(
      state.copyWith(
        counts: counts,
        itemStatus: {...state.itemStatus, itemId: AdhkarActionStatus.saved},
        celebration: celebration,
      ),
    );
    unawaited(_refreshStreak());
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
    if (resolved.period == AdhkarPeriod.morning) {
      emit(state.copyWith(selectedTab: AdhkarTab.morning));
    } else if (resolved.period == AdhkarPeriod.evening) {
      emit(state.copyWith(selectedTab: AdhkarTab.evening));
    }
    _boundaryTimer?.cancel();
    final next = resolved.nextBoundaryUtc;
    if (next != null) {
      final delay = next.difference(_clock.nowUtc());
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
    if (today == null) return;
    final completed = await _repository.fullyCompletedDays(
      accountId: _ownerId,
      lastDay: today,
      maxLookBackDays: 3650,
    );
    if (_disposed) return;
    final days = completed.valueOrNull;
    if (days == null) return;
    final streak = adhkarStreak(
      completions: {
        for (final day in days)
          day: const AdhkarDayCompletion(
            morningComplete: true,
            eveningComplete: true,
          ),
      },
      today: today,
    );
    emit(state.copyWith(streak: streak));
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
