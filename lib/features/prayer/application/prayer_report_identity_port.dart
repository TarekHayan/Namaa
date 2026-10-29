import '../domain/prayer_local_date.dart';
import '../domain/prayer_name.dart';

abstract interface class PrayerReportIdentityPort {
  String reportId(PrayerLocalDate date, PrayerName name);
}
