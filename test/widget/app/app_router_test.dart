import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

final class _CloudSessionFake implements CloudSessionPort {
  _CloudSessionFake(this.accountId);

  final String? accountId;

  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async {
    final id = accountId;
    if (id != null) {
      return AppResult<CloudSyncContext>.success(
        CloudSyncContext(accountId: id),
      );
    }
    return AppResult<CloudSyncContext>.failure(
      AppFailure.blocking(
        category: AppFailureCategory.authorization,
        messageKey: 'tasks.auth.sign_in_required',
        occurredAt: DateTime.utc(2026),
      ),
    );
  }

  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.value(
    CloudSessionSnapshot(
      status: accountId == null
          ? CloudSessionStatus.signedOut
          : CloudSessionStatus.signedIn,
      accountId: accountId,
    ),
  );
}

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

  testWidgets('the Tasks route does not build account data while signed out', (
    tester,
  ) async {
    var buildCount = 0;
    final appRouter = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('foundation root')),
      cloudSession: _CloudSessionFake(null),
      tasksBuilder: (_, accountId) {
        buildCount += 1;
        return Scaffold(body: Text(accountId));
      },
    );
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: appRouter.router,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      ),
    );
    appRouter.go(kTasksRoute);
    await tester.pumpAndSettle();

    expect(find.byKey(kTasksRouteSignedOutKey), findsOneWidget);
    expect(find.text('Sign in to access your tasks.'), findsOneWidget);
    expect(buildCount, 0);
  });

  testWidgets('the Tasks route supplies only the resolved account identity', (
    tester,
  ) async {
    final appRouter = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('foundation root')),
      cloudSession: _CloudSessionFake('account-a'),
      tasksBuilder: (_, accountId) => Scaffold(body: Text(accountId)),
    );
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: appRouter.router,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      ),
    );
    appRouter.go(kTasksRoute);
    await tester.pumpAndSettle();

    expect(find.text('account-a'), findsOneWidget);
    expect(find.byKey(kTasksRouteSignedOutKey), findsNothing);
  });

  testWidgets('local Tasks trial opens the route without sign-in', (
    tester,
  ) async {
    final appRouter = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('foundation root')),
      cloudSession: const TasksPreviewSession(),
      tasksBuilder: (_, accountId) => Scaffold(body: Text(accountId)),
    );
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: appRouter.router,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      ),
    );
    appRouter.go(kTasksRoute);
    await tester.pumpAndSettle();

    expect(find.text(kTasksPreviewAccountId), findsOneWidget);
    expect(find.byKey(kTasksRouteSignedOutKey), findsNothing);
  });
}
