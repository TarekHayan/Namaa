import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/qiyam_night_record.dart';

/// The Qiyam night store boundary (contracts/adhkar-qiyam-application.md).
///
/// A missing row means the night is not recorded; `performed == false` is the
/// explicit "No". The record type and its field rules live in the domain
/// (`features/qiyam/domain/qiyam_night_record.dart`).
abstract interface class QiyamRepository {
  /// The fresh row for (owner, night), or null when the night is not
  /// recorded. A storage failure is a failure, never "no record".
  Future<AppResult<QiyamNightRecord?>> readFresh({
    required String accountId,
    required String nightDate,
  });

  /// The row for (owner, night), emitting null when it is not recorded.
  Stream<QiyamNightRecord?> watchNight({
    required String accountId,
    required String nightDate,
  });

  /// Writes the record row and appends the outbox entry; called inside a
  /// transaction. [hadPrior] selects the outbox kind (create vs update).
  Future<AppResult<void>> writeNight(
    QiyamNightRecord record, {
    required String operationId,
    required bool queueForSync,
    required bool hadPrior,
  });

  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  );
}

/// One transactional save: the record upsert, the provisional `qiyam_done`
/// award on the first `performed = true`, and the outbox entry happen
/// together or not at all (data-model.md, save command).
final class QiyamSaveRequest {
  QiyamSaveRequest({
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
    required this.updatedAt,
    required this.operationId,
    required this.expectedCurrentVersion,
    required this.acknowledgedBase,
    required this.queueForSync,
  }) {
    if (accountId.trim().isEmpty ||
        nightDate.trim().isEmpty ||
        recordId.trim().isEmpty ||
        recordedZoneId.trim().isEmpty ||
        recordedZoneId.contains('|') ||
        recordedOffsetMinutes.abs() > 1080 ||
        !updatedAt.isUtc ||
        operationId.trim().isEmpty) {
      throw ArgumentError('Invalid Qiyam save request');
    }
  }

  final String accountId;
  final String nightDate;

  /// The deterministic night record ID; it doubles as the `qiyam_done`
  /// award `source_id`.
  final String recordId;
  final bool performed;
  final int? rakahs;
  final bool witr;
  final String? startTime;
  final String? endTime;
  final String? note;
  final String recordedZoneId;
  final int recordedOffsetMinutes;

  /// The stamped version: the sampled `now` (possibly bumped by 1
  /// microsecond over a prior equal-or-later version).
  final DateTime updatedAt;
  final String operationId;
  final DateTime? expectedCurrentVersion;
  final DateTime? acknowledgedBase;
  final bool queueForSync;
}

/// The outcome of one transactional save.
final class QiyamSaveOutcome {
  const QiyamSaveOutcome({
    required this.wroteRecord,
    required this.awardInserted,
  });

  /// False only when the commit wrote nothing new.
  final bool wroteRecord;

  /// True when this commit inserted the provisional `qiyam_done` award —
  /// the first `performed = true` for the night whose award was still
  /// missing. Awards are never revoked and never inserted twice.
  final bool awardInserted;
}

/// The transactional save boundary the commands use (implemented by the
/// Drift unit of work in core/data).
abstract interface class QiyamNightCommitPort {
  Future<AppResult<QiyamSaveOutcome>> commit(QiyamSaveRequest request);
}
