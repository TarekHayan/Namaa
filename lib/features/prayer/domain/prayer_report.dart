import 'prayer_local_date.dart';
import 'prayer_name.dart';
import 'prayer_status.dart';

final class PrayerReport {
  PrayerReport({
    required this.accountId,
    required this.reportId,
    required this.date,
    required this.name,
    required this.status,
    required this.recordedZoneId,
    required this.recordedOffsetMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.reportedCompletionAt,
    this.lastAcknowledgedUpdatedAt,
    this.canonicalRewardConfirmedAt,
  }) {
    if (accountId.trim().isEmpty ||
        reportId.trim().isEmpty ||
        recordedZoneId.trim().isEmpty ||
        recordedOffsetMinutes.abs() > 1080 ||
        !createdAt.isUtc ||
        !updatedAt.isUtc ||
        (reportedCompletionAt != null) != status.isCompleted ||
        (reportedCompletionAt != null && !reportedCompletionAt!.isUtc) ||
        (lastAcknowledgedUpdatedAt != null &&
            !lastAcknowledgedUpdatedAt!.isUtc) ||
        (canonicalRewardConfirmedAt != null &&
            !canonicalRewardConfirmedAt!.isUtc)) {
      throw ArgumentError('Invalid prayer report');
    }
  }

  final String accountId;
  final String reportId;
  final PrayerLocalDate date;
  final PrayerName name;
  final PrayerStatus status;
  final DateTime? reportedCompletionAt;
  final String recordedZoneId;
  final int recordedOffsetMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAcknowledgedUpdatedAt;
  final DateTime? canonicalRewardConfirmedAt;

  PrayerReport copyWith({
    PrayerStatus? status,
    DateTime? updatedAt,
    DateTime? reportedCompletionAt,
    bool clearReportedCompletionAt = false,
  }) => PrayerReport(
    accountId: accountId,
    reportId: reportId,
    date: date,
    name: name,
    status: status ?? this.status,
    reportedCompletionAt: clearReportedCompletionAt
        ? null
        : reportedCompletionAt ?? this.reportedCompletionAt,
    recordedZoneId: recordedZoneId,
    recordedOffsetMinutes: recordedOffsetMinutes,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastAcknowledgedUpdatedAt: lastAcknowledgedUpdatedAt,
    canonicalRewardConfirmedAt: canonicalRewardConfirmedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is PrayerReport &&
      other.accountId == accountId &&
      other.reportId == reportId &&
      other.date == date &&
      other.name == name &&
      other.status == status &&
      other.reportedCompletionAt == reportedCompletionAt &&
      other.recordedZoneId == recordedZoneId &&
      other.recordedOffsetMinutes == recordedOffsetMinutes &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.lastAcknowledgedUpdatedAt == lastAcknowledgedUpdatedAt &&
      other.canonicalRewardConfirmedAt == canonicalRewardConfirmedAt;

  @override
  int get hashCode => Object.hash(
    accountId,
    reportId,
    date,
    name,
    status,
    reportedCompletionAt,
    recordedZoneId,
    recordedOffsetMinutes,
    createdAt,
    updatedAt,
    lastAcknowledgedUpdatedAt,
    canonicalRewardConfirmedAt,
  );
}
