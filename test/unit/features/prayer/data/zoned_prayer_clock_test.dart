import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/data/zoned_prayer_clock.dart';

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
}
