import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';

void main() {
  test('canonical prayer names and completion states', () {
    expect(PrayerName.values.map((value) => value.name), [
      'fajr',
      'dhuhr',
      'asr',
      'maghrib',
      'isha',
    ]);
    expect(PrayerStatus.values.map((value) => value.name), [
      'pending',
      'completedOnTime',
      'completedLate',
      'missed',
    ]);
    expect(PrayerStatus.pending.isCompleted, isFalse);
    expect(PrayerStatus.missed.isCompleted, isFalse);
    expect(PrayerStatus.completedLate.isCompleted, isTrue);
  });

  test('date strictly validates real Gregorian days', () {
    expect(PrayerLocalDate.parse('2024-02-29').value, '2024-02-29');
    for (final invalid in [
      '2025-02-29',
      '2026-13-01',
      '2026-02-30',
      '2026-2-01',
      '2026-01-01T00:00:00Z',
    ]) {
      expect(() => PrayerLocalDate.parse(invalid), throwsArgumentError);
    }
  });

  test('finite city coordinates include zero and reject bounds', () {
    expect(
      PrayerCity(
        provider: 'test',
        providerCityId: '0',
        name: 'Zero',
        countryCode: 'ZZ',
        countryName: 'Zero',
        latitude: 0,
        longitude: 0,
        timeZoneId: 'Etc/UTC',
      ).latitude,
      0,
    );
    for (final latitude in [double.nan, double.infinity, 91.0]) {
      expect(
        () => PrayerCity(
          provider: 'test',
          providerCityId: '1',
          name: 'Invalid',
          countryCode: 'ZZ',
          countryName: 'Invalid',
          latitude: latitude,
          longitude: 0,
          timeZoneId: 'Etc/UTC',
        ),
        throwsArgumentError,
      );
    }
    for (final longitude in [double.nan, double.negativeInfinity, 181.0]) {
      expect(
        () => PrayerCity(
          provider: 'test',
          providerCityId: '1',
          name: 'Invalid',
          countryCode: 'ZZ',
          countryName: 'Invalid',
          latitude: 0,
          longitude: longitude,
          timeZoneId: 'Etc/UTC',
        ),
        throwsArgumentError,
      );
    }
  });

  test('report completion timestamp matches status and is UTC', () {
    expect(
      () => PrayerReport(
        accountId: 'owner',
        reportId: 'report',
        date: PrayerLocalDate.parse('2026-10-29'),
        name: PrayerName.fajr,
        status: PrayerStatus.completedOnTime,
        recordedZoneId: 'Etc/UTC',
        recordedOffsetMinutes: 0,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
    expect(
      () => PrayerReport(
        accountId: 'owner',
        reportId: 'report',
        date: PrayerLocalDate.parse('2026-10-29'),
        name: PrayerName.fajr,
        status: PrayerStatus.pending,
        reportedCompletionAt: DateTime.now(),
        recordedZoneId: 'Etc/UTC',
        recordedOffsetMinutes: 0,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
  });

  test('schedule field rejects non-UTC instants', () {
    expect(
      () =>
          PrayerTime(name: PrayerName.fajr, instantUtc: DateTime(2026, 10, 29)),
      throwsArgumentError,
    );
    expect(
      PrayerTime(
        name: PrayerName.fajr,
        instantUtc: DateTime.utc(2026, 10, 29),
      ).instantUtc!.isUtc,
      isTrue,
    );
  });
}
