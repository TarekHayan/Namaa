import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/features/prayer/domain/prayer_guidance.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_guidance_section.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_schedule_list.dart';

void main() {
  testWidgets('card tint follows report status in light and dark themes', (
    tester,
  ) async {
    final at = DateTime.utc(2026, 11);
    for (final brightness in Brightness.values) {
      for (final status in [
        PrayerStatus.pending,
        PrayerStatus.completedOnTime,
        PrayerStatus.completedLate,
        PrayerStatus.missed,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            themeMode: ThemeMode.light,
            supportedLocales: FoundationLocalizations.supportedLocales,
            localizationsDelegates:
                FoundationLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SingleChildScrollView(
                child: PrayerScheduleList(
                  schedule: null,
                  timeZoneId: 'UTC',
                  actions: const {},
                  onStatusChanged: (_, _) {},
                  reports: [
                    PrayerReport(
                      accountId: 'owner',
                      reportId: 'id',
                      date: PrayerLocalDate.parse('2026-11-01'),
                      name: PrayerName.fajr,
                      status: status,
                      reportedCompletionAt: status.isCompleted ? at : null,
                      recordedZoneId: 'UTC',
                      recordedOffsetMinutes: 0,
                      createdAt: at,
                      updatedAt: at,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = tester.widget<Container>(
          find.byKey(const Key('prayer_time_fajr')),
        );
        final colors = brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light;
        final expected = switch (status) {
          PrayerStatus.pending => colors.surface,
          PrayerStatus.completedOnTime => Color.alphaBlend(
            colors.success.withValues(alpha: 0.10),
            colors.surface,
          ),
          PrayerStatus.completedLate => Color.alphaBlend(
            colors.warning.withValues(alpha: 0.10),
            colors.surface,
          ),
          PrayerStatus.missed => Color.alphaBlend(
            colors.error.withValues(alpha: 0.10),
            colors.surface,
          ),
        };
        expect((card.decoration! as BoxDecoration).color, expected);
      }
    }
  });
  test('resident obligatory counts follow the five prayers', () {
    expect(PrayerName.values.map(residentObligatoryRakahs), [2, 4, 4, 3, 4]);
  });
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    testWidgets('guidance and all prayer cards render for $locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  PrayerScheduleList(
                    schedule: null,
                    timeZoneId: 'UTC',
                    reports: const [],
                    actions: const {},
                    onStatusChanged: (_, _) {},
                  ),
                  const PrayerGuidanceSection(),
                ],
              ),
            ),
          ),
        ),
      );
      for (final name in PrayerName.values) {
        expect(find.byKey(Key('prayer_time_${name.wireName}')), findsOneWidget);
      }
      expect(find.byKey(const Key('prayer_guidance_section')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
