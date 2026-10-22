import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/today/data/system_today_calendar.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';

void main() {
  test('uses local key and half-open award boundaries', () {
    final clock = SystemTodayCalendar(
      utcNow: () => DateTime.utc(2026, 10, 12, 22),
      localCivilAtUtc: (utc) => utc.add(const Duration(hours: 2)),
      offsetMinutesAtUtc: (_) => 120,
      localMidnightToUtc: (date) => DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).subtract(const Duration(hours: 2)),
    );
    final sample = clock.sample(projectionRevision: 3);
    expect(sample.localDate.key, '2026-10-13');
    expect(sample.utcOffsetMinutes, 120);
    expect(sample.projectionRevision, 3);
    expect(sample.dayStartUtc, DateTime.utc(2026, 10, 12, 22));
    expect(sample.nextDayStartUtc, DateTime.utc(2026, 10, 13, 22));
    expect(sample.containsAwardAt(sample.dayStartUtc), isTrue);
    expect(sample.containsAwardAt(sample.nextDayStartUtc), isFalse);
    expect(
      sample.containsAwardAt(
        sample.nextDayStartUtc.subtract(const Duration(microseconds: 1)),
      ),
      isTrue,
    );
  });

  test('resamples a changed offset and local date at the same UTC instant', () {
    var offset = 120;
    final now = DateTime.utc(2026, 10, 12, 21, 30);
    final clock = SystemTodayCalendar(
      utcNow: () => now,
      localCivilAtUtc: (utc) => utc.add(Duration(minutes: offset)),
      offsetMinutesAtUtc: (_) => offset,
      localMidnightToUtc: (date) => DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(minutes: offset)),
    );
    final before = clock.sample(projectionRevision: 0);
    offset = 180;
    final after = clock.sample(projectionRevision: 1);
    expect(before.localDate, TodayLocalDate(2026, 10, 12));
    expect(after.localDate, TodayLocalDate(2026, 10, 13));
    expect(before.utcOffsetMinutes, 120);
    expect(after.utcOffsetMinutes, 180);
    expect(before.hasSameDayAndOffset(after), isFalse);
  });

  test('converts separate spring midnights for a 23-hour day', () {
    final clock = SystemTodayCalendar(
      utcNow: () => DateTime.utc(2026, 3, 29, 12),
      localCivilAtUtc: (utc) => utc.add(const Duration(hours: 3)),
      offsetMinutesAtUtc: (_) => 180,
      localMidnightToUtc: (date) => DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(hours: date.day > 29 ? 3 : 2)),
    );
    final sample = clock.sample(projectionRevision: 0);
    expect(sample.dayStartUtc, DateTime.utc(2026, 3, 28, 22));
    expect(sample.nextDayStartUtc, DateTime.utc(2026, 3, 29, 21));
    expect(sample.nextDayStartUtc.difference(sample.dayStartUtc).inHours, 23);
  });

  test('converts separate autumn midnights for a 25-hour day', () {
    final clock = SystemTodayCalendar(
      utcNow: () => DateTime.utc(2026, 10, 25, 12),
      localCivilAtUtc: (utc) => utc.add(const Duration(hours: 2)),
      offsetMinutesAtUtc: (_) => 120,
      localMidnightToUtc: (date) => DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(hours: date.day > 25 ? 2 : 3)),
    );
    final sample = clock.sample(projectionRevision: 0);
    expect(sample.dayStartUtc, DateTime.utc(2026, 10, 24, 21));
    expect(sample.nextDayStartUtc, DateTime.utc(2026, 10, 25, 22));
    expect(sample.nextDayStartUtc.difference(sample.dayStartUtc).inHours, 25);
  });
}
