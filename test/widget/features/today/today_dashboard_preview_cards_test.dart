import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/features/today/presentation/widgets/today_finance_card.dart';
import 'package:namma_project/features/today/presentation/widgets/today_focus_reflection_card.dart';
import 'package:namma_project/features/today/presentation/widgets/today_prayer_card.dart';
import 'package:namma_project/features/today/presentation/widgets/today_quran_card.dart';

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'sample dashboard cards fit narrow $locale $brightness at 1.5x text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 1600);
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
                  size: Size(320, 1600),
                  textScaler: TextScaler.linear(1.5),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        TodayPrayerCard(colors: colors),
                        TodayQuranCard(colors: colors),
                        TodayFinanceCard(colors: colors),
                        TodayFocusReflectionCard(colors: colors),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(
            find.text(
              FoundationLocalizations.of(
                tester.element(find.byType(TodayPrayerCard)),
              ).dashboardSampleBadge,
            ),
            findsNWidgets(4),
          );
        },
      );
    }
  }
}
