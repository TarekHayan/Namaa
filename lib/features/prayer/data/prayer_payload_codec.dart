import '../domain/prayer_report.dart';
import '../domain/prayer_status.dart';

final class PrayerPayloadCodec {
  const PrayerPayloadCodec();

  Map<String, Object?> encode(PrayerReport report) => {
    'localDate': report.date.value,
    'prayerName': report.name.name,
    'status': report.status.wireName,
    'reportedCompletionAt': report.reportedCompletionAt?.toIso8601String(),
    'recordedZoneId': report.recordedZoneId,
    'recordedOffsetMinutes': report.recordedOffsetMinutes,
    'updatedAt': report.updatedAt.toIso8601String(),
  };
}
