enum PrayerStatus { pending, completedOnTime, completedLate, missed }

extension PrayerStatusWire on PrayerStatus {
  bool get isCompleted =>
      this == PrayerStatus.completedOnTime ||
      this == PrayerStatus.completedLate;

  String get wireName => switch (this) {
    PrayerStatus.pending => 'pending',
    PrayerStatus.completedOnTime => 'completed_on_time',
    PrayerStatus.completedLate => 'completed_late',
    PrayerStatus.missed => 'missed',
  };

  static PrayerStatus parse(String value) => PrayerStatus.values.firstWhere(
    (status) => status.wireName == value,
    orElse: () => throw ArgumentError.value(value, 'status'),
  );
}
