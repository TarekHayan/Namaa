import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/prayer_clock_port.dart';
import 'package:namma_project/features/prayer/application/prayer_day_boundaries.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule_projection.dart';
import 'package:namma_project/features/qiyam/application/qiyam_night_port.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';

/// The device zone context captured for a no-schedule night record: the
/// device's local wall clock and its zone provenance.
final class QiyamDeviceContext {
  const QiyamDeviceContext({
    required this.deviceLocal,
    required this.zoneId,
    required this.zoneOffsetMinutes,
  });

  /// The device's local wall clock (`isUtc == false`) at the sampled instant.
  final DateTime deviceLocal;
  final String zoneId;
  final int zoneOffsetMinutes;
}

/// Maps the read-only `PrayerDayBoundaries` port to the Qiyam
/// `QiyamNightPort` (T043, contracts/adhkar-qiyam-application.md).
///
/// Night selection: night D starts at Maghrib on D, so the adapter resolves
/// the city's current day C from the saved location's zone. Before
/// Maghrib(C) the night in progress is C-1's (its window runs to
/// Maghrib(C)); from Maghrib(C) on it is C's night, and Maghrib(C+1) is
/// requested for the night's end and the next refresh — when the next day's
/// schedule is unavailable the upper bound is simply unknown. The last third
/// comes from the shared `PrayerScheduleProjection` the Prayer screen uses
/// (SC-005). An unusable schedule — including a preferences read failure or
/// unordered instants — resolves to the unavailable state: the screen stays
/// visible but recording is locked, with no calendar or noon fallback (owner
/// decision, 2026-11-10). Only `SetupRequired` (no saved location) keeps
/// recording on the device's 12:00 rule. The night's Isha (from the same
/// boundaries) gives the start and end times their Isha-to-Fajr window; a
/// missing or out-of-order Isha leaves the times without a window.
final class PrayerQiyamNightAdapter implements QiyamNightPort {
  PrayerQiyamNightAdapter({
    required PrayerDayBoundariesPort boundaries,
    required PrayerPreferencesPort preferences,
    required PrayerClockPort clock,
    QiyamDeviceContext Function(DateTime nowUtc)? deviceContext,
  }) : _boundaries = boundaries,
       _preferences = preferences,
       _clock = clock,
       _deviceContext = deviceContext ?? _defaultDeviceContext;

  final PrayerDayBoundariesPort _boundaries;
  final PrayerPreferencesPort _preferences;
  final PrayerClockPort _clock;
  final QiyamDeviceContext Function(DateTime nowUtc) _deviceContext;

  @override
  Future<AppResult<QiyamNightState>> resolve({
    required String ownerId,
    required DateTime nowUtc,
  }) async {
    final read = await _preferences.read(ownerId);
    // A storage failure is not "no saved location": it locks recording
    // instead of attributing the night to a guessed day (owner decision,
    // 2026-11-10).
    if (read.failureOrNull != null) {
      return AppResult.success(_unavailable(nowUtc));
    }
    final preferences = read.valueOrNull;
    if (preferences == null || preferences.accountId != ownerId) {
      return AppResult.success(_noSchedule(nowUtc));
    }
    final zone = preferences.city.timeZoneId;
    final cityDay = _clock.cityDate(nowUtc, zone);
    final todayBoundaries = await _boundaries.boundaries(ownerId, cityDay);
    if (todayBoundaries is PrayerDayBoundariesSetupRequired) {
      return AppResult.success(_noSchedule(nowUtc));
    }
    if (todayBoundaries is! PrayerDayBoundariesAvailable) {
      return AppResult.success(_unavailable(nowUtc));
    }
    final available = todayBoundaries;
    final zoneOffsetMinutes = _clock.cityOffsetMinutes(nowUtc, zone);
    if (nowUtc.isBefore(available.maghribUtc)) {
      // Before Maghrib(C) the running night opened at Maghrib(C-1), whose
      // window ends at this day's Maghrib.
      final previous = await _boundaries.boundaries(
        ownerId,
        _previousDay(cityDay),
      );
      if (previous is! PrayerDayBoundariesAvailable) {
        return AppResult.success(_unavailable(nowUtc));
      }
      return AppResult.success(
        _scheduledOrUnavailable(
          nowUtc,
          nightDay: previous.date.value,
          maghribUtc: previous.maghribUtc,
          ishaUtc: previous.ishaUtc,
          nextFajrUtc: previous.nextFajrUtc,
          zoneId: previous.zoneId,
          zoneOffsetMinutes: zoneOffsetMinutes,
          nextMaghribUtc: available.maghribUtc,
        ),
      );
    }
    // Night C is in progress; Maghrib(C+1) ends it. When the next day's
    // schedule cannot produce it the night simply has no known end yet.
    final next = await _boundaries.boundaries(ownerId, _nextDay(cityDay));
    final nextMaghribUtc = next is PrayerDayBoundariesAvailable
        ? next.maghribUtc
        : null;
    return AppResult.success(
      _scheduledOrUnavailable(
        nowUtc,
        nightDay: available.date.value,
        maghribUtc: available.maghribUtc,
        ishaUtc: available.ishaUtc,
        nextFajrUtc: available.nextFajrUtc,
        zoneId: available.zoneId,
        zoneOffsetMinutes: zoneOffsetMinutes,
        nextMaghribUtc: nextMaghribUtc,
      ),
    );
  }

  /// Resolves the scheduled night, or reports unavailable when the instants
  /// are unusable (unordered, lapsed, or a last third the projection cannot
  /// compute) — a composition/data fault locks recording instead of escaping
  /// as an exception.
  QiyamNightState _scheduledOrUnavailable(
    DateTime nowUtc, {
    required String nightDay,
    required DateTime maghribUtc,
    required DateTime? ishaUtc,
    required DateTime nextFajrUtc,
    required String zoneId,
    required int zoneOffsetMinutes,
    required DateTime? nextMaghribUtc,
  }) {
    try {
      final nightDate = PrayerLocalDate.parse(nightDay);
      final lastThird = PrayerScheduleProjection.from(
        today: _boundarySchedule(nightDate, maghribUtc, PrayerName.maghrib),
        tomorrow: _boundarySchedule(
          _dayAfter(nightDate),
          nextFajrUtc,
          PrayerName.fajr,
        ),
        nowUtc: nowUtc,
      ).lastThirdUtc;
      if (lastThird == null) {
        return _unavailable(nowUtc);
      }
      return QiyamNight.resolve(
        nowUtc: nowUtc,
        input: QiyamScheduledNight(
          boundaries: QiyamNightBoundaries(
            maghribUtc: maghribUtc,
            nextFajrUtc: nextFajrUtc,
            lastThirdUtc: lastThird,
            nightDay: nightDay,
            zoneId: zoneId,
            // An Isha outside Maghrib..Fajr is a schedule quirk: the times
            // simply get no window, recording is not locked for it.
            ishaUtc:
                ishaUtc != null &&
                    ishaUtc.isAfter(maghribUtc) &&
                    ishaUtc.isBefore(nextFajrUtc)
                ? ishaUtc
                : null,
          ),
          zoneOffsetMinutes: zoneOffsetMinutes,
          nextMaghribUtc: nextMaghribUtc,
        ),
      );
    } on ArgumentError {
      return _unavailable(nowUtc);
    }
  }

  QiyamNightState _noSchedule(DateTime nowUtc) {
    try {
      final context = _deviceContext(nowUtc);
      return QiyamNight.resolve(
        nowUtc: nowUtc,
        input: QiyamNoSchedule(
          deviceLocal: context.deviceLocal,
          zoneId: context.zoneId,
          zoneOffsetMinutes: context.zoneOffsetMinutes,
        ),
      );
    } on ArgumentError {
      return _unavailable(nowUtc);
    }
  }

  QiyamNightState _unavailable(DateTime nowUtc) => QiyamNight.resolve(
    nowUtc: nowUtc,
    input: const QiyamScheduleUnavailable(),
  );

  static QiyamDeviceContext _defaultDeviceContext(DateTime nowUtc) {
    final deviceLocal = nowUtc.toLocal();
    final offsetMinutes = deviceLocal.timeZoneOffset.inMinutes;
    return QiyamDeviceContext(
      deviceLocal: deviceLocal,
      zoneId: _zoneKey(offsetMinutes),
      zoneOffsetMinutes: offsetMinutes,
    );
  }

  /// The device zone provenance for a no-schedule record: `UTC` or
  /// `UTC±HH:MM` from the wall-clock offset (no IANA lookup is available).
  static String _zoneKey(int offsetMinutes) {
    if (offsetMinutes == 0) return 'UTC';
    final sign = offsetMinutes.isNegative ? '-' : '+';
    final absolute = offsetMinutes.abs();
    final hours = (absolute ~/ 60).toString().padLeft(2, '0');
    final minutes = (absolute % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$minutes';
  }

  static PrayerLocalDate _previousDay(PrayerLocalDate day) =>
      _shiftDay(day, -1);

  static PrayerLocalDate _nextDay(PrayerLocalDate day) => _shiftDay(day, 1);

  static PrayerLocalDate _dayAfter(PrayerLocalDate day) => _shiftDay(day, 1);

  static PrayerLocalDate _shiftDay(PrayerLocalDate day, int days) {
    final carrier = DateTime.parse(
      '${day.value}T00:00:00Z',
    ).add(Duration(days: days));
    return PrayerLocalDate.parse(
      '${carrier.year.toString().padLeft(4, '0')}-'
      '${carrier.month.toString().padLeft(2, '0')}-'
      '${carrier.day.toString().padLeft(2, '0')}',
    );
  }

  /// A minimal schedule carrying only the one boundary instant the Qiyam
  /// night window needs; the other prayers report unavailable.
  static PrayerSchedule _boundarySchedule(
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
}
