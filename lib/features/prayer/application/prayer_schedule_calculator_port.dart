import 'package:namma_project/core/domain/results/app_result.dart';
import '../domain/prayer_local_date.dart';
import '../domain/prayer_preferences.dart';
import '../domain/prayer_schedule.dart';

abstract interface class PrayerScheduleCalculatorPort {
  AppResult<PrayerSchedule> calculate({
    required PrayerPreferences preferences,
    required PrayerLocalDate date,
  });
}
