import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule_projection.dart';

PrayerSchedule schedule(String date, int day) => PrayerSchedule(
  date: PrayerLocalDate.parse(date),
  contextRevision: 1,
  provenance: 'fixture',
  times: {
    for (final name in PrayerName.values)
      name: PrayerTime(
        name: name,
        instantUtc: DateTime.utc(
          2026,
          10,
          day,
          [3, 10, 13, 16, 18][name.index],
        ),
      ),
  },
);

void main() {
  test('strict future boundary, tomorrow and positive night fractions', () {
    final today = schedule('2026-10-29', 29);
    final tomorrow = schedule('2026-10-30', 30);
    final exact = PrayerScheduleProjection.from(
      today: today,
      tomorrow: tomorrow,
      nowUtc: DateTime.utc(2026, 10, 29, 13),
    );
    expect(exact.next?.name, PrayerName.maghrib);
    expect(exact.following?.name, PrayerName.isha);
    expect(exact.remaining, const Duration(hours: 3));
    expect(exact.middleOfNightUtc, DateTime.utc(2026, 10, 29, 21, 30));
    expect(exact.lastThirdUtc, DateTime.utc(2026, 10, 29, 23, 20));
    final afterIsha = PrayerScheduleProjection.from(
      today: today,
      tomorrow: tomorrow,
      nowUtc: DateTime.utc(2026, 10, 29, 20),
    );
    expect(afterIsha.next?.name, PrayerName.fajr);
    expect(afterIsha.remaining?.isNegative, false);
  });
}
