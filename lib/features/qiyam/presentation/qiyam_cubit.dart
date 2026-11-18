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
/// edits through the command — the note, and a time that is not yet a
/// complete `HH:mm`, are debounced by one second so half-typed values are
/// not committed — and reports per-command feedback. The +30 points moment
/// is one-shot per night: only the first `performed = true` save fires it,
/// and it stays on the state until the night rolls over. Nothing is emitted
/// after close, and a night resolution from an earlier generation never
/// overwrites a newer one.
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

  static const Duration _noteDebounce = Duration(seconds: 1);

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

  /// Superseding tokens: a streak or history result from an earlier
  /// refresh never lands after a newer one started.
  int _streakEpoch = 0;
  int _historyEpoch = 0;

  /// The loaded recorded rows behind [QiyamState.history], newest first —
  /// the display entries are rebuilt from them on every page so "Not
  /// recorded" can fill the nights between two loaded records.
  final List<QiyamNightRecord> _historyRecords = <QiyamNightRecord>[];

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

  /// A pair of complete times (or an emptied field) saves at once, as the
  /// platform picker produces them; a half-typed value shares the note's
  /// debounce so it is not committed (and rejected) mid-entry.
  void updateTimes(String? startTime, String? endTime) {
    final form = state.form;
    if (form == null || !form.performed) return;
    final next = _with(form, startTime: startTime, endTime: endTime);
    if (QiyamNightDraft.isValidTime(_clean(next.startTime)) &&
        QiyamNightDraft.isValidTime(_clean(next.endTime))) {
      unawaited(_runSave(next));
    } else {
      _scheduleSave(next);
    }
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

  /// "Load more": fetches only the next history page of RECORDED rows,
  /// with the oldest loaded row as the exclusive bound (the current night
  /// starts the first page when nothing is loaded yet — also the retry
  /// after a failed first page).
  Future<void> loadMoreHistory() async {
    if (state.historyLoading || state.historyComplete) return;
    final cursor = _historyRecords.isEmpty
        ? state.night?.nightDate
        : _historyRecords.last.nightDate;
    if (cursor == null) return;
    final epoch = ++_historyEpoch;
    emit(state.copyWith(historyLoading: true, historyFailed: false));
    final result = await _repository.history(
      accountId: _ownerId,
      before: cursor,
    );
    if (_disposed || epoch != _historyEpoch) return;
    if (result.valueOrNull case final page?) {
      _historyRecords.addAll(page.records);
      emit(
        state.copyWith(
          history: _historyEntries(_historyRecords),
          historyLoading: false,
          historyFailed: false,
          historyComplete: !page.hasMore,
        ),
      );
    } else {
      emit(state.copyWith(historyLoading: false, historyFailed: true));
    }
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

  /// Saves run one after another: the command reads the stored version and
  /// commits against it, so two overlapping saves (a quick Yes, No, Yes)
  /// would make the second one stale.
  Future<void> _saveQueue = Future<void>.value();

  Future<void> _runSave(QiyamForm form) {
    final run = _saveQueue.then((_) => _commitSave(form));
    _saveQueue = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<void> _commitSave(QiyamForm form) async {
    if (_disposed) return;
    final capturedNight = state.night?.nightDate;
    if (capturedNight == null) return;
    // Whether this save moves the STORED record into or out of "performed"
    // (Phase 5 review finding 4): only then does the derived streak need a
    // refresh (never on note, time or rak'ah edits). Comparing against the
    // stored record — not the form — keeps the refresh correct when a save
    // succeeds after a failed one left the form already in the new state.
    final wasPerformed = state.record?.performed ?? false;
    // An explicit save supersedes a pending debounced one (the form already
    // carries the latest text).
    _noteTimer?.cancel();
    _noteTimer = null;
    _formNight = capturedNight;
    emit(
      state.copyWith(
        form: form,
        actionStatus: QiyamActionStatus.pending,
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
        ),
      );
      return;
    }
    final outcome = result.valueOrNull!;
    if (outcome is QiyamNightChanged) {
      emit(
        state.copyWith(
          actionStatus: QiyamActionStatus.nightChanged,
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
        clearFailureMessageKey: true,
      ),
    );
    if (wasPerformed != form.performed) {
      await _refreshStreak();
    }
  }

  /// The display entries over the loaded records: "Not recorded" fills only
  /// the nights strictly BETWEEN two loaded records (Phase 5 review finding
  /// 1) — never before the newest or after the oldest loaded row.
  static List<QiyamHistoryEntry> _historyEntries(
    List<QiyamNightRecord> records,
  ) {
    final entries = <QiyamHistoryEntry>[];
    for (var i = 0; i < records.length; i++) {
      if (i > 0) {
        final newer = _parseNight(records[i - 1].nightDate);
        final older = _parseNight(records[i].nightDate);
        for (
          var night = newer.subtract(const Duration(days: 1));
          night.isAfter(older);
          night = night.subtract(const Duration(days: 1))
        ) {
          entries.add(QiyamHistoryEntry(nightDate: _nightKey(night)));
        }
      }
      entries.add(
        QiyamHistoryEntry(nightDate: records[i].nightDate, record: records[i]),
      );
    }
    return entries;
  }

  static DateTime _parseNight(String nightDate) => DateTime.utc(
    int.parse(nightDate.substring(0, 4)),
    int.parse(nightDate.substring(5, 7)),
    int.parse(nightDate.substring(8, 10)),
  );

  static String _nightKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

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
      emit(
        state.copyWith(
          clearRecord: true,
          clearForm: true,
          clearCelebration: true,
        ),
      );
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
      emit(
        state.copyWith(
          clearForm: true,
          clearRecord: true,
          clearCelebration: true,
          clearFailureMessageKey: true,
          // A night that rolled over while the screen was open says so.
          actionStatus: previousNightDate == null
              ? null
              : QiyamActionStatus.nightChanged,
        ),
      );
      // The streak and the first history page are derived for the current
      // night; refresh them when it changes — never on plain edits.
      await _refreshStreak();
      await _reloadHistory();
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

  /// Reads the derived streak for the current night (research.md R9). A
  /// failed read shows the failure and keeps the last good value — it is
  /// never presented as a streak of 0.
  Future<void> _refreshStreak() async {
    final nightDate = state.night?.nightDate;
    if (nightDate == null) return;
    final epoch = ++_streakEpoch;
    final result = await _repository.streak(
      accountId: _ownerId,
      currentNight: nightDate,
    );
    if (_disposed || epoch != _streakEpoch) return;
    if (result.valueOrNull case final streak?) {
      emit(state.copyWith(streak: streak, streakFailed: false));
    } else {
      emit(state.copyWith(streakFailed: true));
    }
  }

  /// Loads the first history page: the 30 recorded rows before the current
  /// night.
  Future<void> _reloadHistory() async {
    final nightDate = state.night?.nightDate;
    if (nightDate == null) return;
    final epoch = ++_historyEpoch;
    emit(state.copyWith(historyLoading: true, historyFailed: false));
    final result = await _repository.history(
      accountId: _ownerId,
      before: nightDate,
    );
    if (_disposed || epoch != _historyEpoch) return;
    if (result.valueOrNull case final page?) {
      _historyRecords
        ..clear()
        ..addAll(page.records);
      emit(
        state.copyWith(
          history: _historyEntries(_historyRecords),
          historyLoading: false,
          historyFailed: false,
          historyComplete: !page.hasMore,
        ),
      );
    } else {
      emit(state.copyWith(historyLoading: false, historyFailed: true));
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
