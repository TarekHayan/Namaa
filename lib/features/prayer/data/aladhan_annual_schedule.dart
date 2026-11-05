import 'dart:async';
import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:timezone/timezone.dart' as tz;

import '../application/prayer_annual_schedule_port.dart';
import '../domain/prayer_local_date.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_preferences.dart';
import '../domain/prayer_schedule.dart';
import 'adhan_prayer_calculator.dart';
import 'prayer_solar_preflight.dart';
import 'prayer_timezone_initializer.dart';

/// Downloads a Gregorian year once and keeps it in the encrypted local store.
/// An incomplete or mismatched response never replaces an existing year.
final class AlAdhanAnnualSchedule implements PrayerAnnualSchedulePort {
  AlAdhanAnnualSchedule(
    this._database, {
    Dio? dio,
    Future<bool> Function()? hasNetwork,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 5),
               receiveTimeout: const Duration(seconds: 20),
             ),
           ),
       _hasNetwork = hasNetwork ?? (() async => true) {
    initializePrayerTimeZones();
  }

  final FoundationDatabase _database;
  final Dio _dio;
  final Future<bool> Function() _hasNetwork;
  final Map<String, Future<Map<String, dynamic>?>> _inFlight = {};
  final Set<String> _warming = {};

  static const _methodIds = <String, int>{
    'egyptian': 5,
    'muslimWorldLeague': 3,
    'ummAlQura': 4,
    'dubai': 16,
    'northAmerica': 2,
    'kuwait': 9,
    'qatar': 10,
  };

  static const _fields = <String>[
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  @override
  Future<PrayerSchedule?> forDate({
    required PrayerPreferences preferences,
    required PrayerLocalDate date,
  }) async {
    final year = int.parse(date.value.substring(0, 4));
    final methodId = _methodIds[preferences.calculationMethod];
    if (methodId == null) return null;
    final contextKey = jsonEncode([
      preferences.city.provider,
      preferences.city.providerCityId,
      preferences.city.latitude,
      preferences.city.longitude,
      preferences.city.timeZoneId,
      methodId,
      0, // Standard/Shafi Asr.
      'verified-zone-offset-v2', // Ignore timetables cached before offset validation.
    ]);
    final requestKey = jsonEncode([preferences.accountId, contextKey, year]);
    try {
      final cached = await _read(preferences.accountId, contextKey, year);
      final days =
          cached ??
          await (_inFlight[requestKey] ??=
              _downloadAndStore(
                preferences: preferences,
                contextKey: contextKey,
                year: year,
                methodId: methodId,
              ).whenComplete(() {
                _inFlight.remove(requestKey);
              }));
      if (days != null && year < 9998) {
        unawaited(
          _warmNextYear(
            preferences: preferences,
            contextKey: contextKey,
            year: year + 1,
            methodId: methodId,
          ),
        );
      }
      final rawDay = days?[date.value];
      if (rawDay is! Map<String, dynamic>) return null;
      final parts = date.value.split('-').map(int.parse).toList();
      final solar = PrayerSolarPreflight(
        DateTime.utc(parts[0], parts[1], parts[2]),
        adhan.Coordinates(
          preferences.city.latitude,
          preferences.city.longitude,
        ),
        AdhanPrayerCalculator.parameters(preferences.calculationMethod),
      );
      bool possible(PrayerName name) => switch (name) {
        PrayerName.fajr => solar.fajrAvailable,
        PrayerName.dhuhr => solar.dhuhrAvailable,
        PrayerName.asr => solar.asrAvailable,
        PrayerName.maghrib => solar.sunsetAvailable,
        PrayerName.isha => solar.ishaAvailable,
      };
      final times = <PrayerName, PrayerTime>{};
      for (final name in PrayerName.values) {
        final value = rawDay[_apiName(name)];
        if (value is! String) return null;
        final available = possible(name);
        times[name] = PrayerTime(
          name: name,
          instantUtc: available ? DateTime.parse(value).toUtc() : null,
          unavailableReason: available ? null : 'solar_event_unavailable',
        );
      }
      final sunrise = rawDay['Sunrise'];
      if (sunrise is! String) return null;
      return PrayerSchedule(
        date: date,
        contextRevision: preferences.revision,
        times: times,
        sunriseUtc: solar.sunriseAvailable
            ? DateTime.parse(sunrise).toUtc()
            : null,
        provenance: 'AlAdhan API · ${preferences.calculationMethod}',
      );
    } catch (_) {
      // A missing/invalid cache or network outage is handled by the explicit
      // local calculator fallback in PrayerContextService.
      return null;
    }
  }

  static String _apiName(PrayerName name) => switch (name) {
    PrayerName.fajr => 'Fajr',
    PrayerName.dhuhr => 'Dhuhr',
    PrayerName.asr => 'Asr',
    PrayerName.maghrib => 'Maghrib',
    PrayerName.isha => 'Isha',
  };

  Future<void> _warmNextYear({
    required PrayerPreferences preferences,
    required String contextKey,
    required int year,
    required int methodId,
  }) async {
    final key = jsonEncode([preferences.accountId, contextKey, year]);
    if (!_warming.add(key)) return;
    try {
      if (await _read(preferences.accountId, contextKey, year) != null) return;
      await (_inFlight[key] ??=
          _downloadAndStore(
            preferences: preferences,
            contextKey: contextKey,
            year: year,
            methodId: methodId,
          ).whenComplete(() {
            _inFlight.remove(key);
          }));
    } catch (_) {
      // The requested day remains available; retry the next year on the next
      // visit or after connectivity returns.
    } finally {
      _warming.remove(key);
    }
  }

  Future<Map<String, dynamic>?> _read(
    String accountId,
    String contextKey,
    int year,
  ) async {
    final row = await _database
        .customSelect(
          'SELECT days_json FROM prayer_annual_timetables '
          'WHERE account_id = ? AND context_key = ? AND calendar_year = ?',
          variables: [
            Variable.withString(accountId),
            Variable.withString(contextKey),
            Variable.withInt(year),
          ],
        )
        .getSingleOrNull();
    if (row == null) return null;
    final value = jsonDecode(row.read<String>('days_json'));
    return value is Map<String, dynamic> && value.length == _daysIn(year)
        ? value
        : null;
  }

  Future<Map<String, dynamic>?> _downloadAndStore({
    required PrayerPreferences preferences,
    required String contextKey,
    required int year,
    required int methodId,
  }) async {
    try {
      if (!await _hasNetwork()) return null;
      final uri = Uri.https('api.aladhan.com', '/v1/calendar/$year', {
        'latitude': preferences.city.latitude.toString(),
        'longitude': preferences.city.longitude.toString(),
        'method': methodId.toString(),
        'school': '0',
        'timezonestring': preferences.city.timeZoneId,
        'iso8601': 'true',
      });
      Response<dynamic>? response;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          response = await _dio.getUri<dynamic>(uri);
          break;
        } on DioException catch (error) {
          final status = error.response?.statusCode;
          final retryable =
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              status == 429 ||
              (status != null && status >= 500);
          if (!retryable || attempt == 2) rethrow;
          await Future<void>.delayed(
            Duration(milliseconds: 300 * (attempt + 1)),
          );
        }
      }
      if (response == null) return null;
      final body = response.data;
      if (body is! Map || body['code'] != 200) return null;
      final months = body['data'];
      final rows = <dynamic>[];
      if (months is Map) {
        for (var month = 1; month <= 12; month++) {
          final values = months['$month'];
          if (values is! List) return null;
          rows.addAll(values);
        }
      } else if (months is List) {
        for (final values in months) {
          if (values is! List) return null;
          rows.addAll(values);
        }
      } else {
        return null;
      }
      if (rows.length != _daysIn(year)) return null;
      final zone = tz.getLocation(preferences.city.timeZoneId);
      final days = <String, dynamic>{};
      for (final row in rows) {
        if (row is! Map) return null;
        final gregorian = row['date'] is Map ? row['date']['gregorian'] : null;
        final rawDate = gregorian is Map ? gregorian['date'] : null;
        final date = _parseApiDate(rawDate, year);
        final meta = row['meta'];
        final method = meta is Map ? meta['method'] : null;
        if (date == null ||
            meta is! Map ||
            meta['timezone'] != preferences.city.timeZoneId ||
            method is! Map ||
            method['id'] != methodId ||
            meta['school'] != 'STANDARD') {
          return null;
        }
        final timing = row['timings'];
        if (timing is! Map) return null;
        final values = <String, String>{};
        for (final field in _fields) {
          final raw = timing[field];
          if (raw is! String || !raw.contains('T')) return null;
          final instant = DateTime.tryParse(raw)?.toUtc();
          if (instant == null ||
              _declaredOffsetMinutes(raw) !=
                  tz.TZDateTime.from(instant, zone).timeZoneOffset.inMinutes ||
              _localDate(tz.TZDateTime.from(instant, zone)) != date) {
            return null;
          }
          values[field] = instant.toIso8601String();
        }
        final ordered = _fields
            .map((field) => DateTime.parse(values[field]!))
            .toList();
        for (var i = 1; i < ordered.length; i++) {
          if (!ordered[i].isAfter(ordered[i - 1])) return null;
        }
        if (days.containsKey(date)) return null;
        days[date] = values;
      }
      for (
        var day = DateTime.utc(year);
        day.year == year;
        day = day.add(const Duration(days: 1))
      ) {
        if (!days.containsKey(_localDate(day))) return null;
      }
      await _database.customStatement(
        'INSERT INTO prayer_annual_timetables '
        '(account_id, context_key, calendar_year, days_json, fetched_at) '
        'VALUES (?, ?, ?, ?, ?) '
        'ON CONFLICT (account_id, context_key, calendar_year) DO UPDATE SET '
        'days_json = excluded.days_json, fetched_at = excluded.fetched_at',
        [
          preferences.accountId,
          contextKey,
          year,
          jsonEncode(days),
          DateTime.now().toUtc().toIso8601String(),
        ],
      );
      return days;
    } catch (_) {
      return null;
    }
  }

  static int _daysIn(int year) =>
      DateTime.utc(year + 1).difference(DateTime.utc(year)).inDays;

  static String? _parseApiDate(Object? raw, int year) {
    if (raw is! String) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final parsedYear = int.tryParse(parts[2]);
    if (day == null || month == null || parsedYear != year) return null;
    try {
      return PrayerLocalDate.parse(
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
      ).value;
    } catch (_) {
      return null;
    }
  }

  static String _localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static int? _declaredOffsetMinutes(String value) {
    if (value.endsWith('Z')) return 0;
    final match = RegExp(r'([+-])(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final hours = int.parse(match.group(2)!);
    final minutes = int.parse(match.group(3)!);
    if (hours > 23 || minutes > 59) return null;
    final total = hours * 60 + minutes;
    return match.group(1) == '-' ? -total : total;
  }
}
