import '../domain/prayer_local_date.dart';
import '../domain/prayer_preferences.dart';
import '../domain/prayer_schedule.dart';

/// Returns a validated day from the device's owner-scoped annual timetable.
/// A null result means that the local calculator must be used for this date.
abstract interface class PrayerAnnualSchedulePort {
  Future<PrayerSchedule?> forDate({
    required PrayerPreferences preferences,
    required PrayerLocalDate date,
  });
}
