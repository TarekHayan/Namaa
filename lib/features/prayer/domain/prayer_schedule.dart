import 'prayer_local_date.dart';
import 'prayer_name.dart';

final class PrayerTime {
  PrayerTime({
    required this.name,
    required this.instantUtc,
    this.unavailableReason,
  }) {
    if (instantUtc != null && !instantUtc!.isUtc) {
      throw ArgumentError.value(instantUtc, 'instantUtc');
    }
    if ((instantUtc == null) == (unavailableReason == null)) {
      throw ArgumentError('A prayer time is either available or unavailable');
    }
  }

  final PrayerName name;
  final DateTime? instantUtc;
  final String? unavailableReason;

  @override
  bool operator ==(Object other) =>
      other is PrayerTime &&
      other.name == name &&
      other.instantUtc == instantUtc &&
      other.unavailableReason == unavailableReason;

  @override
  int get hashCode => Object.hash(name, instantUtc, unavailableReason);
}

final class PrayerSchedule {
  PrayerSchedule({
    required this.date,
    required this.contextRevision,
    required Map<PrayerName, PrayerTime> times,
    required this.provenance,
    this.sunriseUtc,
  }) : times = Map.unmodifiable(times) {
    if (contextRevision < 1 ||
        provenance.trim().isEmpty ||
        times.length != PrayerName.values.length ||
        !PrayerName.values.every(times.containsKey)) {
      throw ArgumentError('Invalid prayer schedule');
    }
  }

  final PrayerLocalDate date;
  final int contextRevision;
  final Map<PrayerName, PrayerTime> times;
  final String provenance;
  final DateTime? sunriseUtc;

  PrayerSchedule copyWith({
    Map<PrayerName, PrayerTime>? times,
    int? contextRevision,
    String? provenance,
    DateTime? sunriseUtc,
  }) => PrayerSchedule(
    date: date,
    contextRevision: contextRevision ?? this.contextRevision,
    times: times ?? this.times,
    provenance: provenance ?? this.provenance,
    sunriseUtc: sunriseUtc ?? this.sunriseUtc,
  );

  @override
  bool operator ==(Object other) =>
      other is PrayerSchedule &&
      other.date == date &&
      other.contextRevision == contextRevision &&
      other.provenance == provenance &&
      other.sunriseUtc == sunriseUtc &&
      PrayerName.values.every((name) => other.times[name] == times[name]);

  @override
  int get hashCode => Object.hash(
    date,
    contextRevision,
    provenance,
    sunriseUtc,
    Object.hashAll(PrayerName.values.map((name) => times[name])),
  );
}
