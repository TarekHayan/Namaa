import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/features/qiyam/application/qiyam_clock_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_night_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/application/qiyam_supplications_port.dart';
import 'package:namma_project/features/qiyam/application/save_qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';

import 'qiyam_state.dart';

/// The Qiyam screen state holder (contracts/adhkar-qiyam-application.md):
/// it loads the night, the record and the editable form, schedules ONE
/// timer for the next night boundary (plus a refresh on resume), saves
/// edits through the command with the note (and times) debounced by
/// 400 ms, and reports per-command feedback. The +30 XP celebration is
/// one-shot per night: only the first `performed = true` save fires it.
/// Nothing is emitted after close, and a night resolution from an earlier
/// generation never overwrites a newer one.
final class QiyamCubit extends Cubit<QiyamState> {
  QiyamCubit({
    required String ownerId,
    required QiyamNightPort nightPort,
    required QiyamRepository repository,
    required QiyamSupplicationsPort supplications,
    required QiyamCommandRunner commands,
    required QiyamClockPort clock,
  }) : _ownerId = ownerId,
       _nightPort = nightPort,
       _repository = repository,
       _supplications = supplications,
       _commands = commands,
       _clock = clock,
       super(const QiyamState());

  static const Duration _noteDebounce = Duration(milliseconds: 400);

  final String _ownerId;
  final QiyamNightPort _nightPort;
  final QiyamRepository _repository;
  final QiyamSupplicationsPort _supplications;
  final QiyamCommandRunner _commands;
  final QiyamClockPort _clock;

  Timer? _boundaryTimer;
  Timer? _noteTimer;
  StreamSubscription<QiyamNightRecord?>? _recordSubscription;
  String? _watchedNight;

  /// The night the current form belongs to; the form resets when the
  /// resolved night changes, not on a plain resume.
  String? _formNight;
  int _generation = 0;
  bool _disposed = false;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    unawaited(_loadSupplications());
    await _refreshNight();
    if (_disposed) return;
    emit(state.copyWith(loading: false));
  }

  Future<void> _loadSupplications() async {
    final result = await _supplications.supplications(_ownerId);
    if (_disposed) return;
    emit(state.copyWith(supplications: result.valueOrNull ?? const []));
  }

  /// Re-resolves the night when the app resumes (contract lifecycle).
  Future<void> resume() => _refreshNight();

  Future<void> answerYes() async {
    if (!_canRecord) return;
    final form = state.form;
    final effective = form != null && form.performed
        ? form
        : const QiyamForm(performed: true, witr: true, rakahs: 4);
    await _runSave(effective);
  }

  Future<void> answerNo() async {
    if (!_canRecord) return;
    await _runSave(const QiyamForm(performed: false, witr: false));
  }

  /// A rak'ah chip selection saves immediately.
  Future<void> selectRakahs(int rakahs) async {
    final form = state.form;
    if (form == null || !form.performed) return;
    await _runSave(_with(form, rakahs: rakahs));
  }

  Future<void> toggleWitr() async {
    final form = state.form;
    if (form == null || !form.performed) return;
    await _runSave(_with(form, witr: !form.witr));
  }

  /// Time edits share the note's debounce so half-typed values are not
  /// committed (and rejected) mid-entry.
  void updateTimes(String? startTime, String? endTime) {
    final form = state.form;
    if (form == null || !form.performed) return;
    _scheduleSave(_with(form, startTime: startTime, endTime: endTime));
  }

  void updateNote(String text) {
    final form = state.form;
    if (form == null || !form.performed) return;
    _scheduleSave(_with(form, note: text));
  }

  /// Saves the pending debounced edit immediately (when the screen is
  /// left).
  Future<void> flushPendingNote() async {
    _noteTimer?.cancel();
    _noteTimer = null;
    await _saveForm(state.form);
  }

  QiyamForm _with(
    QiyamForm form, {
    int? rakahs,
    bool? witr,
    String? startTime,
    String? endTime,
    String? note,
  }) => QiyamForm(
    performed: true,
    rakahs: rakahs ?? form.rakahs,
    witr: witr ?? form.witr,
    startTime: startTime ?? form.startTime,
    endTime: endTime ?? form.endTime,
    note: note ?? form.note,
  );

  bool get _canRecord {
    final night = state.night;
    return night != null && night.editable && night.nightDate != null;
  }

  void _scheduleSave(QiyamForm form) {
    if (!_canRecord) return;
    _formNight = state.night!.nightDate;
    emit(state.copyWith(form: form, clearFailureMessageKey: true));
    _noteTimer?.cancel();
    _noteTimer = Timer(_noteDebounce, () {
      _noteTimer = null;
      unawaited(_saveForm(state.form));
    });
  }

  Future<void> _saveForm(QiyamForm? form) async {
    if (form == null || !_canRecord) return;
    await _runSave(form);
  }

  Future<void> _runSave(QiyamForm form) async {
    final capturedNight = state.night?.nightDate;
    if (capturedNight == null) return;
    // An explicit save supersedes a pending debounced one (the form already
    // carries the latest text).
    _noteTimer?.cancel();
    _noteTimer = null;
    _formNight = capturedNight;
    emit(
      state.copyWith(
        form: form,
        actionStatus: QiyamActionStatus.pending,
        clearCelebration: true,
        clearFailureMessageKey: true,
      ),
    );
    final result = await _commands.execute(
      capturedNight: capturedNight,
      draft: _draftOf(form),
    );
    if (_disposed) return;
    if (result.failureOrNull case final failure?) {
      emit(
        state.copyWith(
          actionStatus: QiyamActionStatus.failed,
          failureMessageKey: failure.messageKey,
          clearCelebration: true,
        ),
      );
      return;
    }
    final outcome = result.valueOrNull!;
    if (outcome is QiyamNightChanged) {
      emit(
        state.copyWith(
          actionStatus: QiyamActionStatus.nightChanged,
          clearCelebration: true,
          clearFailureMessageKey: true,
        ),
      );
      await _refreshNight();
      return;
    }
    if (outcome is QiyamRecordingLocked) {
      emit(
        state.copyWith(
          actionStatus: QiyamActionStatus.locked,
          clearCelebration: true,
          clearFailureMessageKey: true,
        ),
      );
      return;
    }
    final saved = outcome as QiyamNightSaved;
    emit(
      state.copyWith(
        actionStatus: QiyamActionStatus.saved,
        celebration: saved.firstPerformed,
        clearCelebration: !saved.firstPerformed,
        clearFailureMessageKey: true,
      ),
    );
  }

  QiyamNightDraft _draftOf(QiyamForm form) {
    if (!form.performed) return QiyamNightDraft.notPerformed;
    final note = form.note;
    return QiyamNightDraft(
      performed: true,
      rakahs: form.rakahs,
      witr: form.witr,
      startTime: _clean(form.startTime),
      endTime: _clean(form.endTime),
      note: note == null || note.isEmpty ? null : note,
    );
  }

  static String? _clean(String? value) =>
      value == null || value.isEmpty ? null : value;

  Future<void> _refreshNight() async {
    final generation = ++_generation;
    final resolved = await _nightPort.resolve(
      ownerId: _ownerId,
      nowUtc: _clock.nowUtc(),
    );
    if (_disposed || generation != _generation) return;
    if (resolved.failureOrNull != null) {
      // Keep the last known night; the notice stays until the port recovers.
      return;
    }
    final night = resolved.valueOrNull!;
    final previousNightDate = state.night?.nightDate;
    emit(state.copyWith(night: night));
    _boundaryTimer?.cancel();
    final next = night.nextBoundaryUtc;
    if (next != null) {
      final delay = next.difference(_clock.nowUtc());
      if (delay > Duration.zero) {
        _boundaryTimer = Timer(delay, () {
          unawaited(_refreshNight());
        });
      }
    }
    final nightDate = night.nightDate;
    if (nightDate == null) {
      // Unavailable: no record may be attributed to any night.
      _watchedNight = null;
      _formNight = null;
      unawaited(_recordSubscription?.cancel());
      _recordSubscription = null;
      emit(state.copyWith(clearRecord: true, clearForm: true));
      return;
    }
    if (nightDate != _watchedNight) {
      _watchedNight = nightDate;
      unawaited(_recordSubscription?.cancel());
      _recordSubscription = _repository
          .watchNight(accountId: _ownerId, nightDate: nightDate)
          .listen((row) {
            if (_disposed) return;
            if (row != null) _applyRecord(row);
          });
    }
    if (previousNightDate != nightDate) {
      // The night rolled over: the form and the row belong to the old night.
      _formNight = null;
      emit(state.copyWith(clearForm: true, clearRecord: true));
    }
    final read = await _repository.readFresh(
      accountId: _ownerId,
      nightDate: nightDate,
    );
    if (_disposed || generation != _generation) return;
    if (read.valueOrNull case final record?) {
      _applyRecord(record);
    }
  }

  void _applyRecord(QiyamNightRecord record) {
    emit(state.copyWith(record: record));
    final nightDate = record.nightDate;
    final form = state.form;
    if (form == null || _formNight != nightDate) {
      // Only build the form from storage; unsaved edits are never clobbered
      // by a later row of the same night.
      _formNight = nightDate;
      emit(
        state.copyWith(
          form: QiyamForm(
            performed: record.performed,
            rakahs: record.rakahs,
            witr: record.witr,
            startTime: record.startTime,
            endTime: record.endTime,
            note: record.note,
          ),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    // A debounced edit still waiting when the screen is left is saved, not
    // dropped (the note is flushed on leaving).
    if (_noteTimer != null) {
      _noteTimer!.cancel();
      _noteTimer = null;
      await _saveForm(state.form);
    }
    _disposed = true;
    _boundaryTimer?.cancel();
    _noteTimer?.cancel();
    // The cancel is not awaited: awaiting an async* generator subscription
    // from inside a widget-test zone deadlocks here (the generator's
    // finalization needs an event-loop turn that close does not get).
    // The _disposed guard rejects any late emission instead.
    unawaited(_recordSubscription?.cancel());
    await super.close();
  }
}
