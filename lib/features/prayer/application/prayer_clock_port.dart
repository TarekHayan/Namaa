import '../domain/prayer_local_date.dart';

abstract interface class PrayerClockPort {
  DateTime nowUtc();
  PrayerLocalDate cityDate(DateTime nowUtc, String timeZoneId);
  int cityOffsetMinutes(DateTime nowUtc, String timeZoneId);
}
