/// Injectable device-calendar reader used by Today projection and guards.
library;

import '../domain/today_calendar.dart';

abstract interface class TodayCalendarPort {
  /// Samples current local date, offset, UTC instant and both independent
  /// local-midnight boundaries. The caller advances [projectionRevision] when
  /// date/zone changes; each call also supplies a fresh instant for overdue.
  TodayCalendar sample({required int projectionRevision});
}
