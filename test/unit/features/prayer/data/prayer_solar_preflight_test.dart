import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/data/adhan_prayer_calculator.dart';
import 'package:namma_project/features/prayer/data/prayer_solar_preflight.dart';

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
    },
  );

  test('ordinary sunrise survives when summer twilight never reaches angle', () {
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
  });

  test('interval-based Isha is unavailable without a real sunset', () {
    final check = PrayerSolarPreflight(
      DateTime.utc(2026, 6, 21),
      adhan.Coordinates(69.6492, 18.9553),
      AdhanPrayerCalculator.parameters('ummAlQura'),
    );
    expect(check.sunsetAvailable, isFalse);
    expect(check.ishaAvailable, isFalse);
  });
}
