/// The Qiyam night draft (a submission) and the stored night record, with
/// the field rules from the fixed implementation facts and data-model.md:
///
/// - `rakahs` must be one of 2/4/8/11, and only when performed;
/// - `witr` defaults to true when performed and is false when not;
/// - `start_time`/`end_time` are optional local wall-clock `HH:mm` values; an
///   end time earlier than the start time means the prayer crossed midnight
///   and is accepted (FR-009, acceptance scenario 6);
/// - `note` is at most 500 characters;
/// - when not performed, every detail is cleared (acceptance scenario 5).
///
/// The draft reports its violations instead of throwing, so the save command
/// can reject a submission with typed failures; the stored record throws
/// [ArgumentError] on any violation, because a persisted row must always be
/// valid (migration 0016 mirrors the same checks).
library;

/// The detail-field rules a submission can violate.
enum QiyamDraftViolation { rakahs, time, note, notPerformedDetails }

final class QiyamNightDraft {
  const QiyamNightDraft({
    required this.performed,
    this.rakahs,
    this.witr = false,
    this.startTime,
    this.endTime,
    this.note,
  });

  /// The approved rak'ah choices (FR-009).
  static const Set<int> allowedRakahs = {2, 4, 8, 11};

  /// The largest accepted note length.
  static const int maxNoteLength = 500;

  final bool performed;
  final int? rakahs;
  final bool witr;
  final String? startTime;
  final String? endTime;
  final String? note;

  /// The field rules this draft violates, empty when it is valid.
  List<QiyamDraftViolation> violations() {
    final violations = <QiyamDraftViolation>[];
    if (performed) {
      if (rakahs == null || !allowedRakahs.contains(rakahs)) {
        violations.add(QiyamDraftViolation.rakahs);
      }
      if (!_validTime(startTime) || !_validTime(endTime)) {
        violations.add(QiyamDraftViolation.time);
      }
      if (note != null && note!.length > maxNoteLength) {
        violations.add(QiyamDraftViolation.note);
      }
    } else if (rakahs != null ||
        witr ||
        startTime != null ||
        endTime != null ||
        (note != null && note!.isNotEmpty)) {
      violations.add(QiyamDraftViolation.notPerformedDetails);
    }
    return violations;
  }

  /// The "No" draft: performed false with every detail cleared.
  static const QiyamNightDraft notPerformed = QiyamNightDraft(performed: false);

  static bool _validTime(String? value) =>
      value == null || RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
}

/// One stored Qiyam night row (data-model.md, `qiyam_nights`). "No row"
/// means not recorded; `performed == false` is the explicit "No".
final class QiyamNightRecord {
  QiyamNightRecord({
    required this.accountId,
    required this.nightDate,
    required this.recordId,
    required this.performed,
    required this.rakahs,
    required this.witr,
    required this.startTime,
    required this.endTime,
    required this.note,
    required this.recordedZoneId,
    required this.recordedOffsetMinutes,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAcknowledgedUpdatedAt,
  }) {
    if (accountId.trim().isEmpty ||
        recordId.trim().isEmpty ||
        recordedZoneId.trim().isEmpty ||
        recordedZoneId.contains('|') ||
        recordedOffsetMinutes.abs() > 1080 ||
        !createdAt.isUtc ||
        !updatedAt.isUtc ||
        (!updatedAt.isAfter(createdAt) &&
            !updatedAt.isAtSameMomentAs(createdAt))) {
      throw ArgumentError('Invalid Qiyam night record');
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(nightDate)) {
      throw ArgumentError.value(nightDate, 'nightDate');
    }
    final violations = QiyamNightDraft(
      performed: performed,
      rakahs: rakahs,
      witr: witr,
      startTime: startTime,
      endTime: endTime,
      note: note,
    ).violations();
    if (violations.isNotEmpty) {
      throw ArgumentError.value(violations, 'details');
    }
  }

  final String accountId;
  final String nightDate;
  final String recordId;
  final bool performed;
  final int? rakahs;
  final bool witr;
  final String? startTime;
  final String? endTime;
  final String? note;
  final String recordedZoneId;
  final int recordedOffsetMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAcknowledgedUpdatedAt;
}
