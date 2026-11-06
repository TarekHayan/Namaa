import '../domain/prayer_city.dart';
import '../domain/prayer_preferences.dart';
import 'city_search_port.dart';
import 'prayer_preferences_commands.dart';

/// Keeps a manually chosen city's saved name in the app language.
///
/// The provider returns names in the language of the search, and a city is
/// saved once. When the app later shows the other language, the same city is
/// looked up by id and only its display names are replaced; coordinates,
/// time zone and method stay exactly as chosen, so times do not change.
final class PrayerCityNameLocalizer {
  PrayerCityNameLocalizer({
    required CitySearchPort search,
    required PrayerPreferencesCommands commands,
    DateTime Function()? nowUtc,
  }) : _search = search,
       _commands = commands,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final CitySearchPort _search;
  final PrayerPreferencesCommands _commands;
  final DateTime Function() _nowUtc;

  static final _arabic = RegExp(r'[؀-ۿ]');

  /// Whether [city]'s saved name already reads in [locale].
  static bool matches(PrayerCity city, String locale) =>
      city.provider == 'device' ||
      _arabic.hasMatch(city.name) == (locale == 'ar');

  /// Returns true when new names were saved. Offline, unsupported providers
  /// and unchanged names leave the saved city untouched.
  Future<bool> localize(PrayerPreferences current, String locale) async {
    final city = current.city;
    if (matches(city, locale)) return false;
    try {
      final found = (await _search.lookup(
        city: city,
        locale: locale,
      )).valueOrNull;
      if (found == null ||
          (found.name == city.name &&
              found.countryName == city.countryName &&
              found.adminName == city.adminName)) {
        return false;
      }
      final saved = await _commands.confirm(
        ownerId: current.accountId,
        city: PrayerCity(
          provider: city.provider,
          providerCityId: city.providerCityId,
          name: found.name,
          countryCode: city.countryCode,
          countryName: found.countryName,
          adminName: found.adminName,
          latitude: city.latitude,
          longitude: city.longitude,
          timeZoneId: city.timeZoneId,
        ),
        method: current.calculationMethod,
        expectedRevision: current.revision,
        nowUtc: _nowUtc(),
      );
      return saved.valueOrNull != null;
    } catch (_) {
      return false;
    }
  }
}
