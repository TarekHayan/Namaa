import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/prayer/data/prayer_search_configuration.dart';

void main() {
  final now = DateTime.utc(2026, 10, 29);

  group('Prayer city search configuration', () {
    test('debug/profile evaluation selects the public HTTPS search', () {
      final config = PrayerSearchConfiguration.resolve(
        nowUtc: now,
      ).valueOrNull!;

      expect(config.mode, PrayerSearchMode.evaluation);
      expect(
        config.endpoint,
        Uri.parse('https://geocoding-api.open-meteo.com/v1/search'),
      );
    });

    test('release never enables the evaluation endpoint', () {
      final result = PrayerSearchConfiguration.resolve(
        isRelease: true,
        gatewayUrl: 'https://cities.namaa.example',
        nowUtc: now,
      );

      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull!.category, AppFailureCategory.configuration);
      expect(result.failureOrNull!.recoverable, isTrue);
      expect(result.failureOrNull!.occurredAt, now);
      expect(result.failureOrNull!.messageKey, 'prayerSearchUnavailable');
    });

    for (final isRelease in [false, true]) {
      test('licensed gateway is explicit (release=$isRelease)', () {
        final config = PrayerSearchConfiguration.resolve(
          isRelease: isRelease,
          mode: 'licensedGateway',
          gatewayUrl: 'https://cities.namaa.example/',
          nowUtc: now,
        ).valueOrNull!;

        expect(config.mode, PrayerSearchMode.licensedGateway);
        expect(
          config.endpoint,
          Uri.parse('https://cities.namaa.example/v1/cities/search'),
        );
      });
    }

    for (final url in [
      '',
      'not a URI',
      '/relative',
      'http://cities.namaa.example',
      'file:///cities',
      'https:///missing-host',
      'https://cities.namaa.example/path',
      'https://cities.namaa.example?api_key=do-not-leak',
      'https://cities.namaa.example#secret',
      'https://user:do-not-leak@cities.namaa.example',
      'https://geocoding-api.open-meteo.com',
    ]) {
      test(
        'invalid gateway fails without public fallback: ${url.hashCode}',
        () {
          final result = PrayerSearchConfiguration.resolve(
            isRelease: true,
            mode: 'licensedGateway',
            gatewayUrl: url,
            nowUtc: now,
          );

          expect(result.valueOrNull, isNull);
          expect(
            result.failureOrNull!.category,
            AppFailureCategory.configuration,
          );
          expect(
            result.failureOrNull!.technicalCause,
            'invalid_gateway_origin',
          );
          expect(
            result.failureOrNull.toString(),
            isNot(contains('do-not-leak')),
          );
        },
      );
    }

    test('unknown mode fails closed even in development', () {
      final result = PrayerSearchConfiguration.resolve(
        mode: 'typo',
        nowUtc: now,
      );
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull!.technicalCause, 'unknown_search_mode');
    });
  });
}
