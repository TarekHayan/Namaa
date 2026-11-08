import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/application/prayer_device_location_port.dart';
import 'package:namma_project/features/prayer/data/geolocator_prayer_location.dart';

void main() {
  test('uses measured coordinates and the provider time zone', () async {
    var requests = 0;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests++;
            expect(options.uri.host, 'api.aladhan.com');
            expect(options.uri.queryParameters['latitude'], '30.0444');
            expect(options.uri.queryParameters['longitude'], '31.2357');
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'code': 200,
                  'data': {
                    'meta': {
                      'timezone': 'Africa/Cairo',
                      'method': {'id': 5},
                    },
                  },
                },
              ),
            );
          },
        ),
      );
    final result = await GeolocatorPrayerLocation(dio: dio).resolveCoordinates(
      latitude: 30.0444,
      longitude: 31.2357,
      accuracyMeters: 25,
    );
    expect(requests, 1);
    expect(result.city.provider, 'device');
    expect(result.city.latitude, 30.0444);
    expect(result.city.timeZoneId, 'Africa/Cairo');
    expect(result.suggestedMethod, 'egyptian');
  });

  test(
    'rejects an imprecise fix before it can appear as exact prayer times',
    () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (_, _) {
              fail('An imprecise fix must not be sent to the API');
            },
          ),
        );
      await expectLater(
        GeolocatorPrayerLocation(dio: dio).resolveCoordinates(
          latitude: 27,
          longitude: 30,
          accuracyMeters: 50000,
        ),
        throwsA(
          isA<PrayerLocationException>().having(
            (error) => error.problem,
            'problem',
            PrayerLocationProblem.unavailable,
          ),
        ),
      );
    },
  );
  test(
    'retries a temporary zone-service failure without asking for a city',
    () async {
      var attempts = 0;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              attempts++;
              if (attempts == 1) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 503,
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
              } else {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'code': 200,
                      'data': {
                        'meta': {
                          'timezone': 'Africa/Cairo',
                          'method': {'id': 5},
                        },
                      },
                    },
                  ),
                );
              }
            },
          ),
        );
      final result = await GeolocatorPrayerLocation(dio: dio)
          .resolveCoordinates(
            latitude: 30.0444,
            longitude: 31.2357,
            accuracyMeters: 100,
          );
      expect(attempts, 2);
      expect(result.city.timeZoneId, 'Africa/Cairo');
    },
  );
}
