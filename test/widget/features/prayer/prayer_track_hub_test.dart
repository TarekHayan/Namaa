import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/prayer/presentation/prayer_track_hub.dart';

void main() {
  testWidgets('track opens prayer and labels other entries coming soon', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(body: PrayerTrackHub(onPrayer: () => opened++)),
      ),
    );
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(Key('prayer_track_$i')), findsOneWidget);
    }
    expect(find.text('Coming soon'), findsNWidgets(4));
    await tester.tap(find.byKey(const Key('prayer_track_0')));
    expect(opened, 1);
    await tester.tap(find.byKey(const Key('prayer_track_1')));
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });
}
