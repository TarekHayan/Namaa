import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;

import '../application/prayer_device_location_port.dart';
import '../domain/prayer_city.dart';
import 'prayer_timezone_initializer.dart';

/// Resolves device coordinates and the IANA zone reported for those coordinates.
/// AlAdhan receives coordinates only after the operating-system permission grant.
final class GeolocatorPrayerLocation implements PrayerDeviceLocationPort {
  GeolocatorPrayerLocation({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 8),
            ),
          ) {
    initializePrayerTimeZones();
  }

  final Dio _dio;

  @override
  Future<PrayerDeviceLocation> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const PrayerLocationException(
          PrayerLocationProblem.serviceDisabled,
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const PrayerLocationException(
          PrayerLocationProblem.permissionDenied,
        );
      }
      final fix = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return resolveCoordinates(
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracyMeters: fix.accuracy,
      );
    } on PrayerLocationException {
      rethrow;
    } catch (_) {
      throw const PrayerLocationException(PrayerLocationProblem.unavailable);
    }
  }

  @override
  Future<void> openSettings(PrayerLocationProblem problem) async {
    try {
      if (problem == PrayerLocationProblem.serviceDisabled) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (_) {
      // Some desktop targets have no settings page; the retry stays available.
    }
  }

  /// Kept separate from the platform permission flow for deterministic tests.
  Future<PrayerDeviceLocation> resolveCoordinates({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
  }) async {
    try {
      if (!latitude.isFinite ||
          !longitude.isFinite ||
          latitude.abs() > 90 ||
          longitude.abs() > 180 ||
          !accuracyMeters.isFinite ||
          accuracyMeters > 5000) {
        throw const PrayerLocationException(PrayerLocationProblem.unavailable);
      }
      // The zone is derived from the measured coordinates, not the computer's
      // configured clock, which may belong to a different country.
      final uri = Uri.https('api.aladhan.com', '/v1/timings/${_utcDate()}', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'iso8601': 'true',
      });
      Response<dynamic>? response;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          response = await _dio.getUri<dynamic>(uri);
          break;
        } on DioException catch (error) {
          final status = error.response?.statusCode;
          final retryable =
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              status == 429 ||
              (status != null && status >= 500);
          if (!retryable || attempt == 2) rethrow;
          await Future<void>.delayed(
            Duration(milliseconds: 300 * (attempt + 1)),
          );
        }
      }
      if (response == null) {
        throw const PrayerLocationException(PrayerLocationProblem.unavailable);
      }
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      final meta = data is Map ? data['meta'] : null;
      final zoneId = meta is Map ? meta['timezone'] : null;
      if (body is! Map || body['code'] != 200 || zoneId is! String) {
        throw const PrayerLocationException(PrayerLocationProblem.unavailable);
      }
      tz.getLocation(zoneId);
      final method = meta['method'];
      final id = method is Map ? method['id'] : null;
      final suggested = switch (id) {
        5 => 'egyptian',
        4 => 'ummAlQura',
        16 => 'dubai',
        2 => 'northAmerica',
        9 => 'kuwait',
        10 => 'qatar',
        _ => 'muslimWorldLeague',
      };
      return PrayerDeviceLocation(
        city: PrayerCity(
          provider: 'device',
          providerCityId:
              '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}',
          name: 'Current location',
          countryCode: 'XX',
          countryName: 'GPS',
          latitude: latitude,
          longitude: longitude,
          timeZoneId: zoneId,
        ),
        suggestedMethod: suggested,
      );
    } on PrayerLocationException {
      rethrow;
    } catch (_) {
      throw const PrayerLocationException(PrayerLocationProblem.unavailable);
    }
  }

  static String _utcDate() {
    final now = DateTime.now().toUtc();
    return '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-${now.year}';
  }
}
