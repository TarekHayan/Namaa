import 'package:dio/dio.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:timezone/timezone.dart' as tz;

import '../application/city_search_port.dart';
import '../domain/prayer_city.dart';
import 'prayer_search_configuration.dart';
import 'prayer_timezone_initializer.dart';

final class DioCitySearch implements CitySearchPort {
  DioCitySearch({required PrayerSearchConfiguration configuration, Dio? dio})
    : _configuration = configuration,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 8),
            ),
          ) {
    initializePrayerTimeZones();
  }

  final PrayerSearchConfiguration _configuration;
  final Dio _dio;
  final Map<String, CancelToken> _requests = {};

  String _key(String ownerId, int generation) => '$ownerId/$generation';

  @override
  void cancel({required String ownerId, required int generation}) =>
      _requests.remove(_key(ownerId, generation))?.cancel();

  @override
  Future<AppResult<List<PrayerCity>>> search({
    required String query,
    required String locale,
    required String ownerId,
    required int generation,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2 || trimmed.length > 100) {
      return _failure(
        AppFailureCategory.validation,
        'prayerSearchInvalidQuery',
      );
    }
    final key = _key(ownerId, generation);
    cancel(ownerId: ownerId, generation: generation);
    final token = CancelToken();
    _requests[key] = token;
    try {
      final evaluation = _configuration.mode == PrayerSearchMode.evaluation;
      final response = await _dio.getUri<dynamic>(
        _configuration.endpoint.replace(
          queryParameters: evaluation
              ? {
                  'name': trimmed,
                  'count': '10',
                  'language': locale == 'ar' ? 'ar' : 'en',
                  'format': 'json',
                }
              : {'query': trimmed, 'language': locale == 'ar' ? 'ar' : 'en'},
        ),
        cancelToken: token,
      );
      if (token.isCancelled) {
        return _failure(AppFailureCategory.network, 'prayerSearchCancelled');
      }
      final body = response.data;
      if (body is! Map<Object?, Object?>) {
        return _failure(
          AppFailureCategory.network,
          'prayerSearchInvalidResponse',
        );
      }
      final raw = body['results'];
      if (raw == null) return const AppResult.success([]);
      if (raw is! List) {
        return _failure(
          AppFailureCategory.network,
          'prayerSearchInvalidResponse',
        );
      }
      final cities = <PrayerCity>[];
      for (final item in raw.take(10)) {
        if (item is! Map<Object?, Object?>) continue;
        try {
          final city = _city(item, evaluation: evaluation);
          tz.getLocation(city.timeZoneId);
          cities.add(city);
        } catch (_) {
          // A malformed candidate is never selectable; retain valid siblings.
        }
      }
      return AppResult.success(cities);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        return _failure(AppFailureCategory.network, 'prayerSearchCancelled');
      }
      if (error.response?.statusCode == 429) {
        return _failure(AppFailureCategory.network, 'prayerSearchThrottled');
      }
      return _failure(AppFailureCategory.network, 'prayerSearchOffline');
    } catch (_) {
      return _failure(
        AppFailureCategory.network,
        'prayerSearchInvalidResponse',
      );
    } finally {
      if (identical(_requests[key], token)) _requests.remove(key);
    }
  }

  PrayerCity _city(Map<Object?, Object?> row, {required bool evaluation}) {
    String field(String a, [String? b]) =>
        (row[a] ?? (b == null ? null : row[b]))?.toString() ?? '';
    final latitude = row['latitude'];
    final longitude = row['longitude'];
    return PrayerCity(
      provider: evaluation ? 'open-meteo/geonames' : field('provider'),
      providerCityId: field(evaluation ? 'id' : 'providerCityId'),
      name: field(evaluation ? 'name' : 'cityName', 'name'),
      countryCode: field(evaluation ? 'country_code' : 'countryCode'),
      countryName: field(evaluation ? 'country' : 'countryName'),
      adminName: field(evaluation ? 'admin1' : 'adminName').isEmpty
          ? null
          : field(evaluation ? 'admin1' : 'adminName'),
      latitude: latitude is num ? latitude.toDouble() : double.nan,
      longitude: longitude is num ? longitude.toDouble() : double.nan,
      timeZoneId: field(evaluation ? 'timezone' : 'timeZoneId'),
    );
  }

  AppResult<List<PrayerCity>> _failure(
    AppFailureCategory category,
    String key,
  ) => AppResult.failure(
    AppFailure.recoverable(
      category: category,
      messageKey: key,
      occurredAt: DateTime.now().toUtc(),
    ),
  );
}
