import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
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
  final queries = <String>[];
  final locales = <String>[];

  @override
  Future<AppResult<List<PrayerCity>>> search({
    required String query,
    required String locale,
    required String ownerId,
    required int generation,
  }) {
    queries.add(query);
    locales.add(locale);
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
  testWidgets('default debounce waits 350ms and sends only the latest query', (
    tester,
  ) async {
    final search = _Search();
    final cubit = CitySearchCubit(
      search: search,
      commands: PrayerPreferencesCommands(_Store()),
      ownerId: 'owner',
      locale: 'en',
    );
    addTearDown(cubit.close);
    cubit.updateQuery('  Cairo  ');
    await tester.pump(const Duration(milliseconds: 349));
    expect(search.queries, isEmpty);
    cubit.updateQuery('  Dubai  ');
    await tester.pump(const Duration(milliseconds: 349));
    expect(search.queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(search.queries, ['  Dubai  ']);
    expect(search.cancelled, contains(1));
    search.requests[2]!.complete(const AppResult.success([]));
    await tester.pump();
    expect(cubit.state.phase, CitySearchPhase.noResults);
  });

  testWidgets('closing the old owner cancels pending work and late replies', (
    tester,
  ) async {
    final search = _Search();
    final oldOwner = CitySearchCubit(
      search: search,
      commands: PrayerPreferencesCommands(_Store()),
      ownerId: 'old-owner',
      locale: 'en',
    );
    oldOwner.updateQuery('Cairo');
    await tester.pump(const Duration(milliseconds: 350));
    expect(search.requests, contains(1));
    await oldOwner.close();
    expect(search.cancelled, contains(1));
    search.requests[1]!.complete(const AppResult.success([]));
    await tester.pump();
    expect(oldOwner.isClosed, isTrue);

    final nextSearch = _Search();
    final newOwner = CitySearchCubit(
      search: nextSearch,
      commands: PrayerPreferencesCommands(_Store()),
      ownerId: 'new-owner',
      locale: 'en',
    );
    addTearDown(newOwner.close);
    newOwner.updateQuery('Dubai');
    await tester.pump(const Duration(milliseconds: 350));
    expect(nextSearch.queries, ['Dubai']);
    nextSearch.requests[1]!.complete(const AppResult.success([]));
    await tester.pump();
    expect(newOwner.state.phase, CitySearchPhase.noResults);
  });

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

  test('invalid query and debounce never issue a stale request', () async {
    final search = _Search();
    final cubit = CitySearchCubit(
      search: search,
      commands: PrayerPreferencesCommands(_Store()),
      ownerId: 'owner',
      locale: 'en',
      debounce: const Duration(milliseconds: 10),
    );
    addTearDown(cubit.close);
    cubit.updateQuery('x');
    expect(cubit.state.phase, CitySearchPhase.idle);
    cubit.updateQuery('x' * 101);
    expect(cubit.state.phase, CitySearchPhase.idle);
    cubit.updateQuery('Ca');
    cubit.updateQuery('Cai');
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(search.queries, ['Cai']);
    expect(cubit.state.phase, CitySearchPhase.searching);
    search.requests[4]!.complete(const AppResult.success([]));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.phase, CitySearchPhase.noResults);
  });

  test('locale change discards old response and retries in Arabic', () async {
    final search = _Search();
    final cubit = CitySearchCubit(
      search: search,
      commands: PrayerPreferencesCommands(_Store()),
      ownerId: 'owner',
      locale: 'en',
      debounce: const Duration(milliseconds: 1),
    );
    addTearDown(cubit.close);
    cubit.updateQuery('Cairo');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    cubit.updateLocale('ar');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(search.locales, ['en', 'ar']);
    expect(search.cancelled, contains(1));
    search.requests[1]!.complete(const AppResult.success([]));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.phase, CitySearchPhase.searching);
    search.requests[2]!.complete(const AppResult.success([]));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.phase, CitySearchPhase.noResults);
  });

  test('throttled provider response remains distinct from offline', () async {
    final search = _Search();
    final cubit = CitySearchCubit(
      search: search,
      commands: PrayerPreferencesCommands(_Store()),
      ownerId: 'owner',
      locale: 'en',
      debounce: const Duration(milliseconds: 1),
    );
    addTearDown(cubit.close);
    cubit.updateQuery('Cairo');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    search.requests[1]!.complete(
      AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.network,
          messageKey: 'prayerSearchThrottled',
          occurredAt: DateTime.utc(2026),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.phase, CitySearchPhase.throttled);
    expect(cubit.state.results, isEmpty);
  });

  test('offline search can retry without retaining an old candidate', () async {
    final search = _Search();
    final cubit = CitySearchCubit(
      search: search,
      commands: PrayerPreferencesCommands(_Store()),
      ownerId: 'owner',
      locale: 'en',
      debounce: const Duration(milliseconds: 1),
    );
    addTearDown(cubit.close);
    cubit.updateQuery('Cairo');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    search.requests[1]!.complete(
      AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.network,
          messageKey: 'prayerSearchOffline',
          occurredAt: DateTime.utc(2026),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.phase, CitySearchPhase.offline);
    cubit.updateQuery('Cairo');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final cairo = PrayerCity(
      provider: 'fixture',
      providerCityId: 'cairo',
      name: 'Cairo',
      countryCode: 'EG',
      countryName: 'Egypt',
      latitude: 30.0444,
      longitude: 31.2357,
      timeZoneId: 'Africa/Cairo',
    );
    search.requests[2]!.complete(AppResult.success([cairo]));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.phase, CitySearchPhase.results);
    expect(cubit.state.results, [cairo]);
    expect(cubit.state.candidate, isNull);
  });
}
