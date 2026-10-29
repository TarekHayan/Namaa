enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

extension PrayerNameWire on PrayerName {
  String get wireName => name;

  static PrayerName parse(String value) => PrayerName.values.firstWhere(
    (name) => name.wireName == value,
    orElse: () => throw ArgumentError.value(value, 'prayerName'),
  );
}
