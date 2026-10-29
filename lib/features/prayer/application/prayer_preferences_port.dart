import 'package:namma_project/core/domain/results/app_result.dart';
import '../domain/prayer_preferences.dart';

abstract interface class PrayerPreferencesPort {
  Future<AppResult<PrayerPreferences?>> read(String accountId);
  Stream<PrayerPreferences?> watch(String accountId);
  Future<AppResult<PrayerPreferences>> save(
    PrayerPreferences preferences, {
    required int? expectedRevision,
  });
}
