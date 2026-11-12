import 'dart:convert';

import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../domain/qiyam_night_record.dart';
import 'uuid_qiyam_identity.dart';

/// One retained conflict version pair as the server reports it.
final class QiyamRemoteConflict {
  const QiyamRemoteConflict({
    required this.id,
    required this.active,
    required this.retained,
    required this.detectedAt,
  });

  final String id;
  final QiyamNightRecord active;
  final QiyamNightRecord retained;
  final DateTime detectedAt;
}

/// One dispatch receipt of `apply_qiyam_night_change_v1`.
final class QiyamDispatchReceipt {
  const QiyamDispatchReceipt({
    required this.operationId,
    required this.active,
    required this.conflict,
    required this.award,
  });

  final String operationId;
  final QiyamNightRecord active;
  final QiyamRemoteConflict? conflict;
  final XpAward? award;
}

abstract final class QiyamRemoteModels {
  /// The server's active row (0016's `active_record` jsonb, owner stripped)
  /// into the domain record, validating the deterministic identity.
  static QiyamNightRecord record(Map<String, dynamic> row, String owner) {
    if (row['owner'] != null && row['owner'] != owner) {
      throw const FormatException('Foreign Qiyam record');
    }
    final record = QiyamNightRecord(
      accountId: owner,
      nightDate: row['night_date'] as String,
      recordId: row['record_id'] as String,
      performed: row['performed'] as bool,
      rakahs: row['rakahs'] as int?,
      witr: row['witr'] as bool,
      startTime: row['start_time'] as String?,
      endTime: row['end_time'] as String?,
      note: row['note'] as String?,
      recordedZoneId: row['recorded_zone_id'] as String,
      recordedOffsetMinutes: row['recorded_offset_minutes'] as int,
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
      lastAcknowledgedUpdatedAt: null,
    );
    if (record.recordId !=
        const UuidQiyamIdentity().nightRecordId(record.nightDate)) {
      throw const FormatException('Qiyam record identity mismatch');
    }
    return record;
  }

  static XpAward award(Map<String, dynamic> row, String owner) {
    if (row['owner'] != null && row['owner'] != owner) {
      throw const FormatException('Foreign Qiyam award');
    }
    final source = row['source'] as String;
    if (source != kQiyamDoneAwardSource) {
      throw const FormatException('Unexpected Qiyam award source');
    }
    return XpAward(
      accountId: owner,
      source: source,
      sourceId: row['source_id'] as String,
      amount: row['amount'] as int,
      awardedAt: DateTime.parse(row['awarded_at'] as String).toUtc(),
    );
  }

  /// The semantic wire payload of one night record — the same key set the
  /// outbox carries, without the acknowledged base.
  static String payload(QiyamNightRecord record) => jsonEncode({
    'night_date': record.nightDate,
    'performed': record.performed,
    'rakahs': record.rakahs,
    'witr': record.witr,
    'start_time': record.startTime,
    'end_time': record.endTime,
    'note': record.note,
    'recorded_zone_id': record.recordedZoneId,
    'recorded_offset_minutes': record.recordedOffsetMinutes,
    'updated_at': record.updatedAt.toIso8601String(),
  });
}
