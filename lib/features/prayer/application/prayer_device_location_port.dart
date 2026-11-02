import '../domain/prayer_city.dart';

/// A foreground, user-authorized fix. No background location tracking.
abstract interface class PrayerDeviceLocationPort {
  Future<PrayerDeviceLocation> locate();
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
