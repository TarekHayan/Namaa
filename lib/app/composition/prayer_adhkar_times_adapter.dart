import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_times_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/prayer/application/prayer_clock_port.dart';
import 'package:namma_project/features/prayer/application/prayer_day_boundaries.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';

/// Maps the read-only `PrayerDayBoundaries` port to the Adhkar
/// `AdhkarTimesPort` (T028, contracts/adhkar-qiyam-application.md).
///
/// Day selection: the Adhkar day is the civil date of the Fajr that opened
/// the running period, so the adapter resolves the city's current day from
/// the saved location's zone and steps back one day when `now` is still
/// before that day's Fajr. An unavailable schedule — including a preferences
/// read failure — resolves to the unavailable state: the lists stay visible
/// but counting is locked, with no calendar-day fallback (owner decision,
/// 2026-11-10). Only `SetupRequired` (no saved location) is unrestricted, on
/// the device's calendar day.
final class PrayerAdhkarTimesAdapter implements AdhkarTimesPort {
  PrayerAdhkarTimesAdapter({
    required PrayerDayBoundariesPort boundaries,
    required PrayerPreferencesPort preferences,
    required PrayerClockPort clock,
    String Function(DateTime nowUtc)? deviceDay,
  }) : _boundaries = boundaries,
       _preferences = preferences,
       _clock = clock,
       _deviceDay = deviceDay ?? ((nowUtc) => _key(nowUtc.toLocal()));

  final PrayerDayBoundariesPort _boundaries;
  final PrayerPreferencesPort _preferences;
  final PrayerClockPort _clock;
  final String Function(DateTime nowUtc) _deviceDay;

  @override
  Future<AppResult<AdhkarClockState>> resolve(
    String ownerId,
    DateTime nowUtc,
  ) async {
    final read = await _preferences.read(ownerId);
    // A storage failure is not "no saved location": it locks counting
    // instead of attributing counts to a guessed day (Phase 2 review
    // finding 4).
    if (read.failureOrNull != null) {
      return AppResult.success(
        AdhkarClock.resolve(
          nowUtc: nowUtc,
          input: const AdhkarScheduleUnavailable(),
        ),
      );
    }
    final preferences = read.valueOrNull;
    if (preferences == null || preferences.accountId != ownerId) {
      return AppResult.success(
        AdhkarClock.resolve(
          nowUtc: nowUtc,
          input: AdhkarNoSchedule(deviceDay: _deviceDay(nowUtc)),
        ),
      );
    }
    final today = _clock.cityDate(nowUtc, preferences.city.timeZoneId);
    final todayBoundaries = await _boundaries.boundaries(ownerId, today);
    if (todayBoundaries is PrayerDayBoundariesSetupRequired) {
      return AppResult.success(
        AdhkarClock.resolve(
          nowUtc: nowUtc,
          input: AdhkarNoSchedule(deviceDay: _deviceDay(nowUtc)),
        ),
      );
    }
    if (todayBoundaries is PrayerDayBoundariesUnavailable) {
      return AppResult.success(
        AdhkarClock.resolve(
          nowUtc: nowUtc,
          input: const AdhkarScheduleUnavailable(),
        ),
      );
    }
    final available = todayBoundaries as PrayerDayBoundariesAvailable;
    if (!nowUtc.isBefore(available.fajrUtc)) {
      return AppResult.success(_scheduled(nowUtc, available));
    }
    // Before the city day's Fajr: the running period belongs to the previous
    // Adhkar day, whose boundaries end at this day's Fajr.
    final previousBoundaries = await _boundaries.boundaries(
      ownerId,
      _previousDay(today),
    );
    if (previousBoundaries is! PrayerDayBoundariesAvailable) {
      return AppResult.success(
        AdhkarClock.resolve(
          nowUtc: nowUtc,
          input: const AdhkarScheduleUnavailable(),
        ),
      );
    }
    return AppResult.success(_scheduled(nowUtc, previousBoundaries));
  }

  AdhkarClockState _scheduled(
    DateTime nowUtc,
    PrayerDayBoundariesAvailable available,
  ) => AdhkarClock.resolve(
    nowUtc: nowUtc,
    input: AdhkarScheduledDay(
      boundaries: AdhkarDayBoundaries(
        fajrUtc: available.fajrUtc,
        maghribUtc: available.maghribUtc,
        nextFajrUtc: available.nextFajrUtc,
        fajrDay: available.date.value,
        zoneId: available.zoneId,
      ),
    ),
  );

  static PrayerLocalDate _previousDay(PrayerLocalDate day) {
    final carrier = DateTime.parse('${day.value}T00:00:00Z');
    final previous = carrier.subtract(const Duration(days: 1));
    return PrayerLocalDate.parse(
      '${previous.year.toString().padLeft(4, '0')}-'
      '${previous.month.toString().padLeft(2, '0')}-'
      '${previous.day.toString().padLeft(2, '0')}',
    );
  }

  static String _key(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
