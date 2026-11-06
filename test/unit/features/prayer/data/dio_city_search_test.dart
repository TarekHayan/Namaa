import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/data/dio_city_search.dart';
import 'package:namma_project/features/prayer/data/prayer_search_configuration.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';

void main() {
  test(
    'lookup fetches the same city by id in the requested language',
    () async {
      late Uri requested;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requested = options.uri;
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'id': 5128581,
                    'name': 'New York',
                    'country_code': 'US',
                    'country': 'United States',
                    'admin1': 'New York',
                    'latitude': 40.71427,
                    'longitude': -74.00597,
                    'timezone': 'America/New_York',
                  },
                ),
              );
            },
          ),
        );
      final adapter = DioCitySearch(
        configuration: PrayerSearchConfiguration.resolve().valueOrNull!,
        dio: dio,
      );
      final found = await adapter.lookup(
        city: PrayerCity(
          provider: 'open-meteo/geonames',
          providerCityId: '5128581',
          name: 'نيويورك',
          countryCode: 'US',
          countryName: 'US',
          latitude: 40.71427,
          longitude: -74.00597,
          timeZoneId: 'America/New_York',
        ),
        locale: 'en',
      );
      expect(requested.path, '/v1/get');
      expect(requested.queryParameters, {'id': '5128581', 'language': 'en'});
      expect(found.valueOrNull?.name, 'New York');
      expect(found.valueOrNull?.countryName, 'United States');
    },
  );

  test(
    'captured Open-Meteo fixture preserves distinct Cairo candidates',
    () async {
      final fixture =
          jsonDecode(
                File(
                  'test/fixtures/prayer/cities/open_meteo_cairo.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.resolve(
              Response(requestOptions: options, data: fixture['response']),
            ),
          ),
        );
      final adapter = DioCitySearch(
        configuration: PrayerSearchConfiguration.resolve().valueOrNull!,
        dio: dio,
      );
      final result = await adapter.search(
        query: 'Cairo',
        locale: 'en',
        ownerId: 'owner',
        generation: 1,
      );
      expect(result.valueOrNull, hasLength(3));
      expect(result.valueOrNull!.first.timeZoneId, 'Africa/Cairo');
      expect(result.valueOrNull![1].timeZoneId, 'America/Chicago');
      expect(result.valueOrNull!.first.providerCityId, '360630');
    },
  );

  test(
    'normalizes provider results, keeps zero coordinates and skips bad zone',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.uri.queryParameters['count'], '10');
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'results': [
                    {
                      'id': 1,
                      'name': 'Zero',
                      'country_code': 'GB',
                      'country': 'United Kingdom',
                      'latitude': 0,
                      'longitude': 0,
                      'timezone': 'Europe/London',
                    },
                    {
                      'id': 2,
                      'name': 'Broken',
                      'country_code': 'GB',
                      'country': 'United Kingdom',
                      'latitude': 51,
                      'longitude': 0,
                      'timezone': 'Missing/Zone',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
      final adapter = DioCitySearch(
        configuration: PrayerSearchConfiguration.resolve().valueOrNull!,
        dio: dio,
      );
      final result = await adapter.search(
        query: ' Ze ',
        locale: 'en',
        ownerId: 'owner',
        generation: 1,
      );
      expect(
        result.valueOrNull,
        hasLength(1),
        reason: '${result.failureOrNull}',
      );
      expect(result.valueOrNull!.single.latitude, 0);
      expect(result.valueOrNull!.single.timeZoneId, 'Europe/London');
    },
  );

  test(
    'empty, malformed, throttled and offline responses stay distinct',
    () async {
      final cases = <(Object?, String)>[
        ({'results': <Object>[]}, 'empty'),
        ({'results': 'bad'}, 'prayerSearchInvalidResponse'),
        (429, 'prayerSearchThrottled'),
        (DioExceptionType.connectionError, 'prayerSearchOffline'),
        (DioExceptionType.connectionTimeout, 'prayerSearchOffline'),
        (DioExceptionType.receiveTimeout, 'prayerSearchOffline'),
      ];
      for (final (reply, expected) in cases) {
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                if (reply == 429) {
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      response: Response(
                        requestOptions: options,
                        statusCode: 429,
                      ),
                      type: DioExceptionType.badResponse,
                    ),
                  );
                } else if (reply is DioExceptionType) {
                  handler.reject(
                    DioException(requestOptions: options, type: reply),
                  );
                } else {
                  handler.resolve(
                    Response(requestOptions: options, data: reply),
                  );
                }
              },
            ),
          );
        final result = await DioCitySearch(
          configuration: PrayerSearchConfiguration.resolve().valueOrNull!,
          dio: dio,
        ).search(query: 'Cairo', locale: 'ar', ownerId: 'owner', generation: 1);
        if (expected == 'empty') {
          expect(result.valueOrNull, isEmpty);
        } else {
          expect(result.failureOrNull?.messageKey, expected);
        }
      }
    },
  );

  test('Arabic query keeps at most ten disambiguated cities', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.uri.queryParameters['language'], 'ar');
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'results': [
                    for (var index = 0; index < 12; index++)
                      {
                        'id': index + 1,
                        'name': 'مدينة',
                        'admin1': 'منطقة $index',
                        'country_code': 'EG',
                        'country': 'مصر',
                        'latitude': 30.0,
                        'longitude': 31.0,
                        'timezone': 'Africa/Cairo',
                      },
                  ],
                },
              ),
            );
          },
        ),
      );
    final result = await DioCitySearch(
      configuration: PrayerSearchConfiguration.resolve().valueOrNull!,
      dio: dio,
    ).search(query: 'مدينة', locale: 'ar', ownerId: 'owner', generation: 1);
    expect(result.valueOrNull, hasLength(10));
    expect(result.valueOrNull!.first.name, 'مدينة');
    expect(result.valueOrNull!.first.adminName, 'منطقة 0');
    expect(result.valueOrNull!.last.providerCityId, '10');
  });

  test('cancelling a pending provider reply keeps it unselectable', () async {
    final gate = Completer<void>();
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            await gate.future;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'results': [
                    {
                      'id': 1,
                      'name': 'Cairo',
                      'country_code': 'EG',
                      'country': 'Egypt',
                      'latitude': 30.0444,
                      'longitude': 31.2357,
                      'timezone': 'Africa/Cairo',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
    final adapter = DioCitySearch(
      configuration: PrayerSearchConfiguration.resolve().valueOrNull!,
      dio: dio,
    );
    final pending = adapter.search(
      query: 'Cairo',
      locale: 'en',
      ownerId: 'owner',
      generation: 7,
    );
    await Future<void>.delayed(Duration.zero);
    adapter.cancel(ownerId: 'owner', generation: 7);
    gate.complete();
    final result = await pending;
    expect(result.valueOrNull, isNull);
    expect(result.failureOrNull?.messageKey, 'prayerSearchCancelled');
  });
}
