import 'prayer_local_date.dart';
import 'prayer_name.dart';
import 'prayer_status.dart';

final class PrayerConflictEvidence {
  const PrayerConflictEvidence({
    required this.id,
    required this.date,
    required this.name,
    required this.activeStatus,
    required this.retainedStatus,
    required this.activeAt,
    required this.retainedAt,
  });

  final String id;
  final PrayerLocalDate date;
  final PrayerName name;
  final PrayerStatus activeStatus;
  final PrayerStatus retainedStatus;
  final DateTime activeAt;
  final DateTime retainedAt;
}
