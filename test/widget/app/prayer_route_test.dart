import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/prayer_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/routing/app_router.dart';

import '../../support/mind_maps_test_support.dart';

void main() {
  testWidgets('preview opens Prayer with the persisted preview owner', (
    tester,
  ) async {
    final router = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('root')),
      prayerSession: const PrayerPreviewSession(),
      prayerBuilder: (_, owner) => Scaffold(body: Text(owner)),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        routerConfig: router.router,
      ),
    );
    router.go(kPrayerRoute);
    await tester.pumpAndSettle();
    expect(find.text(kPrayerPreviewAccountId), findsOneWidget);
  });

  testWidgets('sign-out removes the account Prayer route content', (
    tester,
  ) async {
    final session = MindMapsTestSession();
    final router = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('root')),
      prayerSession: session,
      prayerBuilder: (_, owner) => Scaffold(body: Text('Prayer $owner')),
    );
    addTearDown(() async {
      router.dispose();
      await session.dispose();
    });
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        routerConfig: router.router,
      ),
    );
    router.go(kPrayerRoute);
    await tester.pumpAndSettle();
    expect(find.text('Prayer $kMindMapsTestAccountA'), findsOneWidget);
    session.signOut();
    await tester.pumpAndSettle();
    expect(find.byKey(kPrayerRouteSignedOutKey), findsOneWidget);
    expect(find.text('Prayer $kMindMapsTestAccountA'), findsNothing);
  });
}
