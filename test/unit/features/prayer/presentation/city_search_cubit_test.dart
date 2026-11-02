import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/city_search_port.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_commands.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/presentation/city_search_cubit.dart';
import 'package:namma_project/features/prayer/presentation/city_search_state.dart';

class _Search extends Fake implements CitySearchPort {
  final requests = <int, Completer<AppResult<List<PrayerCity>>>>{};
  final cancelled = <int>[];

  @override
  Future<AppResult<List<PrayerCity>>> search({
    required String query,
    required String locale,
    required String ownerId,
    required int generation,
  }) {
    final result = Completer<AppResult<List<PrayerCity>>>();
    requests[generation] = result;
    return result.future;
  }

  @override
  void cancel({required String ownerId, required int generation}) {
    cancelled.add(generation);
  }
}

class _Store extends Fake implements PrayerPreferencesPort {}

void main() {
  test(
    'a late result from an earlier query never replaces current cities',
    () async {
      final search = _Search();
      final cubit = CitySearchCubit(
        search: search,
        commands: PrayerPreferencesCommands(_Store()),
        ownerId: 'owner',
        locale: 'en',
        debounce: const Duration(milliseconds: 1),
      );
      addTearDown(cubit.close);
      cubit.updateQuery('Ca');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      cubit.updateQuery('Du');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final dubai = PrayerCity(
        provider: 'fixture',
        providerCityId: 'dubai',
        name: 'Dubai',
        countryCode: 'AE',
        countryName: 'United Arab Emirates',
        latitude: 25.2,
        longitude: 55.3,
        timeZoneId: 'Asia/Dubai',
      );
      search.requests[2]!.complete(AppResult.success([dubai]));
      await Future<void>.delayed(Duration.zero);
      search.requests[1]!.complete(const AppResult.success([]));
      await Future<void>.delayed(Duration.zero);
      expect(search.cancelled, contains(1));
      expect(cubit.state.phase, CitySearchPhase.results);
      expect(cubit.state.results.single, dubai);
      expect(cubit.state.query, 'Du');
    },
  );
}
