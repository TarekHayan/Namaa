import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/city_search_port.dart';
import 'package:namma_project/features/prayer/application/prayer_city_name_localizer.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_commands.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';

const _arabicName = 'نيويورك';

PrayerCity _city({
  String provider = 'open-meteo/geonames',
  String name = _arabicName,
  String country = 'أمريكا',
}) => PrayerCity(
  provider: provider,
  providerCityId: '5128581',
  name: name,
  countryCode: 'US',
  countryName: country,
  latitude: 40.71427,
  longitude: -74.00597,
  timeZoneId: 'America/New_York',
);

PrayerPreferences _preferences(PrayerCity city) => PrayerPreferences(
  accountId: 'owner-a',
  city: city,
  calculationMethod: 'northAmerica',
  revision: 3,
  updatedAt: DateTime.utc(2026, 11),
);

class _Search extends Fake implements CitySearchPort {
  _Search(this.result);
  final AppResult<PrayerCity?> result;
  final calls = <String>[];
  @override
  Future<AppResult<PrayerCity?>> lookup({
    required PrayerCity city,
    required String locale,
  }) async {
    calls.add(locale);
    return result;
  }
}

class _Store extends Fake implements PrayerPreferencesPort {
  PrayerPreferences? saved;
  int? expected;
  @override
  Future<AppResult<PrayerPreferences>> save(
    PrayerPreferences value, {
    required int? expectedRevision,
  }) async {
    saved = value;
    expected = expectedRevision;
    return AppResult.success(value);
  }
}

void main() {
  final english = PrayerCity(
    provider: 'open-meteo/geonames',
    providerCityId: '5128581',
    name: 'New York',
    countryCode: 'US',
    countryName: 'United States',
    adminName: 'New York',
    // A lookup's coordinates never replace the chosen ones.
    latitude: 1,
    longitude: 1,
    timeZoneId: 'America/New_York',
  );

  test(
    'English app replaces an Arabic saved name, keeping the place',
    () async {
      final search = _Search(AppResult.success(english));
      final store = _Store();
      final localizer = PrayerCityNameLocalizer(
        search: search,
        commands: PrayerPreferencesCommands(store),
        nowUtc: () => DateTime.utc(2026, 11, 6),
      );
      expect(await localizer.localize(_preferences(_city()), 'en'), isTrue);
      expect(search.calls, ['en']);
      final saved = store.saved!;
      expect(saved.city.name, 'New York');
      expect(saved.city.countryName, 'United States');
      expect(saved.city.adminName, 'New York');
      expect(saved.city.latitude, 40.71427);
      expect(saved.city.longitude, -74.00597);
      expect(saved.city.timeZoneId, 'America/New_York');
      expect(saved.calculationMethod, 'northAmerica');
      expect(store.expected, 3);
      expect(saved.revision, 4);
    },
  );

  test(
    'matching language, device location and failures save nothing',
    () async {
      for (final (prefs, locale, result) in [
        (_preferences(_city()), 'ar', AppResult<PrayerCity?>.success(english)),
        (
          _preferences(_city(provider: 'device', name: 'Current location')),
          'ar',
          AppResult<PrayerCity?>.success(english),
        ),
        (
          _preferences(_city()),
          'en',
          const AppResult<PrayerCity?>.success(null),
        ),
        (
          _preferences(_city()),
          'en',
          AppResult<PrayerCity?>.failure(
            AppFailure.recoverable(
              category: AppFailureCategory.network,
              messageKey: 'prayerSearchOffline',
              occurredAt: DateTime.utc(2026),
            ),
          ),
        ),
      ]) {
        final store = _Store();
        final localizer = PrayerCityNameLocalizer(
          search: _Search(result),
          commands: PrayerPreferencesCommands(store),
        );
        expect(await localizer.localize(prefs, locale), isFalse);
        expect(store.saved, isNull);
      }
    },
  );
}
