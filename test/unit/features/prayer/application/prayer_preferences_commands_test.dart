import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_commands.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';

class _Store extends Fake implements PrayerPreferencesPort {
  PrayerPreferences? saved;
  int? base;

  @override
  Future<AppResult<PrayerPreferences>> save(
    PrayerPreferences preferences, {
    required int? expectedRevision,
  }) async {
    saved = preferences;
    base = expectedRevision;
    return AppResult.success(preferences);
  }
}

void main() {
  final city = PrayerCity(
    provider: 'fixture',
    providerCityId: 'cairo',
    name: 'Cairo',
    countryCode: 'EG',
    countryName: 'Egypt',
    latitude: 30.0444,
    longitude: 31.2357,
    timeZoneId: 'Africa/Cairo',
  );

  test(
    'confirm preserves selected city and increments revision once',
    () async {
      final store = _Store();
      final result = await PrayerPreferencesCommands(store).confirm(
        ownerId: 'owner',
        city: city,
        method: 'egyptian',
        expectedRevision: 2,
        nowUtc: DateTime.utc(2026, 3, 20),
      );
      expect(result.failureOrNull, isNull);
      expect(store.base, 2);
      expect(store.saved?.revision, 3);
      expect(store.saved?.city, city);
    },
  );

  test('invalid method is rejected before storage', () async {
    final store = _Store();
    final result = await PrayerPreferencesCommands(store).confirm(
      ownerId: 'owner',
      city: city,
      method: 'invented',
      expectedRevision: null,
      nowUtc: DateTime.utc(2026),
    );
    expect(result.failureOrNull, isNotNull);
    expect(store.saved, isNull);
  });

  test('negative revision and non-UTC clock never reach storage', () async {
    final store = _Store();
    final commands = PrayerPreferencesCommands(store);
    final negative = await commands.confirm(
      ownerId: 'owner',
      city: city,
      method: 'egyptian',
      expectedRevision: -1,
      nowUtc: DateTime.utc(2026),
    );
    expect(negative.failureOrNull, isNotNull);
    final localClock = await commands.confirm(
      ownerId: 'owner',
      city: city,
      method: 'egyptian',
      expectedRevision: null,
      nowUtc: DateTime(2026),
    );
    expect(localClock.failureOrNull, isNotNull);
    expect(store.saved, isNull);
  });
}
