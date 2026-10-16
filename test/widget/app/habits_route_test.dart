import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

void main() {
  testWidgets('signed-out Habits route never builds account data', (
    tester,
  ) async {
    var builds = 0;
    final appRouter = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('root')),
      habitsSession: const _SignedOutSession(),
      habitsBuilder: (_, accountId) {
        builds++;
        return Scaffold(body: Text(accountId));
      },
    );
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        routerConfig: appRouter.router,
      ),
    );
    appRouter.go(kHabitsRoute);
    await tester.pumpAndSettle();
    expect(find.byKey(kHabitsRouteSignedOutKey), findsOneWidget);
    expect(builds, 0);
  });

  testWidgets('preview Habits route resolves its isolated account', (
    tester,
  ) async {
    final appRouter = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('root')),
      habitsSession: const HabitsPreviewSession(),
      habitsBuilder: (_, accountId) => Scaffold(body: Text(accountId)),
    );
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        routerConfig: appRouter.router,
      ),
    );
    appRouter.go(kHabitsRoute);
    await tester.pumpAndSettle();
    expect(find.text(kHabitsPreviewAccountId), findsOneWidget);
  });
}

final class _SignedOutSession implements CloudSessionPort {
  const _SignedOutSession();

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.value(
    const CloudSessionSnapshot(status: CloudSessionStatus.signedOut),
  );

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.authorization,
          messageKey: 'habits.error.account',
          occurredAt: DateTime.utc(2026, 10, 12),
        ),
      );
}
