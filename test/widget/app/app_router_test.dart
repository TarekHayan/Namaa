import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/routing/app_router.dart';

void main() {
  testWidgets(
    'the registered root route renders the supplied Foundation shell',
    (tester) async {
      final appRouter = FoundationAppRouter(
        rootBuilder: (_) => const Scaffold(body: Text('foundation root')),
      );
      addTearDown(appRouter.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: appRouter.router,
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
        ),
      );

      expect(find.text('foundation root'), findsOneWidget);
    },
  );

  testWidgets('an unknown route is handled by the Foundation route boundary', (
    tester,
  ) async {
    final appRouter = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('foundation root')),
    );
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: appRouter.router,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      ),
    );
    appRouter.go('/unregistered-feature');
    await tester.pumpAndSettle();

    expect(find.byKey(kFoundationUnknownRouteKey), findsOneWidget);
    expect(find.text('This route is unavailable.'), findsOneWidget);
  });
}
