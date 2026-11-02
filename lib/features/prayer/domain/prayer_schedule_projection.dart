import 'prayer_name.dart';
import 'prayer_schedule.dart';

final class PrayerOccurrence {
  const PrayerOccurrence(this.name, this.instantUtc);
  final PrayerName name;
  final DateTime instantUtc;
}

final class PrayerScheduleProjection {
  PrayerScheduleProjection({
    required this.next,
    required this.following,
    required this.remaining,
    required this.middleOfNightUtc,
    required this.lastThirdUtc,
  });

  final PrayerOccurrence? next;
  final PrayerOccurrence? following;
  final Duration? remaining;
  final DateTime? middleOfNightUtc;
  final DateTime? lastThirdUtc;

  static PrayerScheduleProjection from({
    required PrayerSchedule today,
    required PrayerSchedule tomorrow,
    required DateTime nowUtc,
  }) {
    if (!nowUtc.isUtc) throw ArgumentError.value(nowUtc, 'nowUtc');
    final occurrences = <PrayerOccurrence>[];
    for (final schedule in [today, tomorrow]) {
      for (final name in PrayerName.values) {
        final instant = schedule.times[name]?.instantUtc;
        if (instant != null) occurrences.add(PrayerOccurrence(name, instant));
      }
    }
    occurrences.sort((a, b) => a.instantUtc.compareTo(b.instantUtc));

    // Unknown earlier events mean that claiming a later event as "next" would
    // be misleading. Partial schedules still render their known individual times.
    final nextIndex = occurrences.indexWhere(
      (entry) => entry.instantUtc.isAfter(nowUtc),
    );
    PrayerOccurrence? next;
    PrayerOccurrence? following;
    if (nextIndex >= 0) {
      final candidate = occurrences[nextIndex];
      final schedule =
          today.date == tomorrow.date ||
              today.times[candidate.name]?.instantUtc == candidate.instantUtc
          ? today
          : tomorrow;
      final unknownBefore = PrayerName.values
          .take(candidate.name.index)
          .any((name) => schedule.times[name]?.instantUtc == null);
      if (!unknownBefore) {
        next = candidate;
        if (nextIndex + 1 < occurrences.length) {
          following = occurrences[nextIndex + 1];
        }
      }
    }

    final maghrib = today.times[PrayerName.maghrib]?.instantUtc;
    final fajr = tomorrow.times[PrayerName.fajr]?.instantUtc;
    DateTime? middle;
    DateTime? lastThird;
    if (maghrib != null && fajr != null && fajr.isAfter(maghrib)) {
      final micros = fajr.difference(maghrib).inMicroseconds;
      middle = maghrib.add(Duration(microseconds: micros ~/ 2));
      lastThird = maghrib.add(Duration(microseconds: micros * 2 ~/ 3));
    }
    return PrayerScheduleProjection(
      next: next,
      following: following,
      remaining: next?.instantUtc.difference(nowUtc),
      middleOfNightUtc: middle,
      lastThirdUtc: lastThird,
    );
  }
}
