final class PrayerLocalDate implements Comparable<PrayerLocalDate> {
  const PrayerLocalDate._(this.value);

  factory PrayerLocalDate.parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw ArgumentError.value(value, 'localDate');
    }
    final year = int.parse(value.substring(0, 4));
    final month = int.parse(value.substring(5, 7));
    final day = int.parse(value.substring(8, 10));
    if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) {
      throw ArgumentError.value(value, 'localDate');
    }
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw ArgumentError.value(value, 'localDate');
    }
    return PrayerLocalDate._(value);
  }

  final String value;

  @override
  int compareTo(PrayerLocalDate other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      other is PrayerLocalDate && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
