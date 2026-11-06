import '../domain/prayer_city.dart';

/// A foreground, user-authorized fix. No background location tracking.
abstract interface class PrayerDeviceLocationPort {
  Future<PrayerDeviceLocation> locate();

  /// Opens the system page that fixes [problem]: location services when they
  /// are off, otherwise this app's permission settings.
  Future<void> openSettings(PrayerLocationProblem problem);
}

final class PrayerDeviceLocation {
  const PrayerDeviceLocation({
    required this.city,
    required this.suggestedMethod,
  });

  final PrayerCity city;
  final String suggestedMethod;
}

enum PrayerLocationProblem { serviceDisabled, permissionDenied, unavailable }

final class PrayerLocationException implements Exception {
  const PrayerLocationException(this.problem);
  final PrayerLocationProblem problem;
}
