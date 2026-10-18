import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/routing/app_router.dart';

import '../../support/mind_maps_test_support.dart';

void main() {
  testWidgets('Tasks preview identity opens Mind Maps without sign-in', (
    tester,
  ) async {
    final router = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('root')),
      mindMapsSession: const TasksPreviewSession(),
      mindMapsBuilder: (_, owner) => Scaffold(body: Text(owner)),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        routerConfig: router.router,
      ),
    );
    router.go(kMindMapsRoute);
    await tester.pumpAndSettle();
    expect(find.text(kTasksPreviewAccountId), findsOneWidget);
  });

  testWidgets('signed-out route does not build private maps', (tester) async {
    final session = MindMapsTestSession(initialAccountId: null);
    var builds = 0;
    final router = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('root')),
      mindMapsSession: session,
      mindMapsBuilder: (_, owner) {
        builds++;
        return Scaffold(body: Text(owner));
      },
    );
    addTearDown(() async {
      router.dispose();
      await session.dispose();
    });
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ar'),
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        routerConfig: router.router,
      ),
    );
    router.go(kMindMapsRoute);
    await tester.pumpAndSettle();
    expect(find.byKey(kMindMapsRouteSignedOutKey), findsOneWidget);
    expect(find.text('سجّل الدخول للوصول إلى خرائطك الذهنية.'), findsOneWidget);
    expect(builds, 0);
  });
}
