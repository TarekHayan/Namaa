import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/prayer_adhkar_times_adapter.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/prayer/application/prayer_clock_port.dart';
import 'package:namma_project/features/prayer/application/prayer_day_boundaries.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';

/// T028: the composition adapter that maps `PrayerDayBoundaries` to the
/// Adhkar `AdhkarTimesPort`. It requests the city day whose Fajr opened the
/// running period (the previous day before Fajr), and it never falls back to
/// calendar days when the schedule is unavailable (owner decision,
/// 2026-11-10).
void main() {
  final now = DateTime.utc(2026, 11, 10, 12);
  final fajr = DateTime.utc(2026, 11, 10, 4, 30);
  final maghrib = DateTime.utc(2026, 11, 10, 16, 50);
  final nextFajr = DateTime.utc(2026, 11, 11, 4, 29);

  late FakeBoundaries boundaries;
  late FakePreferences preferences;
  late PrayerAdhkarTimesAdapter adapter;

  setUp(() {
    boundaries = FakeBoundaries();
    boundaries.results[PrayerLocalDate.parse(
      '2026-11-10',
    )] = PrayerDayBoundariesAvailable(
      date: PrayerLocalDate.parse('2026-11-10'),
      fajrUtc: fajr,
      maghribUtc: maghrib,
      nextFajrUtc: nextFajr,
      zoneId: 'UTC',
    );
    boundaries.results[PrayerLocalDate.parse(
      '2026-11-09',
    )] = PrayerDayBoundariesAvailable(
      date: PrayerLocalDate.parse('2026-11-09'),
      fajrUtc: DateTime.utc(2026, 11, 9, 4, 31),
      maghribUtc: DateTime.utc(2026, 11, 9, 16, 51),
      nextFajrUtc: fajr,
      zoneId: 'UTC',
    );
    preferences = FakePreferences();
    preferences.stored = _prefs();
    adapter = PrayerAdhkarTimesAdapter(
      boundaries: boundaries,
      preferences: preferences,
      clock: const FakeClock(),
      deviceDay: (nowUtc) =>
          '${nowUtc.year.toString().padLeft(4, '0')}-'
          '${nowUtc.month.toString().padLeft(2, '0')}-'
          '${nowUtc.day.toString().padLeft(2, '0')}',
    );
  });

  test('a mid-day instant resolves Morning on the city day', () async {
    final state = (await adapter.resolve('owner', now)).valueOrNull!;
    expect(state.scheduleState, AdhkarScheduleState.available);
    expect(state.day, '2026-11-10');
    expect(state.period, AdhkarPeriod.morning);
    expect(state.morningCountable, isTrue);
    expect(boundaries.requested.map((d) => d.value), ['2026-11-10']);
  });

  test(
    'before Fajr the previous day is requested and its Evening counts',
    () async {
      final state = (await adapter.resolve(
        'owner',
        DateTime.utc(2026, 11, 10, 1),
      )).valueOrNull!;
      expect(state.day, '2026-11-09');
      expect(state.period, AdhkarPeriod.evening);
      expect(state.eveningCountable, isTrue);
      expect(boundaries.requested.map((d) => d.value), [
        '2026-11-10',
        '2026-11-09',
      ]);
    },
  );

  test('setupRequired resolves unrestricted on the device day', () async {
    preferences.stored = null;
    boundaries.results[PrayerLocalDate.parse('2026-11-10')] =
        const PrayerDayBoundariesSetupRequired();
    final state = (await adapter.resolve('owner', now)).valueOrNull!;
    expect(state.scheduleState, AdhkarScheduleState.setupRequired);
    expect(state.day, '2026-11-10');
    expect(state.period, AdhkarPeriod.unrestricted);
    expect(state.morningCountable, isTrue);
    expect(state.eveningCountable, isTrue);
  });

  test('unavailable stays unavailable with no calendar fallback', () async {
    boundaries.results[PrayerLocalDate.parse('2026-11-10')] =
        const PrayerDayBoundariesUnavailable(reason: 'polar night');
    final state = (await adapter.resolve('owner', now)).valueOrNull!;
    expect(state.scheduleState, AdhkarScheduleState.unavailable);
    expect(state.day, isNull);
    expect(state.morningCountable, isFalse);
    expect(state.eveningCountable, isFalse);
  });

  test('a preferences read failure stays unavailable', () async {
    preferences.readOutcome = AppResult<PrayerPreferences?>.failure(
      AppFailure.recoverable(
        category: AppFailureCategory.persistence,
        messageKey: 'prayer.preferencesUnavailable',
        occurredAt: now,
      ),
    );
    final state = (await adapter.resolve('owner', now)).valueOrNull!;
    expect(state.scheduleState, AdhkarScheduleState.unavailable);
    expect(state.day, isNull);
    expect(
      boundaries.requested,
      isEmpty,
      reason: 'no day is requested when the location is unreadable',
    );
  });

  test(
    'unordered boundary instants resolve to unavailable, not a throw',
    () async {
      // Maghrib lands AFTER the next Fajr: the day boundaries are unusable.
      boundaries.results[PrayerLocalDate.parse(
        '2026-11-10',
      )] = PrayerDayBoundariesAvailable(
        date: PrayerLocalDate.parse('2026-11-10'),
        fajrUtc: DateTime.utc(2026, 11, 10, 4, 30),
        maghribUtc: DateTime.utc(2026, 11, 11, 5),
        nextFajrUtc: DateTime.utc(2026, 11, 11, 4, 29),
        zoneId: 'UTC',
      );
      final state = (await adapter.resolve('owner', now)).valueOrNull!;
      expect(state.scheduleState, AdhkarScheduleState.unavailable);
      expect(state.day, isNull);
      expect(state.morningCountable, isFalse);
    },
  );

  test('a boundaries port failure surface stays unavailable', () async {
    boundaries.failure = AppFailure.recoverable(
      category: AppFailureCategory.persistence,
      messageKey: 'test.failed',
      occurredAt: now,
    );
    final state = (await adapter.resolve('owner', now)).valueOrNull!;
    expect(state.scheduleState, AdhkarScheduleState.unavailable);
    expect(state.day, isNull);
  });
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
  DateTime nowUtc() => DateTime.utc(2026, 11, 10, 12);

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
