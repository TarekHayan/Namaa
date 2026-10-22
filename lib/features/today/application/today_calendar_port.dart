/// Injectable device-calendar reader used by Today projection and guards.
library;

import 'dart:async';

import '../domain/today_calendar.dart';

/// The presentation owns and cancels the foreground check timer.
typedef TodayForegroundScheduler =
    Timer Function(Duration interval, void Function() tick);

abstract interface class TodayCalendarPort {
  /// Samples current local date, offset, UTC instant and both independent
  /// local-midnight boundaries. The caller advances [projectionRevision] when
  /// date/zone changes; each call also supplies a fresh instant for overdue.
  TodayCalendar sample({required int projectionRevision});
}
