import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/data/zoned_prayer_clock.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('city date follows New York DST and differs from device UTC date', () {
    final clock = ZonedPrayerClock(now: () => DateTime.utc(2026, 3, 8, 3));
    expect(
      clock.cityDate(clock.nowUtc(), 'America/New_York').value,
      '2026-03-07',
    );
    expect(
      clock.offsetMinutes(DateTime.utc(2026, 3, 8, 6), 'America/New_York'),
      -300,
    );
    expect(
      clock.offsetMinutes(DateTime.utc(2026, 3, 8, 8), 'America/New_York'),
      -240,
    );
    expect(
      clock.cityDate(DateTime.utc(2027), 'Asia/Dubai').value,
      '2027-01-01',
    );
  });

  test('autumn DST repeats an hour without changing the city date', () {
    final clock = ZonedPrayerClock(now: () => DateTime.utc(2026, 11, 1, 6));
    expect(
      clock.offsetMinutes(DateTime.utc(2026, 11, 1, 5, 59), 'America/New_York'),
      -240,
    );
    expect(
      clock.offsetMinutes(DateTime.utc(2026, 11, 1, 6), 'America/New_York'),
      -300,
    );
    expect(
      clock
          .cityDate(DateTime.utc(2026, 11, 1, 5, 59), 'America/New_York')
          .value,
      '2026-11-01',
    );
    expect(
      clock.cityDate(clock.nowUtc(), 'America/New_York').value,
      '2026-11-01',
    );
  });

  test(
    'city calendar crosses month and year independently of device UTC date',
    () {
      final clock = ZonedPrayerClock(now: () => DateTime.utc(2026, 12, 31, 21));
      final globalZone = tz.local;
      expect(clock.cityDate(clock.nowUtc(), 'Asia/Dubai').value, '2027-01-01');
      expect(
        clock.cityDate(DateTime.utc(2026, 3, 1, 1), 'America/New_York').value,
        '2026-02-28',
      );
      expect(clock.cityOffsetMinutes(DateTime.utc(2026, 3), 'Africa/Accra'), 0);
      expect(tz.local, same(globalZone));
    },
  );
}
