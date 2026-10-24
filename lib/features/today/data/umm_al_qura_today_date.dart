library;

import 'package:general_datetime_core/general_datetime_core.dart';

import '../domain/today_calendar.dart';

/// A verified Umm al-Qura civil date derived from one Today local date.
final class UmmAlQuraTodayDate {
  const UmmAlQuraTodayDate({
    required this.year,
    required this.month,
    required this.day,
  });

  /// Converts [localDate] without reading a clock or using a network service.
  ///
  /// `general_datetime_core` uses a finite Umm al-Qura table. A date outside
  /// that table is deliberately unavailable rather than approximated.
  static UmmAlQuraTodayDate? fromLocalDate(TodayLocalDate localDate) {
    try {
      final fields = CalendarSystems.ummAlQura.fromGregorianDay(
        DateTime.utc(localDate.year, localDate.month, localDate.day),
      );
      return UmmAlQuraTodayDate(
        year: fields.year,
        month: fields.month,
        day: fields.day,
      );
    } on ArgumentError {
      return null;
    } on RangeError {
      return null;
    }
  }

  final int year;
  final int month;
  final int day;

  @override
  bool operator ==(Object other) =>
      other is UmmAlQuraTodayDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
