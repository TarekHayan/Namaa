import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/prayer_context_service.dart';
import '../application/prayer_report_commands.dart';
import '../domain/prayer_day_snapshot.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_status.dart';
import 'prayer_state.dart';

/// Read-only route controller. A route visit owns the stream and its timer.
final class PrayerCubit extends Cubit<PrayerState> {
  PrayerCubit({
    required PrayerContextService context,
    required String ownerId,
    PrayerReportCommands Function(
      PrayerScopeValidator scopeValidator,
      PrayerScopeValidator ownerValidator,
    )?
    reportCommands,
  }) : _context = context,
       _ownerId = ownerId,
       super(const PrayerState()) {
    _reportCommands = reportCommands?.call(
      _isCurrentScope,
      _isCurrentOwnerContext,
    );
    _listen();
  }

  final PrayerContextService _context;
  final String _ownerId;
  late final PrayerReportCommands? _reportCommands;
  StreamSubscription<PrayerDaySnapshot>? _subscription;
  int _scopeGeneration = 0;
  String? _scopeKey;

  void _listen() {
    _subscription = _context
        .watch(_ownerId)
        .listen(
          (snapshot) {
            if (!isClosed && snapshot.ownerId == _ownerId) {
              final key = _snapshotScopeKey(snapshot);
              final scopeChanged = key != _scopeKey;
              if (scopeChanged) {
                _scopeKey = key;
                _scopeGeneration++;
              }
              emit(
                state.copyWith(
                  snapshot: snapshot,
                  failed: false,
                  actions: scopeChanged ? const {} : state.actions,
                ),
              );
            }
          },
          onError: (_, _) {
            if (!isClosed) emit(const PrayerState(failed: true));
          },
        );
  }

  Future<void> setStatus(PrayerName name, PrayerStatus status) async {
    final command = _reportCommands;
    final snapshot = state.snapshot;
    final preferences = snapshot?.preferences;
    final date = snapshot?.localDate;
    if (command == null || preferences == null || date == null) return;
    if (state.actions[name] == PrayerActionPhase.saving) return;
    final captured = PrayerReportCommandContext(
      localDate: date,
      timeZoneId: preferences.city.timeZoneId,
      preferenceRevision: preferences.revision,
      scopeGeneration: _scopeGeneration,
    );
    _setAction(name, PrayerActionPhase.saving);
    final result = await command.setStatus(
      name: name,
      status: status,
      capturedContext: captured,
    );
    if (isClosed || !_isCurrentScope(captured)) return;
    _setAction(
      name,
      result.failureOrNull == null
          ? PrayerActionPhase.saved
          : PrayerActionPhase.failed,
    );
  }

  bool _isCurrentScope(PrayerReportCommandContext value) {
    final snapshot = state.snapshot;
    final preferences = snapshot?.preferences;
    return snapshot?.ownerId == _ownerId &&
        snapshot?.localDate == value.localDate &&
        preferences?.revision == value.preferenceRevision &&
        preferences?.city.timeZoneId == value.timeZoneId &&
        _scopeGeneration == value.scopeGeneration;
  }

  bool _isCurrentOwnerContext(PrayerReportCommandContext value) {
    final snapshot = state.snapshot;
    final preferences = snapshot?.preferences;
    return snapshot?.ownerId == _ownerId &&
        preferences?.revision == value.preferenceRevision &&
        preferences?.city.timeZoneId == value.timeZoneId;
  }

  void _setAction(PrayerName name, PrayerActionPhase phase) {
    emit(
      state.copyWith(
        actions: Map.unmodifiable({...state.actions, name: phase}),
      ),
    );
  }

  String _snapshotScopeKey(PrayerDaySnapshot snapshot) =>
      '${snapshot.ownerId}|${snapshot.localDate?.value}|'
      '${snapshot.preferences?.revision}|'
      '${snapshot.preferences?.city.timeZoneId}';

  Future<void> retry() async {
    if (isClosed) return;
    await _subscription?.cancel();
    if (isClosed) return;
    emit(const PrayerState());
    _listen();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
