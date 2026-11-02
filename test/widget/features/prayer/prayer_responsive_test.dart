import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_guidance_section.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_header.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_schedule_list.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_supplementary_times.dart';

void main() {
  for (final width in [320.0, 390.0, 430.0, 768.0, 1200.0]) {
    for (final locale in [const Locale('ar'), const Locale('en')]) {
      for (final brightness in Brightness.values) {
        for (final scale in [1.0, 1.5]) {
          testWidgets('$width $locale $brightness text $scale', (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            tester.view.padding = const FakeViewPadding(top: 38, bottom: 22);
            tester.view.viewPadding = const FakeViewPadding(
              top: 38,
              bottom: 22,
            );
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPadding);
            addTearDown(tester.view.resetViewPadding);
            final city = locale.languageCode == 'ar'
                ? 'مدينة طويلة الاسم لاختبار التفاف النصوص في واجهة الصلاة عند تكبير الخط'
                : 'A very long location name that must wrap on a narrow prayer screen';
            await tester.pumpWidget(
              MaterialApp(
                locale: locale,
                theme: ThemeData(brightness: brightness),
                supportedLocales: FoundationLocalizations.supportedLocales,
                localizationsDelegates:
                    FoundationLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: SafeArea(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            PrayerHeader(
                              city: city,
                              details: 'Africa/Cairo · Egyptian',
                              completedCount: 2,
                              actions: [],
                            ),
                            PrayerScheduleList(
                              schedule: null,
                              timeZoneId: 'UTC',
                              reports: const [],
                              actions: const {},
                              onStatusChanged: (_, _) {},
                            ),
                            const PrayerSupplementaryTimes(timeZoneId: 'UTC'),
                            const PrayerGuidanceSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            expect(
              tester.getTopLeft(find.byType(PrayerHeader)).dy,
              greaterThanOrEqualTo(38),
            );
            final cityText = tester.widget<Text>(find.text(city));
            expect(cityText.maxLines, isNull);
            expect(cityText.overflow, isNull);
            final copy = FoundationLocalizations.of(
              tester.element(find.byType(PrayerGuidanceSection)),
            );
            for (final guidance in [
              copy.prayerJahrDefinition,
              copy.prayerSirrDefinition,
            ]) {
              final text = tester.widget<Text>(find.text(guidance));
              expect(text.maxLines, isNull);
              expect(text.overflow, isNull);
            }
            for (final name in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
              for (final status in [
                'completed_on_time',
                'completed_late',
                'missed',
              ]) {
                final action = find.byKey(Key('prayer_status_${name}_$status'));
                final size = tester.getSize(action);
                expect(size.width, greaterThanOrEqualTo(48));
                expect(size.height, greaterThanOrEqualTo(48));
                final paragraphs = find.descendant(
                  of: action,
                  matching: find.byType(RichText),
                );
                for (final element in paragraphs.evaluate()) {
                  final render = element.renderObject;
                  if (render is RenderParagraph) {
                    expect(render.didExceedMaxLines, isFalse);
                  }
                }
              }
            }
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}
