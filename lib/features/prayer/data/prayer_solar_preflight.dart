import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';
// Pinned Adhan 2.0.1 raw solar API is required to detect substituted times.
// ignore: implementation_imports
import 'package:adhan_dart/src/SolarTime.dart';

/// Inspects raw solar events before Adhan's high-latitude substitution runs.
final class PrayerSolarPreflight {
  PrayerSolarPreflight(
    DateTime date,
    Coordinates coordinates,
    CalculationParameters parameters,
  ) : _solar = SolarTime(date, coordinates),
      _parameters = parameters;

  final SolarTime _solar;
  final CalculationParameters _parameters;

  // adhan_dart 2.0.1 clamps an out-of-range acos argument to 1.0 in
  // correctedHourAngle, producing a finite substitute even in polar day.
  // Check the un-clamped altitude geometry before exposing the event.
  bool _altitudeReachable(double altitude) {
    final latitude = _solar.observer.latitude * math.pi / 180;
    final declination = _solar.solar.declination! * math.pi / 180;
    final requested = altitude * math.pi / 180;
    final denominator = math.cos(latitude) * math.cos(declination);
    if (!denominator.isFinite || denominator.abs() < 1e-12) return false;
    final cosine =
        (math.sin(requested) - math.sin(latitude) * math.sin(declination)) /
        denominator;
    return cosine.isFinite && cosine.abs() <= 1;
  }

  bool get sunriseAvailable =>
      _altitudeReachable(-50 / 60) && _solar.sunrise.isFinite;
  bool get sunsetAvailable =>
      _altitudeReachable(-50 / 60) && _solar.sunset.isFinite;
  bool get dhuhrAvailable => _solar.transit.isFinite;
  bool get asrAvailable =>
      sunriseAvailable && sunsetAvailable && _solar.afternoon(1).isFinite;
  bool get fajrAvailable =>
      sunriseAvailable &&
      _altitudeReachable(-_parameters.fajrAngle) &&
      _solar.hourAngle(-_parameters.fajrAngle, false).isFinite;
  bool get ishaAvailable =>
      sunsetAvailable &&
      ((_parameters.ishaInterval ?? 0) > 0 ||
          (_altitudeReachable(-_parameters.ishaAngle) &&
              _solar.hourAngle(-_parameters.ishaAngle, true).isFinite));
}
