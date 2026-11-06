import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/prayer_clock_port.dart';
import 'package:namma_project/features/prayer/application/prayer_context_service.dart';
import 'package:namma_project/features/prayer/application/prayer_device_location_port.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_commands.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/application/prayer_repository.dart';
import 'package:namma_project/features/prayer/data/adhan_prayer_calculator.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/presentation/prayer_cubit.dart';
import 'package:namma_project/features/prayer/presentation/prayer_screen.dart';

class _Preferences extends Fake implements PrayerPreferencesPort {
  _Preferences({this.initial});
  final PrayerPreferences? initial;
  PrayerPreferences? saved;
  @override
  Stream<PrayerPreferences?> watch(String accountId) => Stream.value(initial);
  @override
  Future<AppResult<PrayerPreferences>> save(
    PrayerPreferences value, {
    required int? expectedRevision,
  }) async {
    saved = value;
    return AppResult.success(value);
  }
}

class _Clock extends Fake implements PrayerClockPort {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 11);
  @override
  PrayerLocalDate cityDate(DateTime nowUtc, String timeZoneId) =>
      PrayerLocalDate.parse('2026-11-01');
}

class _Reports extends Fake implements PrayerRepository {
  @override
  Stream<List<PrayerReport>> watchDay({
    required String accountId,
    required PrayerLocalDate date,
  }) => Stream.value([]);
}

class _Location extends Fake implements PrayerDeviceLocationPort {
  _Location({this.denied = false});
  bool denied;
  int calls = 0;
  final opened = <PrayerLocationProblem>[];

  @override
  Future<void> openSettings(PrayerLocationProblem problem) async =>
      opened.add(problem);
  @override
  Future<PrayerDeviceLocation> locate() async {
    calls++;
    if (denied) {
      throw const PrayerLocationException(
        PrayerLocationProblem.permissionDenied,
      );
    }
    return PrayerDeviceLocation(
      city: PrayerCity(
        provider: 'device',
        providerCityId: '30.0444,31.2357',
        name: 'Current location',
        countryCode: 'XX',
        countryName: 'GPS',
        latitude: 30.0444,
        longitude: 31.2357,
        timeZoneId: 'Africa/Cairo',
      ),
      suggestedMethod: 'egyptian',
    );
  }
}

void main() {
  Future<PrayerCubit> show(
    WidgetTester tester,
    _Preferences preferences,
    _Location location,
  ) async {
    final cubit = PrayerCubit(
      context: PrayerContextService(
        preferences: preferences,
        reports: _Reports(),
        calculator: AdhanPrayerCalculator(),
        clock: _Clock(),
      ),
      ownerId: 'owner-a',
    );
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: PrayerScreen(
            ownerId: 'owner-a',
            cubit: cubit,
            commands: PrayerPreferencesCommands(preferences),
            location: location,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return cubit;
  }

  testWidgets('first setup uses device coordinates without typing a city', (
    tester,
  ) async {
    final preferences = _Preferences();
    final location = _Location();
    final cubit = await show(tester, preferences, location);
    expect(location.calls, 1);
    expect(preferences.saved?.accountId, 'owner-a');
    expect(preferences.saved?.city.latitude, 30.0444);
    expect(preferences.saved?.calculationMethod, 'egyptian');
    await tester.runAsync(cubit.close);
  });

  testWidgets('denied permission keeps manual city selection available', (
    tester,
  ) async {
    final preferences = _Preferences();
    final location = _Location(denied: true);
    final cubit = await show(tester, preferences, location);
    expect(location.calls, 1);
    expect(preferences.saved, isNull);
    // No city search: the way forward is the permission itself.
    expect(find.text('Search cities'), findsNothing);
    expect(find.textContaining('Location permission'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.byKey(const Key('prayer_open_settings')));
    await tester.pump();
    expect(location.opened, [PrayerLocationProblem.permissionDenied]);
    // Returning from settings with permission granted retries by itself.
    location.denied = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(location.calls, 2);
    expect(preferences.saved?.city.latitude, 30.0444);
    await tester.runAsync(cubit.close);
  });

  testWidgets('return visit rechecks a saved fix without rewriting it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = _Preferences(
      initial: PrayerPreferences(
        accountId: 'owner-a',
        city: PrayerCity(
          provider: 'device',
          providerCityId: '30.0444,31.2357',
          name: 'Current location',
          countryCode: 'XX',
          countryName: 'GPS',
          latitude: 30.0444,
          longitude: 31.2357,
          timeZoneId: 'Africa/Cairo',
        ),
        calculationMethod: 'egyptian',
        revision: 1,
        updatedAt: DateTime.utc(2026),
      ),
    );
    final location = _Location();
    final cubit = await show(tester, preferences, location);
    expect(location.calls, 1);
    expect(preferences.saved, isNull);
    expect(find.text('My current location'), findsOneWidget);
    final heading = tester.widget<Text>(find.text('Prayer times'));
    final locationLabel = tester.widget<Text>(find.text('My current location'));
    expect(heading.style?.fontSize, lessThanOrEqualTo(40));
    expect(locationLabel.style?.fontSize, lessThanOrEqualTo(24));
    // Once granted, location is re-checked quietly: no permanent button on
    // the screen. It stays reachable from the settings sheet.
    expect(find.byKey(const Key('prayer_use_location')), findsNothing);
    await tester.tap(find.byKey(const Key('prayer_settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prayer_use_location')), findsOneWidget);
    expect(find.byKey(const Key('prayer_method')), findsOneWidget);
    expect(find.byKey(const Key('prayer_city_search')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.runAsync(cubit.close);
  });

  testWidgets('prayer screen presents the four groups in order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = _Preferences(
      initial: PrayerPreferences(
        accountId: 'owner-a',
        city: PrayerCity(
          provider: 'fixture',
          providerCityId: 'cairo',
          name: 'Cairo',
          countryCode: 'EG',
          countryName: 'Egypt',
          latitude: 30.0444,
          longitude: 31.2357,
          timeZoneId: 'Africa/Cairo',
        ),
        calculationMethod: 'egyptian',
        revision: 1,
        updatedAt: DateTime.utc(2026),
      ),
    );
    final cubit = await show(tester, preferences, _Location());
    final header = find.byKey(const Key('prayer_header'));
    expect(header, findsOneWidget);
    for (final name in PrayerName.values) {
      expect(find.byKey(Key('prayer_time_${name.wireName}')), findsOneWidget);
      for (final status in ['completed_on_time', 'completed_late', 'missed']) {
        expect(
          find.byKey(Key('prayer_status_${name.wireName}_$status')),
          findsOneWidget,
        );
      }
    }
    final first = find.byKey(const Key('prayer_time_fajr'));
    final last = find.byKey(const Key('prayer_time_isha'));
    final info = find.byKey(const Key('prayer_supplementary_0'));
    final guidance = find.byKey(const Key('prayer_guidance_section'));
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(Key('prayer_supplementary_$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('prayer_guidance_jahr')), findsOneWidget);
    expect(find.byKey(const Key('prayer_guidance_sirr')), findsOneWidget);
    expect(tester.getTopLeft(header).dy, lessThan(tester.getTopLeft(first).dy));
    expect(tester.getTopLeft(first).dy, lessThan(tester.getTopLeft(last).dy));
    expect(tester.getTopLeft(last).dy, lessThan(tester.getTopLeft(info).dy));
    expect(
      tester.getTopLeft(info).dy,
      lessThan(tester.getTopLeft(guidance).dy),
    );
    expect(find.text('Prayer streak: coming soon'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(cubit.close);
  });
}
