import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/prayer/data/aladhan_annual_schedule.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';

import '../../../../support/foundation_test_support.dart';

void main() {
  test(
    'live Cairo annual calendar is accepted and cached offline',
    () async {
      final path = TemporaryDatabasePath();
      FoundationDatabase? database;
      try {
        database = await FoundationDatabase.openEncrypted(
          path: path.allocate(),
          key: List<int>.generate(32, (i) => i + 30),
        );
        final preferences = PrayerPreferences(
          accountId: 'live-cairo-check',
          city: PrayerCity(
            provider: 'device',
            providerCityId: 'cairo',
            name: 'Current location',
            countryCode: 'XX',
            countryName: 'GPS',
            latitude: 30.0444,
            longitude: 31.2357,
            timeZoneId: 'Africa/Cairo',
          ),
          calculationMethod: 'egyptian',
          revision: 1,
          updatedAt: DateTime.utc(2026),
        );
        final day = PrayerLocalDate.parse('2026-11-01');
        final probe = await Dio().getUri<dynamic>(
          Uri.https('api.aladhan.com', '/v1/calendar/2026', {
            'latitude': '30.0444',
            'longitude': '31.2357',
            'method': '5',
            'school': '0',
            'timezonestring': 'Africa/Cairo',
            'iso8601': 'true',
          }),
        );
        final body = probe.data as Map;
        final months = body['data'] as Map;
        for (var month = 1; month <= 12; month++) {
          final rows = months['$month'] as List;
          for (final row in rows) {
            final meta = row['meta'] as Map;
            expect(meta['timezone'], 'Africa/Cairo');
            expect(meta['method']['id'], 5);
            expect(meta['school'], 'STANDARD');
            for (final field in const [
              'Fajr',
              'Sunrise',
              'Dhuhr',
              'Asr',
              'Maghrib',
              'Isha',
            ]) {
              final raw = row['timings'][field] as String;
              expect(raw, isA<String>());
              expect(
                DateTime.tryParse(raw),
                isNotNull,
                reason:
                    '$month ${row['date']['gregorian']['date']} $field=$raw',
              );
            }
          }
        }
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) => handler.resolve(
                Response(requestOptions: options, data: body),
              ),
            ),
          );
        final source = AlAdhanAnnualSchedule(
          database,
          dio: dio,
          hasNetwork: () async => true,
        );
        final schedule = await source.forDate(
          preferences: preferences,
          date: day,
        );
        expect(schedule?.provenance, startsWith('AlAdhan API'));
        expect(
          schedule?.times[PrayerName.fajr]?.instantUtc,
          DateTime.utc(2026, 11, 1, 2, 41),
        );
        expect(
          schedule?.times[PrayerName.maghrib]?.instantUtc,
          DateTime.utc(2026, 11, 1, 15, 8),
        );
        final offline = AlAdhanAnnualSchedule(
          database,
          hasNetwork: () async => false,
        );
        final cached = await offline.forDate(
          preferences: preferences,
          date: day,
        );
        expect(
          cached?.times[PrayerName.fajr]?.instantUtc,
          schedule?.times[PrayerName.fajr]?.instantUtc,
        );
      } finally {
        await database?.close();
        path.dispose();
      }
    },
    skip: !const bool.fromEnvironment('PRAYER_LIVE_API'),
  );
}
