import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/prayer_annual_schedule_port.dart';
import 'package:namma_project/features/prayer/application/prayer_day_boundaries.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/application/prayer_schedule_calculator_port.dart';
import 'package:namma_project/features/prayer/data/prayer_day_boundaries_reader.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule.dart';

/// T011: the read-only Prayer day boundaries port for Adhkar/Qiyam (T012).
/// The reader must reuse the encrypted annual timetable and the local
/// calculator under 008's rules, and must make no provider access of its own.
void main() {
  final cairo = PrayerCity(
    provider: 'device',
    providerCityId: 'device-fix',
    name: 'Cairo',
    countryCode: 'EG',
    countryName: 'Egypt',
    latitude: 30.0444,
    longitude: 31.2357,
    timeZoneId: 'Africa/Cairo',
  );

  PrayerPreferences prefs({PrayerCity? city, String method = 'Umm al-Qura'}) =>
      PrayerPreferences(
        accountId: 'owner',
        city: city ?? cairo,
        calculationMethod: method,
        revision: 1,
        updatedAt: DateTime.utc(2026, 11, 9, 4),
      );

  PrayerSchedule scheduleWith(
    PrayerLocalDate date, {
    DateTime? fajr,
    DateTime? maghrib,
    String? fajrUnavailableReason,
  }) {
    DateTime? at(String hm) => DateTime.parse('${date.value}T$hm:00Z');
    final resolvedFajr = fajrUnavailableReason == null
        ? (fajr ?? at('05:10'))
        : null;
    return PrayerSchedule(
      date: date,
      contextRevision: 1,
      provenance: 'test',
      times: {
        PrayerName.fajr: PrayerTime(
          name: PrayerName.fajr,
          instantUtc: resolvedFajr,
          unavailableReason: fajrUnavailableReason,
        ),
        PrayerName.dhuhr: PrayerTime(
          name: PrayerName.dhuhr,
          instantUtc: at('12:00'),
        ),
        PrayerName.asr: PrayerTime(
          name: PrayerName.asr,
          instantUtc: at('15:20'),
        ),
        PrayerName.maghrib: PrayerTime(
          name: PrayerName.maghrib,
          instantUtc: maghrib ?? at('17:45'),
        ),
        PrayerName.isha: PrayerTime(
          name: PrayerName.isha,
          instantUtc: at('19:10'),
        ),
      },
    );
  }

  late FakePreferences preferences;
  late FakeAnnual annual;
  late FakeCalculator calculator;
  late PrayerDayBoundariesReader reader;

  setUp(() {
    preferences = FakePreferences(owner: 'owner');
    annual = FakeAnnual();
    calculator = FakeCalculator();
    reader = PrayerDayBoundariesReader(
      preferences: preferences,
      annualSchedules: annual,
      calculator: calculator,
    );
  });

  test(
    'an available date returns the annual-cache instants and the zone',
    () async {
      final date = PrayerLocalDate.parse('2026-11-09');
      annual.schedules[date] = scheduleWith(
        date,
        fajr: DateTime.utc(2026, 11, 9, 3, 10),
      );
      annual.schedules[PrayerLocalDate.parse('2026-11-10')] = scheduleWith(
        PrayerLocalDate.parse('2026-11-10'),
      );
      preferences.stored = prefs();
      final result = await reader.boundaries('owner', date);
      expect(result, isA<PrayerDayBoundariesAvailable>());
      final available = result as PrayerDayBoundariesAvailable;
      expect(available.date, date);
      expect(available.fajrUtc, DateTime.utc(2026, 11, 9, 3, 10));
      expect(available.maghribUtc, DateTime.utc(2026, 11, 9, 17, 45));
      // The next Fajr comes from the D+1 annual cache.
      expect(available.nextFajrUtc, DateTime.utc(2026, 11, 10, 5, 10));
      expect(available.zoneId, 'Africa/Cairo');
      // No calculator fallback happened: no provider access per request.
      expect(calculator.calls, 0);
      expect(annual.calls, 2);
    },
  );

  test(
    'the calculator fallback serves a date missing from the annual cache',
    () async {
      final date = PrayerLocalDate.parse('2026-11-09');
      preferences.stored = prefs();
      calculator.builder = scheduleWith;
      final result = await reader.boundaries('owner', date);
      expect(result, isA<PrayerDayBoundariesAvailable>());
      final available = result as PrayerDayBoundariesAvailable;
      expect(available.fajrUtc, DateTime.utc(2026, 11, 9, 5, 10));
      expect(available.nextFajrUtc, DateTime.utc(2026, 11, 10, 5, 10));
      expect(calculator.calls, 2);
      expect(annual.calls, 2);
    },
  );

  test('setupRequired when there are no saved preferences', () async {
    final result = await reader.boundaries(
      'owner',
      PrayerLocalDate.parse('2026-11-09'),
    );
    expect(result, isA<PrayerDayBoundariesSetupRequired>());
    expect(annual.calls, 0);
    expect(calculator.calls, 0);
  });

  test(
    'unavailable when a needed instant is missing (high latitude)',
    () async {
      final date = PrayerLocalDate.parse('2026-12-21');
      annual.schedules[date] = scheduleWith(
        date,
        fajrUnavailableReason: 'polar night',
      );
      annual.schedules[PrayerLocalDate.parse('2026-12-22')] = scheduleWith(
        PrayerLocalDate.parse('2026-12-22'),
      );
      preferences.stored = prefs();
      final result = await reader.boundaries('owner', date);
      expect(result, isA<PrayerDayBoundariesUnavailable>());
      expect(
        (result as PrayerDayBoundariesUnavailable).reason,
        contains('polar night'),
      );
      expect(calculator.calls, 0);
    },
  );

  test('changes fires when the location or method changes, not for equal '
      'preference revisions', () async {
    final seen = <void>[];
    final sub = reader.changes('owner').listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    preferences.emit(prefs());
    await Future<void>.delayed(Duration.zero);
    // Same city and method: no event even though the revision advanced.
    preferences.emit(prefs().copyWith(revision: 2));
    await Future<void>.delayed(Duration.zero);
    expect(seen, isEmpty);
    // The method changed.
    preferences.emit(prefs(method: 'Karachi'));
    await Future<void>.delayed(Duration.zero);
    expect(seen, hasLength(1));
    // The location changed.
    preferences.emit(
      prefs(
        city: PrayerCity(
          provider: 'device',
          providerCityId: 'device-fix',
          name: 'Tromso',
          countryCode: 'NO',
          countryName: 'Norway',
          latitude: 69.65,
          longitude: 18.96,
          timeZoneId: 'Europe/Oslo',
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(seen, hasLength(2));
    await sub.cancel();
  });
}

final class FakePreferences implements PrayerPreferencesPort {
  FakePreferences({required this.owner});

  final String owner;
  PrayerPreferences? stored;
  final _controller = StreamController<PrayerPreferences?>.broadcast();

  void emit(PrayerPreferences? value) {
    stored = value;
    _controller.add(value);
  }

  @override
  Future<AppResult<PrayerPreferences?>> read(String accountId) async {
    if (accountId != owner) {
      return AppResult.success(null);
    }
    return AppResult.success(stored);
  }

  @override
  Stream<PrayerPreferences?> watch(String accountId) => _controller.stream;

  @override
  Future<AppResult<PrayerPreferences>> save(
    PrayerPreferences preferences, {
    required int? expectedRevision,
  }) => throw UnimplementedError();
}

final class FakeAnnual implements PrayerAnnualSchedulePort {
  final schedules = <PrayerLocalDate, PrayerSchedule>{};
  var calls = 0;

  @override
  Future<PrayerSchedule?> forDate({
    required PrayerPreferences preferences,
    required PrayerLocalDate date,
  }) async {
    calls++;
    return schedules[date];
  }
}

final class FakeCalculator implements PrayerScheduleCalculatorPort {
  PrayerSchedule Function(PrayerLocalDate date)? builder;
  var calls = 0;

  @override
  AppResult<PrayerSchedule> calculate({
    required PrayerPreferences preferences,
    required PrayerLocalDate date,
  }) {
    calls++;
    final built = builder?.call(date);
    if (built == null) {
      return AppResult.failure(FailureStub.recoverable);
    }
    return AppResult.success(built);
  }
}

class FailureStub {
  static final recoverable = AppFailure.recoverable(
    category: AppFailureCategory.configuration,
    messageKey: 'test.calculatorUnavailable',
    occurredAt: DateTime.utc(2026, 11, 9),
  );
}
