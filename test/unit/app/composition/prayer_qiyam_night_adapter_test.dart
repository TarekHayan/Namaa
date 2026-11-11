import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/prayer_qiyam_night_adapter.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/prayer_clock_port.dart';
import 'package:namma_project/features/prayer/application/prayer_day_boundaries.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule_projection.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';

/// T043: the composition adapter that maps `PrayerDayBoundaries` to the
/// Qiyam `QiyamNightPort`. Night D starts at Maghrib on D, so before the
/// city day's Maghrib the previous day's boundaries carry the running night,
/// and after it the next day's Maghrib is requested for the night's end. The
/// last third matches the shared Prayer projection (SC-005), and an
/// unusable schedule never falls back to a calendar day (owner decision,
/// 2026-11-10).
void main() {
  final fajr = {
    '2026-11-10': DateTime.utc(2026, 11, 10, 4, 31),
    '2026-11-11': DateTime.utc(2026, 11, 11, 4, 30),
    '2026-11-12': DateTime.utc(2026, 11, 12, 4, 29),
    '2026-11-13': DateTime.utc(2026, 11, 13, 4, 28),
    '2026-11-14': DateTime.utc(2026, 11, 14, 4, 27),
  };
  final maghrib = {
    '2026-11-10': DateTime.utc(2026, 11, 10, 16, 50),
    '2026-11-11': DateTime.utc(2026, 11, 11, 16, 50),
    '2026-11-12': DateTime.utc(2026, 11, 12, 16, 49),
    '2026-11-13': DateTime.utc(2026, 11, 13, 16, 49),
  };
  // The four days the scenarios request; 2026-11-14 exists only as the
  // next-Fajr source for 2026-11-13's boundaries.
  const coreDays = ['2026-11-10', '2026-11-11', '2026-11-12', '2026-11-13'];

  late FakeBoundaries boundaries;
  late FakePreferences preferences;
  late FakeClock clock;
  late PrayerQiyamNightAdapter adapter;

  setUp(() {
    boundaries = FakeBoundaries();
    for (final day in coreDays) {
      boundaries.results[PrayerLocalDate.parse(
        day,
      )] = PrayerDayBoundariesAvailable(
        date: PrayerLocalDate.parse(day),
        fajrUtc: fajr[day]!,
        maghribUtc: maghrib[day]!,
        nextFajrUtc: fajr[_nextKey(day)]!,
        zoneId: 'UTC',
      );
    }
    preferences = FakePreferences()..stored = _prefs();
    clock = FakeClock();
    adapter = PrayerQiyamNightAdapter(
      boundaries: boundaries,
      preferences: preferences,
      clock: clock,
      deviceContext: (nowUtc) => QiyamDeviceContext(
        // A fixed local wall clock (11:59 local, before the 12:00 rule) with
        // a +02:00 device zone provenance.
        deviceLocal: DateTime(2026, 11, 11, 11, 59),
        zoneId: 'UTC+02:00',
        zoneOffsetMinutes: 120,
      ),
    );
  });

  test('20:00 on the city day is that day\'s night and asks for the next '
      'Maghrib', () async {
    final now = DateTime.utc(2026, 11, 11, 20);
    final state = (await adapter.resolve(
      ownerId: 'owner',
      nowUtc: now,
    )).valueOrNull!;
    expect(state.scheduleState, QiyamScheduleState.available);
    expect(state.nightDate, '2026-11-11');
    expect(state.editable, isTrue);
    expect(state.nextBoundaryUtc, DateTime.utc(2026, 11, 12, 16, 49));
    expect(state.zoneId, 'UTC');
    expect(state.zoneOffsetMinutes, 0);
    expect(boundaries.requested.map((d) => d.value), [
      '2026-11-11',
      '2026-11-12',
    ]);
  });

  test('03:00 belongs to the previous night until Maghrib', () async {
    final now = DateTime.utc(2026, 11, 11, 3);
    final state = (await adapter.resolve(
      ownerId: 'owner',
      nowUtc: now,
    )).valueOrNull!;
    expect(state.scheduleState, QiyamScheduleState.available);
    expect(state.nightDate, '2026-11-10');
    expect(state.editable, isTrue);
    expect(state.nextBoundaryUtc, DateTime.utc(2026, 11, 11, 16, 50));
    expect(boundaries.requested.map((d) => d.value), [
      '2026-11-11',
      '2026-11-10',
    ]);
  });

  test('10:00 is still the previous night, well past its Fajr', () async {
    final state = (await adapter.resolve(
      ownerId: 'owner',
      nowUtc: DateTime.utc(2026, 11, 11, 10),
    )).valueOrNull!;
    expect(state.nightDate, '2026-11-10');
    expect(state.editable, isTrue);
  });

  test('the last third equals the shared Prayer projection (SC-005)', () async {
    final beforeMaghrib = (await adapter.resolve(
      ownerId: 'owner',
      nowUtc: DateTime.utc(2026, 11, 11, 3),
    )).valueOrNull!;
    expect(
      beforeMaghrib.lastThirdUtc,
      _projectedLastThird(
        '2026-11-10',
        maghrib['2026-11-10']!,
        fajr['2026-11-11']!,
      ),
    );

    final afterMaghrib = (await adapter.resolve(
      ownerId: 'owner',
      nowUtc: DateTime.utc(2026, 11, 11, 20),
    )).valueOrNull!;
    expect(
      afterMaghrib.lastThirdUtc,
      _projectedLastThird(
        '2026-11-11',
        maghrib['2026-11-11']!,
        fajr['2026-11-12']!,
      ),
    );
    expect(afterMaghrib.lastThirdAvailable, isTrue);
  });

  test('setupRequired keeps recording on the device 12:00 rule', () async {
    preferences.stored = null;
    final state = (await adapter.resolve(
      ownerId: 'owner',
      nowUtc: DateTime.utc(2026, 11, 11, 9, 59),
    )).valueOrNull!;
    expect(state.scheduleState, QiyamScheduleState.setupRequired);
    expect(state.nightDate, '2026-11-10');
    expect(state.editable, isTrue);
    expect(state.lastThirdUtc, isNull);
    expect(state.nextBoundaryUtc, DateTime(2026, 11, 11, 12).toUtc());
    expect(state.zoneId, 'UTC+02:00');
    expect(state.zoneOffsetMinutes, 120);
    expect(
      boundaries.requested,
      isEmpty,
      reason: 'no day is requested without a saved location',
    );
  });

  test('unavailable stays unavailable with no calendar fallback', () async {
    boundaries.results[PrayerLocalDate.parse('2026-11-11')] =
        const PrayerDayBoundariesUnavailable(reason: 'polar night');
    final state = (await adapter.resolve(
      ownerId: 'owner',
      nowUtc: DateTime.utc(2026, 11, 11, 20),
    )).valueOrNull!;
    expect(state.scheduleState, QiyamScheduleState.unavailable);
    expect(state.nightDate, isNull);
    expect(state.editable, isFalse);
  });

  test('a preferences read failure stays unavailable', () async {
    preferences.readOutcome = AppResult<PrayerPreferences?>.failure(
      AppFailure.recoverable(
        category: AppFailureCategory.persistence,
        messageKey: 'prayer.preferencesUnavailable',
        occurredAt: DateTime.utc(2026, 11, 11),
      ),
    );
    final state = (await adapter.resolve(
      ownerId: 'owner',
      nowUtc: DateTime.utc(2026, 11, 11, 20),
    )).valueOrNull!;
    expect(state.scheduleState, QiyamScheduleState.unavailable);
    expect(state.nightDate, isNull);
    expect(
      boundaries.requested,
      isEmpty,
      reason: 'no day is requested when the location is unreadable',
    );
  });

  test(
    'unordered boundary instants resolve to unavailable, not a throw',
    () async {
      boundaries.results[PrayerLocalDate.parse(
        '2026-11-11',
      )] = PrayerDayBoundariesAvailable(
        date: PrayerLocalDate.parse('2026-11-11'),
        fajrUtc: fajr['2026-11-11']!,
        maghribUtc: DateTime.utc(2026, 11, 11, 16, 50),
        nextFajrUtc: DateTime.utc(2026, 11, 11, 4, 29),
        zoneId: 'UTC',
      );
      final state = (await adapter.resolve(
        ownerId: 'owner',
        nowUtc: DateTime.utc(2026, 11, 11, 20),
      )).valueOrNull!;
      expect(state.scheduleState, QiyamScheduleState.unavailable);
      expect(state.nightDate, isNull);
    },
  );

  test('a lapsed window resolves to unavailable, not a throw', () async {
    // The previous day's Maghrib lands after the sampled instant: the
    // requested night never started.
    boundaries.results[PrayerLocalDate.parse(
      '2026-11-10',
    )] = PrayerDayBoundariesAvailable(
      date: PrayerLocalDate.parse('2026-11-10'),
      fajrUtc: fajr['2026-11-10']!,
      maghribUtc: DateTime.utc(2026, 11, 11, 17),
      nextFajrUtc: fajr['2026-11-11']!,
      zoneId: 'UTC',
    );
    final state = (await adapter.resolve(
      ownerId: 'owner',
      nowUtc: DateTime.utc(2026, 11, 11, 3),
    )).valueOrNull!;
    expect(state.scheduleState, QiyamScheduleState.unavailable);
    expect(state.nightDate, isNull);
  });

  test('an unavailable next day still resolves today\'s night with no known '
      'end', () async {
    boundaries.results[PrayerLocalDate.parse('2026-11-12')] =
        const PrayerDayBoundariesUnavailable(reason: 'polar night');
    final state = (await adapter.resolve(
      ownerId: 'owner',
      nowUtc: DateTime.utc(2026, 11, 11, 20),
    )).valueOrNull!;
    expect(state.scheduleState, QiyamScheduleState.available);
    expect(state.nightDate, '2026-11-11');
    expect(state.nextBoundaryUtc, isNull);
    expect(state.lastThirdAvailable, isTrue);
  });
}

String _nextKey(String day) {
  final carrier = DateTime.parse(
    '${day}T00:00:00Z',
  ).add(const Duration(days: 1));
  return '${carrier.year.toString().padLeft(4, '0')}-'
      '${carrier.month.toString().padLeft(2, '0')}-'
      '${carrier.day.toString().padLeft(2, '0')}';
}

/// The last third exactly as the shared Prayer projection computes it for
/// night [nightDay] (research.md R2): `from(today: D, tomorrow: D+1)`.
DateTime _projectedLastThird(
  String nightDay,
  DateTime maghribUtc,
  DateTime nextFajrUtc,
) {
  final today = PrayerLocalDate.parse(nightDay);
  final tomorrow = PrayerLocalDate.parse(_nextKey(nightDay));
  return PrayerScheduleProjection.from(
    today: _boundarySchedule(today, maghribUtc, PrayerName.maghrib),
    tomorrow: _boundarySchedule(tomorrow, nextFajrUtc, PrayerName.fajr),
    nowUtc: maghribUtc,
  ).lastThirdUtc!;
}

PrayerPreferences _prefs() => PrayerPreferences(
  accountId: 'owner',
  city: PrayerCity(
    provider: 'device',
    providerCityId: 'device-fix',
    name: 'Cairo',
    countryCode: 'EG',
    countryName: 'Egypt',
    latitude: 30.0444,
    longitude: 31.2357,
    timeZoneId: 'UTC',
  ),
  calculationMethod: 'Umm al-Qura',
  revision: 1,
  updatedAt: DateTime.utc(2026, 11, 10),
);

/// A minimal schedule carrying only the one boundary instant the Qiyam night
/// window needs; the other prayers report unavailable.
PrayerSchedule _boundarySchedule(
  PrayerLocalDate date,
  DateTime instantUtc,
  PrayerName available,
) => PrayerSchedule(
  date: date,
  contextRevision: 1,
  provenance: 'qiyam night boundaries',
  times: {
    for (final name in PrayerName.values)
      name: name == available
          ? PrayerTime(name: name, instantUtc: instantUtc)
          : PrayerTime(
              name: name,
              instantUtc: null,
              unavailableReason: 'not used for the Qiyam night window',
            ),
  },
);

final class FakePreferences implements PrayerPreferencesPort {
  PrayerPreferences? stored;
  AppResult<PrayerPreferences?>? readOutcome;

  @override
  Future<AppResult<PrayerPreferences?>> read(String accountId) async {
    final outcome = readOutcome;
    if (outcome != null) return outcome;
    return AppResult.success(stored);
  }

  @override
  Stream<PrayerPreferences?> watch(String accountId) => const Stream.empty();

  @override
  Future<AppResult<PrayerPreferences>> save(
    PrayerPreferences preferences, {
    required int? expectedRevision,
  }) => throw UnimplementedError();
}

final class FakeClock implements PrayerClockPort {
  const FakeClock();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 11, 11, 20);

  @override
  PrayerLocalDate cityDate(DateTime nowUtc, String timeZoneId) =>
      PrayerLocalDate.parse(
        '${nowUtc.year.toString().padLeft(4, '0')}-'
        '${nowUtc.month.toString().padLeft(2, '0')}-'
        '${nowUtc.day.toString().padLeft(2, '0')}',
      );

  @override
  int cityOffsetMinutes(DateTime nowUtc, String timeZoneId) => 0;
}

final class FakeBoundaries implements PrayerDayBoundariesPort {
  final results = <PrayerLocalDate, PrayerDayBoundariesResult>{};
  final requested = <PrayerLocalDate>[];
  AppFailure? failure;

  @override
  Future<PrayerDayBoundariesResult> boundaries(
    String ownerId,
    PrayerLocalDate civilDate,
  ) async {
    requested.add(civilDate);
    final error = failure;
    if (error != null) {
      return PrayerDayBoundariesUnavailable(reason: error.messageKey);
    }
    return results[civilDate]!;
  }

  @override
  Stream<void> changes(String ownerId) => const Stream.empty();
}
