import 'dart:convert';

import '../../xp/domain/xp_award.dart';
import '../domain/prayer_local_date.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_report.dart';
import '../domain/prayer_status.dart';
import 'uuid_prayer_report_identity.dart';

final class PrayerRemoteConflict {
  const PrayerRemoteConflict({
    required this.id,
    required this.active,
    required this.retained,
    required this.detectedAt,
  });

  final String id;
  final PrayerReport active;
  final PrayerReport retained;
  final DateTime detectedAt;
}

final class PrayerDispatchReceipt {
  const PrayerDispatchReceipt({
    required this.operationId,
    required this.active,
    required this.conflict,
    required this.award,
  });

  final String operationId;
  final PrayerReport active;
  final PrayerRemoteConflict? conflict;
  final XpAward? award;
}

abstract final class PrayerRemoteModels {
  static PrayerReport report(Map<String, dynamic> row, String owner) {
    if (row['owner'] != null && row['owner'] != owner) {
      throw const FormatException('Foreign Prayer report');
    }
    final date = PrayerLocalDate.parse(row['local_date'] as String);
    final name = PrayerNameWire.parse(row['prayer_name'] as String);
    final status = PrayerStatusWire.parse(row['status'] as String);
    final completion = row['reported_completion_at'];
    final report = PrayerReport(
      accountId: owner,
      reportId: row['report_id'] as String,
      date: date,
      name: name,
      status: status,
      reportedCompletionAt: completion == null
          ? null
          : DateTime.parse(completion as String).toUtc(),
      recordedZoneId: row['recorded_zone_id'] as String,
      recordedOffsetMinutes: row['recorded_offset_minutes'] as int,
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
    );
    if (report.reportId != _expectedId(date, name)) {
      throw const FormatException('Prayer report identity mismatch');
    }
    return report;
  }

  static String _expectedId(PrayerLocalDate date, PrayerName name) {
    // Keep the deterministic identity check at the parsing boundary.
    return UuidPrayerReportIdentity().reportId(date, name);
  }

  static XpAward award(Map<String, dynamic> row, String owner) {
    if (row['owner'] != null && row['owner'] != owner) {
      throw const FormatException('Foreign Prayer award');
    }
    return XpAward(
      accountId: owner,
      source: row['source'] as String,
      sourceId: row['source_id'] as String,
      amount: row['amount'] as int,
      awardedAt: DateTime.parse(row['awarded_at'] as String).toUtc(),
    );
  }

  static PrayerRemoteConflict conflict(Map<String, dynamic> row, String owner) {
    if (row['owner'] != null && row['owner'] != owner) {
      throw const FormatException('Foreign Prayer conflict');
    }
    final active = report(
      Map<String, dynamic>.from(row['active_report'] as Map),
      owner,
    );
    final retained = report(
      Map<String, dynamic>.from(row['retained_report'] as Map),
      owner,
    );
    if (active.reportId != retained.reportId ||
        active.reportId != row['report_id']) {
      throw const FormatException('Prayer conflict report mismatch');
    }
    return PrayerRemoteConflict(
      id: row['conflict_id'] as String,
      active: active,
      retained: retained,
      detectedAt: DateTime.parse(row['detected_at'] as String).toUtc(),
    );
  }

  static String payload(PrayerReport report) => jsonEncode({
    'localDate': report.date.value,
    'prayerName': report.name.name,
    'status': report.status.wireName,
    'reportedCompletionAt': report.reportedCompletionAt?.toIso8601String(),
    'recordedZoneId': report.recordedZoneId,
    'recordedOffsetMinutes': report.recordedOffsetMinutes,
    'createdAt': report.createdAt.toIso8601String(),
    'updatedAt': report.updatedAt.toIso8601String(),
  });
}
