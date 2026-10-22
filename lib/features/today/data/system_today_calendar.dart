/// Device-calendar adapter. Platform lifecycle scheduling remains in the app.
library;

import '../application/today_calendar_port.dart';
import '../domain/today_calendar.dart';

final class SystemTodayCalendar implements TodayCalendarPort {
  SystemTodayCalendar({
    DateTime Function()? utcNow,
    DateTime Function(DateTime utc)? localCivilAtUtc,
    int Function(DateTime utc)? offsetMinutesAtUtc,
    DateTime Function(TodayLocalDate date)? localMidnightToUtc,
  }) : _utcNow = utcNow ?? _systemUtcNow,
       _localCivilAtUtc = localCivilAtUtc ?? _systemLocalCivilAtUtc,
       _offsetMinutesAtUtc = offsetMinutesAtUtc ?? _systemOffsetMinutesAtUtc,
       _localMidnightToUtc = localMidnightToUtc ?? _systemLocalMidnightToUtc;

  final DateTime Function() _utcNow;
  final DateTime Function(DateTime utc) _localCivilAtUtc;
  final int Function(DateTime utc) _offsetMinutesAtUtc;
  final DateTime Function(TodayLocalDate date) _localMidnightToUtc;

  static DateTime _systemUtcNow() => DateTime.now().toUtc();
  static DateTime _systemLocalCivilAtUtc(DateTime utc) => utc.toLocal();
  static int _systemOffsetMinutesAtUtc(DateTime utc) =>
      utc.toLocal().timeZoneOffset.inMinutes;
  static DateTime _systemLocalMidnightToUtc(TodayLocalDate date) =>
      DateTime(date.year, date.month, date.day).toUtc();

  @override
  TodayCalendar sample({required int projectionRevision}) {
    final nowUtc = _utcNow();
    if (!nowUtc.isUtc) {
      throw ArgumentError.value(nowUtc, 'utcNow', 'must return UTC');
    }
    final localDate = TodayLocalDate.fromCivil(_localCivilAtUtc(nowUtc));
    return TodayCalendar(
      localDate: localDate,
      nowUtc: nowUtc,
      utcOffsetMinutes: _offsetMinutesAtUtc(nowUtc),
      dayStartUtc: _localMidnightToUtc(localDate),
      nextDayStartUtc: _localMidnightToUtc(localDate.next),
      projectionRevision: projectionRevision,
    );
  }
}
