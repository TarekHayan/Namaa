/// Device-local calendar values. Locale affects formatting, not membership.
library;

final class TodayLocalDate implements Comparable<TodayLocalDate> {
  TodayLocalDate(this.year, this.month, this.day) {
    final parsed = DateTime.utc(year, month, day);
    if (year < 1 ||
        year > 9999 ||
        parsed.year != year ||
        parsed.month != month ||
        parsed.day != day) {
      throw ArgumentError('Invalid Today local calendar date');
    }
  }

  factory TodayLocalDate.fromCivil(DateTime date) =>
      TodayLocalDate(date.year, date.month, date.day);

  factory TodayLocalDate.parse(String key) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
    if (match == null) throw FormatException('Invalid local date key', key);
    final date = TodayLocalDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
    if (date.key != key) throw FormatException('Invalid local date key', key);
    return date;
  }

  final int year;
  final int month;
  final int day;

  String get key =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  TodayLocalDate get next {
    final nextCivil = DateTime.utc(year, month, day + 1);
    return TodayLocalDate.fromCivil(nextCivil);
  }

  int get weekday => DateTime.utc(year, month, day).weekday;

  @override
  int compareTo(TodayLocalDate other) => key.compareTo(other.key);

  @override
  bool operator ==(Object other) =>
      other is TodayLocalDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => key;
}

final class TodayCalendar {
  TodayCalendar({
    required this.localDate,
    required this.nowUtc,
    required this.utcOffsetMinutes,
    required this.dayStartUtc,
    required this.nextDayStartUtc,
    required this.projectionRevision,
  }) {
    if (!nowUtc.isUtc || !dayStartUtc.isUtc || !nextDayStartUtc.isUtc) {
      throw ArgumentError('Today calendar instants must be UTC');
    }
    if (projectionRevision < 0 ||
        utcOffsetMinutes < -14 * 60 ||
        utcOffsetMinutes > 14 * 60 ||
        !dayStartUtc.isBefore(nextDayStartUtc) ||
        nowUtc.isBefore(dayStartUtc) ||
        !nowUtc.isBefore(nextDayStartUtc)) {
      throw ArgumentError('Invalid Today calendar sample');
    }
  }

  final TodayLocalDate localDate;
  final DateTime nowUtc;
  final int utcOffsetMinutes;
  final DateTime dayStartUtc;
  final DateTime nextDayStartUtc;
  final int projectionRevision;

  bool containsAwardAt(DateTime awardedAtUtc) {
    if (!awardedAtUtc.isUtc) {
      throw ArgumentError.value(awardedAtUtc, 'awardedAtUtc', 'must be UTC');
    }
    return !awardedAtUtc.isBefore(dayStartUtc) &&
        awardedAtUtc.isBefore(nextDayStartUtc);
  }

  bool hasSameDayAndOffset(TodayCalendar other) =>
      localDate == other.localDate &&
      utcOffsetMinutes == other.utcOffsetMinutes;
}
