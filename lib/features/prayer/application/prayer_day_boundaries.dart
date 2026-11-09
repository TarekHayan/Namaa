import '../domain/prayer_local_date.dart';

/// Read-only day-boundary instants for the 009 Adhkar and Qiyam domains
/// (specs/009-adhkar-qiyam/contracts/adhkar-qiyam-application.md).
///
/// For an owner and a civil date in the saved location's zone this port
/// returns the Fajr and Maghrib instants of that date plus the next date's
/// Fajr, so both consumers derive their windows from one authority: the same
/// encrypted annual timetable and local calculator 008 uses. The port makes
/// no provider access of its own and never substitutes a guessed time.
abstract interface class PrayerDayBoundariesPort {
  Future<PrayerDayBoundariesResult> boundaries(
    String ownerId,
    PrayerLocalDate civilDate,
  );

  /// Emits whenever the saved location or calculation method changes.
  Stream<void> changes(String ownerId);
}

/// The outcome of a boundaries lookup.
sealed class PrayerDayBoundariesResult {
  const PrayerDayBoundariesResult();
}

/// The three instants for [date], taken from the schedule source that served
/// the day.
final class PrayerDayBoundariesAvailable extends PrayerDayBoundariesResult {
  const PrayerDayBoundariesAvailable({
    required this.date,
    required this.fajrUtc,
    required this.maghribUtc,
    required this.nextFajrUtc,
    required this.zoneId,
  });

  final PrayerLocalDate date;
  final DateTime fajrUtc;
  final DateTime maghribUtc;
  final DateTime nextFajrUtc;
  final String zoneId;
}

/// No saved Prayer location/method for the owner.
final class PrayerDayBoundariesSetupRequired extends PrayerDayBoundariesResult {
  const PrayerDayBoundariesSetupRequired();
}

/// One of the three instants could not be computed (for example at high
/// latitude); no guessed time is substituted.
final class PrayerDayBoundariesUnavailable extends PrayerDayBoundariesResult {
  const PrayerDayBoundariesUnavailable({required this.reason});

  final String reason;
}
