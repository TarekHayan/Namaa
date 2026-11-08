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

  test('every prayer boundary advances to the following occurrence', () {
    final today = schedule('2026-10-29', 29);
    final tomorrow = schedule('2026-10-30', 30);
    final hours = [3, 10, 13, 16, 18];
    for (var index = 0; index < hours.length; index++) {
      final boundary = DateTime.utc(2026, 10, 29, hours[index]);
      final before = PrayerScheduleProjection.from(
        today: today,
        tomorrow: tomorrow,
        nowUtc: boundary.subtract(const Duration(seconds: 1)),
      );
      expect(before.next?.name, PrayerName.values[index]);
      expect(before.remaining, const Duration(seconds: 1));
      final exact = PrayerScheduleProjection.from(
        today: today,
        tomorrow: tomorrow,
        nowUtc: boundary,
      );
      expect(exact.next?.name, PrayerName.values[(index + 1) % hours.length]);
      expect(exact.remaining?.isNegative, false);
      expect(exact.following, isNotNull);
      final after = PrayerScheduleProjection.from(
        today: today,
        tomorrow: tomorrow,
        nowUtc: boundary.add(const Duration(seconds: 1)),
      );
      expect(after.next?.name, PrayerName.values[(index + 1) % hours.length]);
      expect(after.remaining?.isNegative, false);
    }
  });

  test('an unknown earlier prayer prevents a false next-prayer claim', () {
    final base = schedule('2026-10-29', 29);
    final times = Map<PrayerName, PrayerTime>.of(base.times);
    times[PrayerName.fajr] = PrayerTime(
      name: PrayerName.fajr,
      instantUtc: null,
      unavailableReason: 'solar_event_unavailable',
    );
    final partial = PrayerSchedule(
      date: base.date,
      contextRevision: base.contextRevision,
      provenance: base.provenance,
      times: times,
    );
    final projection = PrayerScheduleProjection.from(
      today: partial,
      tomorrow: schedule('2026-10-30', 30),
      nowUtc: DateTime.utc(2026, 10, 29, 2),
    );
    expect(projection.next, isNull);
    expect(projection.following, isNull);
    expect(projection.remaining, isNull);
  });

  test('an unavailable Isha cannot be skipped for tomorrow Fajr', () {
    final base = schedule('2026-10-29', 29);
    final times = Map<PrayerName, PrayerTime>.of(base.times);
    times[PrayerName.isha] = PrayerTime(
      name: PrayerName.isha,
      instantUtc: null,
      unavailableReason: 'solar_event_unavailable',
    );
    final partial = PrayerSchedule(
      date: base.date,
      contextRevision: base.contextRevision,
      provenance: base.provenance,
      times: times,
    );
    final projection = PrayerScheduleProjection.from(
      today: partial,
      tomorrow: schedule('2026-10-30', 30),
      nowUtc: DateTime.utc(2026, 10, 29, 17),
    );
    expect(projection.next, isNull);
    expect(projection.remaining, isNull);
  });
}
