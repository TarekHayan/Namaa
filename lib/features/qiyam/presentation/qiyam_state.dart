import 'package:namma_project/features/qiyam/application/qiyam_repository.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_supplication.dart';

/// Per-command feedback for the Qiyam tracker (contracts/
/// adhkar-qiyam-application.md). `nightChanged` means the captured night is
/// no longer the current one; the screen refreshes instead of saving.
enum QiyamActionStatus { pending, saved, failed, locked, nightChanged }

/// The editable details of the tracker card. The form exists only after an
/// answer: Yes presents the defaults (4 rak'ahs, Witr on) or the stored
/// record's details, No presents the cleared details.
final class QiyamForm {
  const QiyamForm({
    required this.performed,
    required this.witr,
    this.rakahs,
    this.startTime,
    this.endTime,
    this.note,
  });

  final bool performed;

  /// One of the approved rak'ah choices (2, 4, 8, 11) while performed.
  final int? rakahs;
  final bool witr;
  final String? startTime;
  final String? endTime;
  final String? note;

  QiyamForm copyWith({
    bool? performed,
    int? rakahs,
    bool? witr,
    String? startTime,
    String? endTime,
    String? note,
  }) => QiyamForm(
    performed: performed ?? this.performed,
    rakahs: rakahs ?? this.rakahs,
    witr: witr ?? this.witr,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    note: note ?? this.note,
  );
}

/// The Qiyam screen state: the resolved night, the current night's record,
/// the editable form, the derived streak, the paged history, and the
/// per-command feedback.
final class QiyamState {
  const QiyamState({
    this.loading = false,
    this.night,
    this.record,
    this.form,
    this.supplications = const [],
    this.actionStatus,
    this.celebration = false,
    this.failureMessageKey,
    this.streak,
    this.streakFailed = false,
    this.history = const [],
    this.historyLoading = false,
    this.historyFailed = false,
    this.historyComplete = false,
  });

  final bool loading;

  /// The resolved Qiyam night; null only while the first load is running.
  final QiyamNightState? night;

  /// The current night's record; null when the night is not recorded.
  final QiyamNightRecord? record;

  /// The editable form; null until an answer is given (Yes or No).
  final QiyamForm? form;

  /// The approved supplications of the reviewed catalog, in catalog order.
  final List<QiyamSupplication> supplications;

  /// The latest command's feedback; cleared on the next command.
  final QiyamActionStatus? actionStatus;

  /// One-shot: true only on the transition into the first `performed = true`
  /// save of the night (the +30 XP celebration).
  final bool celebration;

  /// The message key of the latest validation or persistence failure.
  final String? failureMessageKey;

  /// The derived Qiyam streak; null until the first successful read. A
  /// failed read is reported by [streakFailed] — never as a streak of 0.
  final int? streak;

  /// True when the latest streak read failed; the last good value stays.
  final bool streakFailed;

  /// The loaded history pages, newest first (30 nights per page). A failed
  /// page fetch is reported by [historyFailed] — never as an empty history.
  final List<QiyamHistoryEntry> history;

  /// True while a history page (the first one or a "load more") is loading.
  final bool historyLoading;

  /// True when the latest history page fetch failed.
  final bool historyFailed;

  /// True when the walk back has reached an entirely unrecorded window.
  final bool historyComplete;

  /// True while the schedule is unavailable: the screen stays visible but
  /// recording is locked (owner decision, 2026-11-10).
  bool get recordingLocked =>
      night == null || night!.scheduleState == QiyamScheduleState.unavailable;

  bool get recordingEditable => night?.editable ?? false;

  QiyamState copyWith({
    bool? loading,
    QiyamNightState? night,
    QiyamNightRecord? record,
    QiyamForm? form,
    List<QiyamSupplication>? supplications,
    QiyamActionStatus? actionStatus,
    bool celebration = false,
    String? failureMessageKey,
    int? streak,
    bool? streakFailed,
    List<QiyamHistoryEntry>? history,
    bool? historyLoading,
    bool? historyFailed,
    bool? historyComplete,
    bool clearRecord = false,
    bool clearForm = false,
    bool clearActionStatus = false,
    bool clearFailureMessageKey = false,
    bool clearCelebration = false,
  }) => QiyamState(
    loading: loading ?? this.loading,
    night: night ?? this.night,
    record: clearRecord ? null : (record ?? this.record),
    form: clearForm ? null : (form ?? this.form),
    supplications: supplications ?? this.supplications,
    actionStatus: clearActionStatus
        ? null
        : (actionStatus ?? this.actionStatus),
    celebration: clearCelebration ? false : (celebration || this.celebration),
    failureMessageKey: clearFailureMessageKey
        ? null
        : (failureMessageKey ?? this.failureMessageKey),
    streak: streak ?? this.streak,
    streakFailed: streakFailed ?? this.streakFailed,
    history: history ?? this.history,
    historyLoading: historyLoading ?? this.historyLoading,
    historyFailed: historyFailed ?? this.historyFailed,
    historyComplete: historyComplete ?? this.historyComplete,
  );
}
