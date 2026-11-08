import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/today_localization_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/today/domain/today_prayer_reference.dart';
import 'package:namma_project/features/today/domain/today_section.dart';
import 'package:namma_project/features/today/presentation/widgets/today_coming_soon_page.dart';
import 'package:namma_project/features/today/presentation/widgets/today_counters_card.dart';
import 'package:namma_project/features/today/presentation/widgets/today_finance_card.dart';
import 'package:namma_project/features/today/presentation/widgets/today_prayer_card.dart';
import 'package:namma_project/features/today/presentation/widgets/today_quran_card.dart';

void main() {
  final prayer = TodaySection.available(
    TodayPrayerReference(
      ownerId: 'preview',
      city: 'Cairo',
      timeZoneId: 'Africa/Cairo',
      localDate: '2026-03-20',
      nextName: PrayerName.asr,
      nextUtc: DateTime.utc(2026, 3, 20, 13, 30),
      followingName: PrayerName.maghrib,
      followingUtc: DateTime.utc(2026, 3, 20, 16, 10),
      nowUtc: DateTime.utc(2026, 3, 20, 13),
    ),
  );
  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'sample dashboard cards fit narrow $locale $brightness at 1.5x text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 2400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final colors = brightness == Brightness.dark
              ? AppColors.dark
              : AppColors.light;

          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              supportedLocales: FoundationLocalizations.supportedLocales,
              localizationsDelegates:
                  FoundationLocalizations.localizationsDelegates,
              theme: ThemeData(brightness: brightness),
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 2400),
                  textScaler: TextScaler.linear(1.5),
                ),
                child: Scaffold(
                  body: Builder(
                    builder: (context) {
                      final strings = resolveTodayStrings(context);
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            TodayPrayerCard(colors: colors, prayer: prayer),
                            TodayQuranCard(colors: colors),
                            TodayFinanceCard(colors: colors),
                            TodayCountersCard(colors: colors, strings: strings),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          final copy = FoundationLocalizations.of(
            tester.element(find.byType(TodayPrayerCard)),
          );
          expect(find.text(copy.dashboardSampleBadge), findsNWidgets(4));
          expect(find.text('Cairo'), findsOneWidget);
        },
      );
    }
  }

  testWidgets(
    'future-domain cards render sample badges and accessible semantics',
    (tester) async {
      final colors = AppColors.light;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final strings = resolveTodayStrings(context);
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      TodayPrayerCard(colors: colors, prayer: prayer),
                      TodayQuranCard(colors: colors),
                      TodayFinanceCard(colors: colors),
                      TodayCountersCard(colors: colors, strings: strings),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayPrayerCard)),
      );

      // Prayer is real; only the other preview sections carry sample badges.
      expect(find.text(copy.dashboardSampleBadge), findsNWidgets(4));

      // Verify accessible semantics containing dashboardSampleValue
      final sampleSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains(copy.dashboardSampleValue),
      );
      // Quran title/progress, Finance 2 tiles, Counters tiles.
      expect(sampleSemantics, findsAtLeastNWidgets(3));
    },
  );

  testWidgets(
    'interactive controls on preview cards route to TodayComingSoonPage or show preview notice without mutating state',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final colors = AppColors.light;
      var prayerOpens = 0;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final strings = resolveTodayStrings(context);
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      TodayPrayerCard(
                        colors: colors,
                        prayer: prayer,
                        onTap: () => prayerOpens++,
                      ),
                      TodayQuranCard(colors: colors),
                      TodayFinanceCard(colors: colors),
                      TodayCountersCard(colors: colors, strings: strings),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayPrayerCard)),
      );
      final strings = resolveTodayStrings(
        tester.element(find.byType(TodayPrayerCard)),
      );

      // 1. Tap Prayer Card -> invokes the real Prayer destination.
      await tester.ensureVisible(find.byType(TodayPrayerCard));
      await tester.tap(find.byType(TodayPrayerCard));
      await tester.pumpAndSettle();
      expect(prayerOpens, 1);
      expect(find.byType(TodayComingSoonPage), findsNothing);

      // 2. Tap Quran Card action -> Navigates to TodayComingSoonPage (Quran)
      await tester.ensureVisible(find.text(copy.dashboardQuranContinueReading));
      await tester.tap(find.text(copy.dashboardQuranContinueReading));
      await tester.pumpAndSettle();
      expect(find.byType(TodayComingSoonPage), findsOneWidget);
      expect(find.text(copy.dashboardComingSoonQuranTitle), findsOneWidget);

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TodayComingSoonPage), findsNothing);

      // 3. Tap Finance Card action -> Navigates to TodayComingSoonPage (Finance)
      await tester.ensureVisible(
        find.text(copy.dashboardComingSoonFinanceTitle).first,
      );
      await tester.tap(find.text(copy.dashboardComingSoonFinanceTitle).first);
      await tester.pumpAndSettle();
      expect(find.byType(TodayComingSoonPage), findsOneWidget);
      expect(find.text(copy.dashboardComingSoonFinanceTitle), findsWidgets);

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TodayComingSoonPage), findsNothing);

      // 4. Tap Counters Card Show More -> Navigates to TodayComingSoonPage (Counters)
      await tester.ensureVisible(find.text(strings.showMore));
      await tester.tap(find.text(strings.showMore));
      await tester.pumpAndSettle();
      expect(find.byType(TodayComingSoonPage), findsOneWidget);
      expect(find.text(copy.dashboardComingSoonCountersTitle), findsOneWidget);

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TodayComingSoonPage), findsNothing);

      // 5. Counter increment is a preview destination, not a saved increment.
      final increment = find.byKey(const ValueKey('counter_increment_0'));
      await tester.ensureVisible(increment);
      await tester.tap(increment);
      await tester.pumpAndSettle();
      expect(find.byType(TodayComingSoonPage), findsOneWidget);
      expect(find.text(copy.dashboardComingSoonCountersTitle), findsOneWidget);
    },
  );
}
