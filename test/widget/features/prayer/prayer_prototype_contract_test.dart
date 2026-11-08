import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/prayer/application/prayer_clock_port.dart';
import 'package:namma_project/features/prayer/application/prayer_context_service.dart';
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
import 'package:namma_project/features/prayer/presentation/widgets/prayer_guidance_section.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_header.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_schedule_list.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_supplementary_times.dart';

class _Preferences extends Fake implements PrayerPreferencesPort {
  _Preferences(this.value);
  final PrayerPreferences value;

  @override
  Stream<PrayerPreferences?> watch(String ownerId) => Stream.value(value);
}

class _Reports extends Fake implements PrayerRepository {
  @override
  Stream<List<PrayerReport>> watchDay({
    required String accountId,
    required PrayerLocalDate date,
  }) => Stream.value(const []);
}

class _Clock extends Fake implements PrayerClockPort {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 11, 1, 12);

  @override
  PrayerLocalDate cityDate(DateTime nowUtc, String timeZoneId) =>
      PrayerLocalDate.parse('2026-11-01');
}

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    testWidgets('prototype groups and roles stay in order for $locale', (
      tester,
    ) async {
      final phone = locale.languageCode == 'ar';
      tester.view.physicalSize = Size(phone ? 390 : 1200, phone ? 844 : 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preferences = _Preferences(
        PrayerPreferences(
          accountId: 'owner',
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
          updatedAt: DateTime.utc(2026, 11),
        ),
      );
      final cubit = PrayerCubit(
        ownerId: 'owner',
        context: PrayerContextService(
          preferences: preferences,
          reports: _Reports(),
          calculator: AdhanPrayerCalculator(),
          clock: _Clock(),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          home: Scaffold(
            body: PrayerScreen(
              ownerId: 'owner',
              cubit: cubit,
              commands: PrayerPreferencesCommands(preferences),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final groups = [
        find.byType(PrayerHeader),
        find.byType(PrayerScheduleList),
        find.byType(PrayerSupplementaryTimes),
        find.byType(PrayerGuidanceSection),
      ];
      for (final group in groups) {
        expect(group, findsOneWidget);
      }
      for (var i = 1; i < groups.length; i++) {
        expect(
          tester.getTopLeft(groups[i]).dy,
          greaterThan(tester.getTopLeft(groups[i - 1]).dy),
        );
      }
      for (final name in PrayerName.values) {
        expect(find.byKey(Key('prayer_time_${name.wireName}')), findsOneWidget);
        for (final status in [
          'completed_on_time',
          'completed_late',
          'missed',
        ]) {
          expect(
            find.byKey(Key('prayer_status_${name.wireName}_$status')),
            findsOneWidget,
          );
        }
      }
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(Key('prayer_supplementary_$i')), findsOneWidget);
      }
      final headerSurface = tester.widget<Container>(
        find.byKey(const Key('prayer_header')),
      );
      expect(headerSurface.padding, EdgeInsets.all(phone ? 24 : 32));
      expect(
        (headerSurface.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(32),
      );
      final cardSurface = tester.widget<Container>(
        find.byKey(const Key('prayer_time_fajr')),
      );
      expect(cardSurface.padding, EdgeInsets.all(phone ? 20 : 24));
      expect(
        (cardSurface.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(32),
      );
      final supplementary = tester.widget<Container>(
        find.byKey(const Key('prayer_supplementary_0')),
      );
      expect(supplementary.padding, const EdgeInsets.all(16));
      expect(
        (supplementary.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(16),
      );
      final guidance = tester.widget<Container>(
        find.byKey(const Key('prayer_guidance_section')),
      );
      expect(
        (guidance.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(32),
      );
      expect(guidance.padding, EdgeInsets.all(phone ? 24 : 32));
      expect(find.byKey(const Key('prayer_guidance_jahr')), findsOneWidget);
      expect(find.byKey(const Key('prayer_guidance_sirr')), findsOneWidget);
      final header = tester.widget<PrayerHeader>(groups.first);
      expect(header.completedCount, 0);
      final copy = FoundationLocalizations.of(tester.element(groups.first));
      expect(find.text(copy.prayerStreakSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(cubit.close);
    });
  }
}
