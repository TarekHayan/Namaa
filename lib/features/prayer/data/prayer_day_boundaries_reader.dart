import 'dart:async';

import '../application/prayer_annual_schedule_port.dart';
import '../application/prayer_day_boundaries.dart';
import '../application/prayer_preferences_port.dart';
import '../application/prayer_schedule_calculator_port.dart';
import '../domain/prayer_local_date.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_preferences.dart';
import '../domain/prayer_schedule.dart';

/// Implements [PrayerDayBoundariesPort] with 008's own schedule sources.
///
/// Data flow per lookup: one owner-scoped preferences read, then the annual
/// timetable first and the local calculator only when the cache misses a day.
/// The reader performs no provider access itself, so a lookup adds no network
/// work beyond what the annual cache adapter already does per 008.
final class PrayerDayBoundariesReader implements PrayerDayBoundariesPort {
  PrayerDayBoundariesReader({
    required PrayerPreferencesPort preferences,
    required PrayerAnnualSchedulePort annualSchedules,
    required PrayerScheduleCalculatorPort calculator,
  }) : _preferences = preferences,
       _annualSchedules = annualSchedules,
       _calculator = calculator;

  final PrayerPreferencesPort _preferences;
  final PrayerAnnualSchedulePort _annualSchedules;
  final PrayerScheduleCalculatorPort _calculator;

  @override
  Future<PrayerDayBoundariesResult> boundaries(
    String ownerId,
    PrayerLocalDate civilDate,
  ) async {
    final read = await _preferences.read(ownerId);
    // A storage failure is not the same as "no saved location": reporting it
    // as setupRequired would silently fall back to calendar days and
    // attribute counts to the wrong Adhkar day (Phase 2 review, finding 4).
    if (read.failureOrNull != null) {
      return const PrayerDayBoundariesUnavailable(
        reason: 'prayer.preferencesUnavailable',
      );
    }
    final preferences = read.valueOrNull;
    if (preferences == null || preferences.accountId != ownerId) {
      return const PrayerDayBoundariesSetupRequired();
    }

    final nextDay = _nextDate(civilDate);
    final daySchedule = await _resolve(preferences, civilDate);
    final nextSchedule = await _resolve(preferences, nextDay);
    if (daySchedule == null || nextSchedule == null) {
      return const PrayerDayBoundariesUnavailable(
        reason: 'prayer.scheduleUnavailable',
      );
    }

    final fajr = daySchedule.times[PrayerName.fajr];
    final maghrib = daySchedule.times[PrayerName.maghrib];
    final nextFajr = nextSchedule.times[PrayerName.fajr];
    final missing = <String>[
      if (fajr?.instantUtc == null)
        fajr?.unavailableReason ?? PrayerName.fajr.name,
      if (maghrib?.instantUtc == null)
        maghrib?.unavailableReason ?? PrayerName.maghrib.name,
      if (nextFajr?.instantUtc == null)
        nextFajr?.unavailableReason ??
            '${PrayerName.fajr.name}(${nextDay.value})',
    ];
    if (missing.isNotEmpty) {
      return PrayerDayBoundariesUnavailable(reason: missing.join(', '));
    }
    return PrayerDayBoundariesAvailable(
      date: civilDate,
      fajrUtc: fajr!.instantUtc!,
      maghribUtc: maghrib!.instantUtc!,
      nextFajrUtc: nextFajr!.instantUtc!,
      zoneId: preferences.city.timeZoneId,
    );
  }

  @override
  Stream<void> changes(String ownerId) {
    String? lastKey;
    var first = true;
    return _preferences
        .watch(ownerId)
        .map((preferences) {
          // A foreign-owner emission is treated like a removed location.
          final effective =
              preferences != null && preferences.accountId == ownerId
              ? preferences
              : null;
          final key = effective == null
              ? null
              : '${effective.city.provider}/${effective.city.providerCityId}/'
                    '${effective.city.latitude}/${effective.city.longitude}/'
                    '${effective.city.timeZoneId}/${effective.calculationMethod}';
          // The first observation never emits; afterwards every key transition
          // emits, including null -> value and value -> null (finding 5).
          final changed = !first && key != lastKey;
          first = false;
          lastKey = key;
          return changed;
        })
        .where((changed) => changed)
        .map((_) {});
  }

  Future<PrayerSchedule?> _resolve(
    // The annual cache is authoritative; the calculator only fills a miss.
    PrayerPreferences preferences,
    PrayerLocalDate date,
  ) async {
    try {
      final cached = await _annualSchedules.forDate(
        preferences: preferences,
        date: date,
      );
      if (cached != null) return cached;
    } catch (_) {
      // The cache adapter may fail transiently; fall through to the
      // calculator rather than reporting unavailable too early.
    }
    return _calculator
        .calculate(preferences: preferences, date: date)
        .valueOrNull;
  }

  static PrayerLocalDate _nextDate(PrayerLocalDate date) {
    final carrier = DateTime.parse('${date.value}T00:00:00Z');
    final next = carrier.add(const Duration(days: 1));
    return PrayerLocalDate.parse(
      '${next.year.toString().padLeft(4, '0')}-'
      '${next.month.toString().padLeft(2, '0')}-'
      '${next.day.toString().padLeft(2, '0')}',
    );
  }
}
