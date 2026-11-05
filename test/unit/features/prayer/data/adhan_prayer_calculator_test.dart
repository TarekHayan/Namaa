import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/data/adhan_prayer_calculator.dart';
import 'package:namma_project/features/prayer/data/prayer_timezone_initializer.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('prototype parity excludes the approved Ramadan Isha adjustment', () {
    final source =
        (jsonDecode(
                  File(
                    'test/fixtures/prayer/calculation/aladhan_reference.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();
    final prototype =
        (jsonDecode(
                  File(
                    'test/fixtures/prayer/calculation/prototype_parity.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();
    expect(prototype, hasLength(source.length));
    final differences = <String>[];
    for (var index = 0; index < source.length; index++) {
      final row = source[index];
      final expected = prototype[index];
      final parts = (row['date'] as String).split('-').map(int.parse).toList();
      final date = PrayerLocalDate.parse(
        '${parts[2]}-${parts[1].toString().padLeft(2, '0')}-${parts[0].toString().padLeft(2, '0')}',
      );
      expect(expected['city'], row['city']);
      expect(expected['method'], row['method']);
      expect(expected['date'], date.value);
      final city = PrayerCity(
        provider: 'fixture',
        providerCityId: row['city'] as String,
        name: row['city'] as String,
        countryCode: 'XX',
        countryName: 'Fixture',
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        timeZoneId: row['zone'] as String,
      );
      final actual = AdhanPrayerCalculator()
          .calculate(
            preferences: PrayerPreferences(
              accountId: 'owner',
              city: city,
              calculationMethod: row['method'] as String,
              revision: 1,
              updatedAt: DateTime.utc(2026),
            ),
            date: date,
          )
          .valueOrNull;
      expect(actual, isNotNull);
      final observed = <String, DateTime?>{
        'fajr': actual!.times[PrayerName.fajr]?.instantUtc,
        'sunrise': actual.sunriseUtc,
        'dhuhr': actual.times[PrayerName.dhuhr]?.instantUtc,
        'asr': actual.times[PrayerName.asr]?.instantUtc,
        'maghrib': actual.times[PrayerName.maghrib]?.instantUtc,
        'isha': actual.times[PrayerName.isha]?.instantUtc,
      };
      final reference = expected['utc'] as Map<String, dynamic>;
      for (final entry in observed.entries) {
        final utc = DateTime.parse(reference[entry.key] as String);
        final seconds = entry.value!.difference(utc).abs().inSeconds;
        if (seconds > 60) {
          final detail =
              '${row['city']} ${row['method']} ${date.value} '
              '${entry.key}: ${seconds}s';
          final isRamadanIsha =
              row['method'] == 'ummAlQura' &&
              date.value == '2026-03-08' &&
              entry.key == 'isha' &&
              seconds == 1800;
          final isDubaiPresetAdjustment =
              row['method'] == 'dubai' &&
              ((entry.key == 'sunrise' && seconds == 180) ||
                  (entry.key == 'asr' && seconds == 240));
          expect(
            isRamadanIsha || isDubaiPresetAdjustment,
            isTrue,
            reason: detail,
          );
          differences.add(detail);
        }
      }
    }
    expect(differences, hasLength(27));
  });

  test('seven presets cover all independently captured cities and dates', () {
    initializePrayerTimeZones();
    final rows =
        (jsonDecode(
                  File(
                    'test/fixtures/prayer/calculation/aladhan_reference.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();
    expect(rows, hasLength(84));
    expect(rows.map((row) => row['city']).toSet(), {
      'Cairo',
      'Dubai',
      'New York',
    });
    expect(
      rows.map((row) => row['method']).toSet(),
      AdhanPrayerCalculator.methods,
    );

    final unexpected = <String>[];
    for (final row in rows) {
      final parts = (row['date'] as String).split('-').map(int.parse).toList();
      final date = PrayerLocalDate.parse(
        '${parts[2]}-${parts[1].toString().padLeft(2, '0')}-${parts[0].toString().padLeft(2, '0')}',
      );
      final city = PrayerCity(
        provider: 'fixture',
        providerCityId: row['city'] as String,
        name: row['city'] as String,
        countryCode: 'XX',
        countryName: 'Fixture',
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        timeZoneId: row['zone'] as String,
      );
      final pref = PrayerPreferences(
        accountId: 'owner',
        city: city,
        calculationMethod: row['method'] as String,
        revision: 1,
        updatedAt: DateTime.utc(2026),
      );
      final actual = AdhanPrayerCalculator()
          .calculate(preferences: pref, date: date)
          .valueOrNull;
      expect(actual, isNotNull, reason: '${row['city']} ${row['date']}');
      final zone = tz.getLocation(row['zone'] as String);
      final timings = row['timings'] as Map<String, dynamic>;
      DateTime reference(String label) {
        final time = (timings[label] as String).substring(0, 5).split(':');
        return tz.TZDateTime(
          zone,
          parts[2],
          parts[1],
          parts[0],
          int.parse(time[0]),
          int.parse(time[1]),
        ).toUtc();
      }

      final observed = <String, DateTime?>{
        'Fajr': actual!.times[PrayerName.fajr]?.instantUtc,
        'Sunrise': actual.sunriseUtc,
        'Dhuhr': actual.times[PrayerName.dhuhr]?.instantUtc,
        'Asr': actual.times[PrayerName.asr]?.instantUtc,
        'Maghrib': actual.times[PrayerName.maghrib]?.instantUtc,
        'Isha': actual.times[PrayerName.isha]?.instantUtc,
      };
      for (final entry in observed.entries) {
        final got = entry.value;
        expect(
          got,
          isNotNull,
          reason: '${row['city']} ${row['date']} ${entry.key}',
        );
        final delta = got!.difference(reference(entry.key)).abs();
        if (delta <= const Duration(minutes: 1)) continue;
        final detail =
            '${row['city']} ${row['method']} ${row['date']} ${entry.key}: ${delta.inSeconds}s';
        unexpected.add(detail);
      }
    }
    expect(unexpected, isEmpty);
  });

  test('Umm al-Qura uses 120-minute Isha in Ramadan and 90 otherwise', () {
    final ramadan = AdhanPrayerCalculator.parameters(
      'ummAlQura',
      date: DateTime.utc(2026, 3, 8),
    );
    final outsideRamadan = AdhanPrayerCalculator.parameters(
      'ummAlQura',
      date: DateTime.utc(2026, 6, 21),
    );
    expect(ramadan.ishaInterval, 120);
    expect(outsideRamadan.ishaInterval, 90);
    expect(
      AdhanPrayerCalculator.parameters(
        'qatar',
        date: DateTime.utc(2026, 3, 8),
      ).ishaInterval,
      90,
    );
  });

  test('adjacent city dates are calculated independently', () {
    final preferences = PrayerPreferences(
      accountId: 'owner',
      city: PrayerCity(
        provider: 'fixture',
        providerCityId: 'cairo',
        name: 'Cairo',
        countryCode: 'EG',
        countryName: 'Egypt',
        latitude: 30.0444,
        longitude: 31.2357,
        timeZoneId: 'Africa/Cairo',
      ),
      calculationMethod: 'egyptian',
      revision: 1,
      updatedAt: DateTime.utc(2026),
    );
    final calculator = AdhanPrayerCalculator();
    final today = calculator
        .calculate(
          preferences: preferences,
          date: PrayerLocalDate.parse('2026-03-20'),
        )
        .valueOrNull;
    final tomorrow = calculator
        .calculate(
          preferences: preferences,
          date: PrayerLocalDate.parse('2026-03-21'),
        )
        .valueOrNull;
    expect(today, isNotNull);
    expect(tomorrow, isNotNull);
    expect(today!.date.value, '2026-03-20');
    expect(tomorrow!.date.value, '2026-03-21');
    expect(tomorrow.sunriseUtc!.difference(today.sunriseUtc!).inHours, 23);
  });

  test('zero-coordinate and polar output follows independent edge fixtures', () {
    initializePrayerTimeZones();
    final rows =
        (jsonDecode(
                  File(
                    'test/fixtures/prayer/calculation/praytimes_edge_reference.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();
    expect(rows, hasLength(2));
    for (final row in rows) {
      final day = PrayerLocalDate.parse(row['date'] as String);
      final city = PrayerCity(
        provider: 'fixture',
        providerCityId: row['case'] as String,
        name: row['case'] as String,
        countryCode: 'XX',
        countryName: 'Fixture',
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        timeZoneId: row['zone'] as String,
      );
      final schedule = AdhanPrayerCalculator()
          .calculate(
            preferences: PrayerPreferences(
              accountId: 'owner',
              city: city,
              calculationMethod: row['method'] as String,
              revision: 1,
              updatedAt: DateTime.utc(2026),
            ),
            date: day,
          )
          .valueOrNull;
      expect(schedule, isNotNull, reason: row['case'] as String);
      final actual = <String, DateTime?>{
        'fajr': schedule!.times[PrayerName.fajr]?.instantUtc,
        'sunrise': schedule.sunriseUtc,
        'dhuhr': schedule.times[PrayerName.dhuhr]?.instantUtc,
        'asr': schedule.times[PrayerName.asr]?.instantUtc,
        'maghrib': schedule.times[PrayerName.maghrib]?.instantUtc,
        'isha': schedule.times[PrayerName.isha]?.instantUtc,
      };
      final reference = row['utc'] as Map<String, dynamic>;
      for (final entry in reference.entries) {
        final observed = actual[entry.key];
        if (entry.value == null) {
          expect(observed, isNull, reason: '${row['case']} ${entry.key}');
          continue;
        }
        final expected = DateTime.parse(entry.value as String);
        expect(observed, isNotNull, reason: '${row['case']} ${entry.key}');
        expect(
          observed!.difference(expected).abs(),
          lessThanOrEqualTo(const Duration(minutes: 1)),
          reason: '${row['case']} ${entry.key}',
        );
      }
    }
  });
}
