import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/data/adhan_prayer_calculator.dart';
import 'package:namma_project/features/prayer/data/prayer_solar_preflight.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';

void main() {
  test('regular latitude has raw solar events for all five prayers', () {
    final check = PrayerSolarPreflight(
      DateTime.utc(2026, 3, 20),
      adhan.Coordinates(30.0444, 31.2357),
      AdhanPrayerCalculator.parameters('egyptian'),
    );
    expect(check.sunriseAvailable, isTrue);
    expect(check.sunsetAvailable, isTrue);
    expect(check.dhuhrAvailable, isTrue);
    expect(check.asrAvailable, isTrue);
    expect(check.fajrAvailable, isTrue);
    expect(check.ishaAvailable, isTrue);
  });

  test(
    'polar day does not present a substituted twilight as observed time',
    () {
      final check = PrayerSolarPreflight(
        DateTime.utc(2026, 6, 21),
        adhan.Coordinates(69.6492, 18.9553),
        AdhanPrayerCalculator.parameters('egyptian'),
      );
      expect(check.sunriseAvailable, isFalse);
      expect(check.sunsetAvailable, isFalse);
      expect(check.fajrAvailable, isFalse);
      expect(check.ishaAvailable, isFalse);
      expect(check.asrAvailable, isTrue);
    },
  );

  test(
    'ordinary sunrise survives when summer twilight never reaches angle',
    () {
      final check = PrayerSolarPreflight(
        DateTime.utc(2026, 6, 21),
        adhan.Coordinates(59.3293, 18.0686),
        AdhanPrayerCalculator.parameters('egyptian'),
      );
      expect(check.sunriseAvailable, isTrue);
      expect(check.sunsetAvailable, isTrue);
      expect(check.dhuhrAvailable, isTrue);
      expect(check.asrAvailable, isTrue);
      expect(check.fajrAvailable, isFalse);
      expect(check.ishaAvailable, isFalse);
    },
  );

  test('interval-based Isha is unavailable without a real sunset', () {
    final check = PrayerSolarPreflight(
      DateTime.utc(2026, 6, 21),
      adhan.Coordinates(69.6492, 18.9553),
      AdhanPrayerCalculator.parameters('ummAlQura'),
    );
    expect(check.sunsetAvailable, isFalse);
    expect(check.ishaAvailable, isFalse);
  });

  test('zero coordinates are valid solar inputs', () {
    final check = PrayerSolarPreflight(
      DateTime.utc(2026, 3, 20),
      adhan.Coordinates(0, 0),
      AdhanPrayerCalculator.parameters('egyptian'),
    );
    expect(check.sunriseAvailable, isTrue);
    expect(check.sunsetAvailable, isTrue);
    expect(check.fajrAvailable, isTrue);
    expect(check.ishaAvailable, isTrue);
  });

  test(
    'polar library substitutions remain unavailable in the public schedule',
    () {
      final preferences = PrayerPreferences(
        accountId: 'owner',
        city: PrayerCity(
          provider: 'fixture',
          providerCityId: 'tromso',
          name: 'Tromso',
          countryCode: 'NO',
          countryName: 'Norway',
          latitude: 69.6492,
          longitude: 18.9553,
          timeZoneId: 'Europe/Oslo',
        ),
        calculationMethod: 'egyptian',
        revision: 1,
        updatedAt: DateTime.utc(2026),
      );
      final schedule = AdhanPrayerCalculator()
          .calculate(
            preferences: preferences,
            date: PrayerLocalDate.parse('2026-06-21'),
          )
          .valueOrNull;
      expect(schedule, isNotNull);
      expect(schedule!.sunriseUtc, isNull);
      expect(schedule.times[PrayerName.fajr]?.instantUtc, isNull);
      expect(schedule.times[PrayerName.maghrib]?.instantUtc, isNull);
      expect(schedule.times[PrayerName.isha]?.instantUtc, isNull);
      expect(schedule.times[PrayerName.dhuhr]?.instantUtc, isNotNull);
      expect(schedule.times[PrayerName.asr]?.instantUtc, isNotNull);
    },
  );
}
