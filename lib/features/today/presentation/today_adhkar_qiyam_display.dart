/// Display helpers for the live Adhkar/Qiyam values on Home and the Track
/// hub. They format only what the Adhkar and Qiyam screens already show, so
/// the numbers and the last-third time always match those screens.
library;

import 'package:intl/intl.dart' show DateFormat;
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/today_adhkar_qiyam_reference.dart';

/// "3/10".
String todayRatio(int done, int total) => '$done/$total';

/// The start of the last third as `HH:mm` in the night's zone, formatted
/// exactly as the Qiyam screen's heading chip does. Null when the schedule
/// cannot produce it.
String? todayLastThirdText(TodayAdhkarQiyamReference value, String locale) {
  final instant = value.lastThirdUtc;
  final zoneId = value.qiyamZoneId;
  if (instant == null || zoneId == null) return null;
  if (tz.timeZoneDatabase.locations.isEmpty) {
    timezone_data.initializeTimeZones();
  }
  try {
    final cityTime = tz.TZDateTime.from(instant, tz.getLocation(zoneId));
    return DateFormat.Hm(locale).format(cityTime);
  } catch (_) {
    return DateFormat.Hm(locale).format(instant.toUtc());
  }
}

/// Whether Adhkar numbers can be shown (a schedule, and no failed read).
bool todayAdhkarReadable(TodayAdhkarQiyamReference value) =>
    !value.scheduleUnavailable && !value.adhkarLoadFailed;

/// Whether tonight's Qiyam state is a real answer state (not locked, no
/// failed read).
bool todayQiyamReadable(TodayAdhkarQiyamReference value) =>
    !value.qiyamLoadFailed && value.tonight != TodayQiyamTonight.locked;
