import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_supplementary_times.dart';

void main() {
  for (final width in [320.0, 768.0]) {
    testWidgets('supplementary times adapt at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PrayerSupplementaryTimes(
                timeZoneId: 'UTC',
                sunriseUtc: DateTime.utc(2026, 11, 1, 6),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('prayer_supplementary_0')), findsOneWidget);
      expect(find.byKey(const Key('prayer_supplementary_1')), findsOneWidget);
      expect(find.byKey(const Key('prayer_supplementary_2')), findsOneWidget);
      expect(
        find.text('Time unavailable for this location and date'),
        findsNWidgets(2),
      );
      final first = tester.getTopLeft(
        find.byKey(const Key('prayer_supplementary_0')),
      );
      final second = tester.getTopLeft(
        find.byKey(const Key('prayer_supplementary_1')),
      );
      expect(
        width == 320 ? second.dy > first.dy : second.dy == first.dy,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
