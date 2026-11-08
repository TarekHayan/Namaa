import 'package:timezone/timezone.dart' as tz;

import '../application/prayer_clock_port.dart';
import '../domain/prayer_local_date.dart';
import 'prayer_timezone_initializer.dart';

final class ZonedPrayerClock implements PrayerClockPort {
  ZonedPrayerClock({DateTime Function()? now}) : _now = now ?? DateTime.now {
    initializePrayerTimeZones();
  }

  final DateTime Function() _now;

  @override
  DateTime nowUtc() => _now().toUtc();

  @override
  PrayerLocalDate cityDate(DateTime nowUtc, String timeZoneId) {
    final local = tz.TZDateTime.from(
      nowUtc.toUtc(),
      tz.getLocation(timeZoneId),
    );
    return PrayerLocalDate.parse(
      '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}',
    );
  }

  @override
  int cityOffsetMinutes(DateTime nowUtc, String timeZoneId) =>
      tz.TZDateTime.from(
        nowUtc.toUtc(),
        tz.getLocation(timeZoneId),
      ).timeZoneOffset.inMinutes;

  /// Compatibility for schedule callers while command code uses the port
  /// name that makes the selected-city context explicit.
  int offsetMinutes(DateTime nowUtc, String timeZoneId) =>
      cityOffsetMinutes(nowUtc, timeZoneId);
}
