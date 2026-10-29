import 'package:adhan_dart/adhan_dart.dart';
import 'package:adhan_dart/src/SolarTime.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  test(
    'pinned raw solar and seven preset APIs compile and yield UTC times',
    () {
      const coordinates = Coordinates(30.0444, 31.2357);
      final date = DateTime.utc(2026, 10, 29);
      final solar = SolarTime(date, coordinates);
      expect(solar.sunrise.isFinite, isTrue);
      expect(solar.sunset.isFinite, isTrue);
      expect(solar.hourAngle(-19.5, false).isFinite, isTrue);

      final presets = [
        CalculationMethodParameters.egyptian(),
        CalculationMethodParameters.muslimWorldLeague(),
        CalculationMethodParameters.ummAlQura(),
        CalculationMethodParameters.dubai(),
        CalculationMethodParameters.northAmerica(),
        CalculationMethodParameters.kuwait(),
        CalculationMethodParameters.qatar(),
      ];
      for (final parameters in presets) {
        parameters.madhab = Madhab.shafi;
        final times = PrayerTimes(
          date: date,
          coordinates: coordinates,
          calculationParameters: parameters,
        );
        expect(times.fajr.isUtc, isTrue);
        expect(times.isha.isAfter(times.maghrib), isTrue);
      }
      expect(presets[2].ishaInterval, 90);
      expect(presets[6].ishaInterval, 90);
    },
  );

  test('pinned UUID supports a caller-supplied v5 namespace', () {
    const uuid = Uuid();
    expect(
      uuid.v5(Namespace.dns.value, 'www.widgets.com'),
      '21f7f8de-8051-5b89-8680-0195ef798b6a',
    );
  });

  test('pinned Dio supports bounded, cancellable discovery', () {
    final options = BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
    );
    expect(options.connectTimeout, const Duration(seconds: 5));
    expect(options.receiveTimeout, const Duration(seconds: 8));
    final token = CancelToken();
    token.cancel();
    expect(token.isCancelled, isTrue);
  });
}
