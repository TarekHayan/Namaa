import 'prayer_name.dart';

/// Ordinary resident obligatory counts. Optional prayers are separate.
int residentObligatoryRakahs(PrayerName name) => switch (name) {
  PrayerName.fajr => 2,
  PrayerName.dhuhr || PrayerName.asr || PrayerName.isha => 4,
  PrayerName.maghrib => 3,
};
