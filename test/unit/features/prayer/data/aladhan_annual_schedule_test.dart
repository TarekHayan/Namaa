import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/prayer/data/aladhan_annual_schedule.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';

import '../../../../support/foundation_test_support.dart';

PrayerPreferences _preference(String owner, {String method = 'egyptian'}) =>
    PrayerPreferences(
      accountId: owner,
      city: PrayerCity(
        provider: 'fixture',
        providerCityId: 'zero',
        name: 'Zero',
        countryCode: 'GB',
        countryName: 'United Kingdom',
        latitude: 0,
        longitude: 0,
        timeZoneId: 'Etc/UTC',
      ),
      calculationMethod: method,
      revision: 1,
      updatedAt: DateTime.utc(2026),
    );

Map<String, dynamic> _year({int year = 2026, bool complete = true}) {
  final months = <String, dynamic>{};
  for (var month = 1; month <= 12; month++) {
    final rows = <Map<String, dynamic>>[];
    for (
      var day = DateTime.utc(year, month);
      day.month == month && day.year == year;
      day = day.add(const Duration(days: 1))
    ) {
      if (!complete && day.day == 10 && day.month == 1) continue;
      String at(int hour) =>
          DateTime.utc(day.year, day.month, day.day, hour).toIso8601String();
      rows.add({
        'date': {
          'gregorian': {
            'date':
                '${day.day.toString().padLeft(2, '0')}-'
                '${month.toString().padLeft(2, '0')}-$year',
          },
        },
        'meta': {
          'timezone': 'Etc/UTC',
          'method': {'id': 5},
          'school': 'STANDARD',
        },
        'timings': {
          'Fajr': at(5),
          'Sunrise': at(6),
          'Dhuhr': at(12),
          'Asr': at(15),
          'Maghrib': at(18),
          'Isha': at(20),
        },
      });
    }
    months['$month'] = rows;
  }
  return {'code': 200, 'data': months};
}

void main() {
  final key = List<int>.generate(32, (i) => i + 20);
  test(
    'downloads a complete year once; cached dates survive offline restart',
    () async {
      final path = TemporaryDatabasePath();
      FoundationDatabase? db;
      try {
        final file = path.allocate();
        db = await FoundationDatabase.openEncrypted(path: file, key: key);
        var calls = 0;
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                calls++;
                expect(options.uri.path, startsWith('/v1/calendar/'));
                expect(options.uri.queryParameters['method'], '5');
                expect(options.uri.queryParameters['latitude'], '0.0');
                final result = _year(
                  year: int.parse(options.uri.pathSegments.last),
                );
                handler.resolve(
                  Response(requestOptions: options, data: result),
                );
              },
            ),
          );
        final source = AlAdhanAnnualSchedule(
          db,
          dio: dio,
          hasNetwork: () async => true,
        );
        final first = await source.forDate(
          preferences: _preference('owner'),
          date: PrayerLocalDate.parse('2026-01-01'),
        );
        final last = await source.forDate(
          preferences: _preference('owner'),
          date: PrayerLocalDate.parse('2026-12-31'),
        );
        for (var i = 0; i < 20; i++) {
          final count = await db.rawScalar(
            'SELECT count(*) FROM prayer_annual_timetables',
          );
          if (count == 2) break;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(calls, 2);
        expect(
          await db.rawScalar('SELECT count(*) FROM prayer_annual_timetables'),
          2,
        );
        expect(
          first!.times[PrayerName.fajr]!.instantUtc,
          DateTime.utc(2026, 1, 1, 5),
        );
        expect(
          last!.times[PrayerName.isha]!.instantUtc,
          DateTime.utc(2026, 12, 31, 20),
        );
        expect(first.provenance, contains('AlAdhan'));
        await db.close();
        db = await FoundationDatabase.openEncrypted(path: file, key: key);
        var offlineCalls = 0;
        final offline = AlAdhanAnnualSchedule(
          db,
          hasNetwork: () async => false,
          dio: Dio()
            ..interceptors.add(
              InterceptorsWrapper(
                onRequest: (options, handler) {
                  offlineCalls++;
                  handler.reject(DioException(requestOptions: options));
                },
              ),
            ),
        );
        expect(
          (await offline.forDate(
            preferences: _preference('owner'),
            date: PrayerLocalDate.parse('2027-06-21'),
          ))?.times[PrayerName.dhuhr]?.instantUtc,
          DateTime.utc(2027, 6, 21, 12),
        );
        expect(offlineCalls, 0);
        expect(
          await offline.forDate(
            preferences: _preference('other'),
            date: PrayerLocalDate.parse('2026-06-21'),
          ),
          isNull,
        );
        expect(offlineCalls, 0);
        expect(
          await db.rawScalar(
            "SELECT count(*) FROM prayer_annual_timetables WHERE account_id='other'",
          ),
          0,
        );
      } finally {
        await db?.close();
        path.dispose();
      }
    },
  );

  test('partial annual response is never persisted', () async {
    final path = TemporaryDatabasePath();
    final db = await FoundationDatabase.openEncrypted(
      path: path.allocate(),
      key: key,
    );
    try {
      final source = AlAdhanAnnualSchedule(
        db,
        hasNetwork: () async => true,
        dio: Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: _year(complete: false),
                  ),
                );
              },
            ),
          ),
      );
      expect(
        await source.forDate(
          preferences: _preference('owner'),
          date: PrayerLocalDate.parse('2026-01-01'),
        ),
        isNull,
      );
      expect(
        await db.rawScalar('SELECT count(*) FROM prayer_annual_timetables'),
        0,
      );
    } finally {
      await db.close();
      path.dispose();
    }
  });

  test(
    'annual response with an offset inconsistent with its IANA zone is rejected',
    () async {
      final path = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: path.allocate(),
        key: key,
      );
      try {
        final body = _year();
        final first = (body['data'] as Map<String, dynamic>)['1'] as List;
        final timings =
            (first.first as Map<String, dynamic>)['timings']
                as Map<String, dynamic>;
        // Same UTC instant and civil day as the original 05:00Z, but the
        // provider claims a +01:00 offset for Etc/UTC.
        timings['Fajr'] = '2026-01-01T06:00:00+01:00';
        final source = AlAdhanAnnualSchedule(
          db,
          hasNetwork: () async => true,
          dio: Dio()
            ..interceptors.add(
              InterceptorsWrapper(
                onRequest: (options, handler) => handler.resolve(
                  Response(requestOptions: options, data: body),
                ),
              ),
            ),
        );
        expect(
          await source.forDate(
            preferences: _preference('owner'),
            date: PrayerLocalDate.parse('2026-01-01'),
          ),
          isNull,
        );
        expect(
          await db.rawScalar('SELECT count(*) FROM prayer_annual_timetables'),
          0,
        );
      } finally {
        await db.close();
        path.dispose();
      }
    },
  );

  test('a provider year cannot expose substituted summer twilight', () async {
    final path = TemporaryDatabasePath();
    final db = await FoundationDatabase.openEncrypted(
      path: path.allocate(),
      key: key,
    );
    try {
      final preference = PrayerPreferences(
        accountId: 'owner',
        city: PrayerCity(
          provider: 'fixture',
          providerCityId: 'high-latitude',
          name: 'High latitude',
          countryCode: 'XX',
          countryName: 'Fixture',
          latitude: 59.3293,
          longitude: 18.0686,
          timeZoneId: 'Etc/UTC',
        ),
        calculationMethod: 'egyptian',
        revision: 1,
        updatedAt: DateTime.utc(2026),
      );
      final source = AlAdhanAnnualSchedule(
        db,
        hasNetwork: () async => true,
        dio: Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) => handler.resolve(
                Response(
                  requestOptions: options,
                  data: _year(year: int.parse(options.uri.pathSegments.last)),
                ),
              ),
            ),
          ),
      );
      final schedule = await source.forDate(
        preferences: preference,
        date: PrayerLocalDate.parse('2026-06-21'),
      );
      expect(schedule, isNotNull);
      expect(schedule!.times[PrayerName.fajr]?.instantUtc, isNull);
      expect(schedule.times[PrayerName.isha]?.instantUtc, isNull);
      expect(schedule.times[PrayerName.dhuhr]?.instantUtc, isNotNull);
      expect(schedule.sunriseUtc, isNotNull);
    } finally {
      await db.close();
      path.dispose();
    }
  });

  test(
    'transient provider failure retries before using local fallback',
    () async {
      final path = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: path.allocate(),
        key: key,
      );
      try {
        var attempts = 0;
        final source = AlAdhanAnnualSchedule(
          db,
          hasNetwork: () async => true,
          dio: Dio()
            ..interceptors.add(
              InterceptorsWrapper(
                onRequest: (options, handler) {
                  if (options.uri.path.endsWith('/2026')) {
                    attempts++;
                    if (attempts == 1) {
                      handler.reject(
                        DioException(
                          requestOptions: options,
                          response: Response(
                            requestOptions: options,
                            statusCode: 503,
                          ),
                          type: DioExceptionType.badResponse,
                        ),
                      );
                      return;
                    }
                  }
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      data: _year(
                        year: int.parse(options.uri.pathSegments.last),
                      ),
                    ),
                  );
                },
              ),
            ),
        );
        final result = await source.forDate(
          preferences: _preference('owner'),
          date: PrayerLocalDate.parse('2026-11-01'),
        );
        expect(attempts, 2);
        expect(result?.provenance, startsWith('AlAdhan API'));
      } finally {
        await db.close();
        path.dispose();
      }
    },
  );
}
