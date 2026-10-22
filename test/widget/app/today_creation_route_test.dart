import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/app/routing/owner_entry_intent.dart';

void main() {
  testWidgets('owner route carries only a validated one-shot entry intent', (
    tester,
  ) async {
    OwnerEntryIntent? seen;
    final routing = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('Today')),
      cloudSession: const TasksPreviewSession(),
      tasksBuilder: (context, accountId) => Builder(
        builder: (childContext) {
          seen = OwnerEntryIntentScope.maybeOf(childContext);
          return Scaffold(body: Text('Tasks $accountId'));
        },
      ),
    );
    addTearDown(routing.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: routing.router,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
      ),
    );
    routing.router.go(kTasksRoute, extra: OwnerEntryIntent.newTask);
    await tester.pumpAndSettle();
    expect(find.textContaining('Tasks '), findsOneWidget);
    expect(seen, OwnerEntryIntent.newTask);

    routing.router.go(kFoundationRootRoute);
    await tester.pumpAndSettle();
    routing.router.go(
      kTasksRoute,
      extra: <String, Object>{'accountId': 'other'},
    );
    await tester.pumpAndSettle();
    expect(seen, isNull);
  });
}
