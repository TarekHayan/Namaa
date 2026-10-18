import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

void main() {
  testWidgets(
    'unresolved and switching session never shows stale Habit owner',
    (tester) async {
      final session = _SwitchableSession();
      final appRouter = FoundationAppRouter(
        rootBuilder: (_) => const Scaffold(body: Text('root')),
        habitsSession: session,
        habitsBuilder: (_, accountId) => Scaffold(body: Text(accountId)),
      );
      addTearDown(() async {
        appRouter.dispose();
        await session.close();
      });
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          supportedLocales: FoundationLocalizations.supportedLocales,
          routerConfig: appRouter.router,
        ),
      );
      appRouter.go(kHabitsRoute);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(kHabitsRouteLoadingKey), findsOneWidget);
      session.emit(
        const CloudSessionSnapshot(
          status: CloudSessionStatus.signedIn,
          accountId: kHabitsPreviewAccountId,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(kHabitsPreviewAccountId), findsOneWidget);
      session.emit(
        const CloudSessionSnapshot(status: CloudSessionStatus.signedOut),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(kHabitsRouteSignedOutKey), findsOneWidget);
      session.initial.complete(
        const AppResult.success(
          CloudSyncContext(accountId: kHabitsPreviewAccountId),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(kHabitsRouteSignedOutKey), findsOneWidget);
    },
  );
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

  testWidgets('unknown initial session settles to signed out', (tester) async {
    final appRouter = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('root')),
      habitsSession: const _UnknownSession(),
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
    expect(find.byKey(kHabitsRouteSignedOutKey), findsOneWidget);
    expect(find.byKey(kHabitsRouteLoadingKey), findsNothing);
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

final class _SwitchableSession implements CloudSessionPort {
  final initial = Completer<AppResult<CloudSyncContext>>();
  final _changes = StreamController<CloudSessionSnapshot>.broadcast(sync: true);
  void emit(CloudSessionSnapshot snapshot) => _changes.add(snapshot);
  Future<void> close() => _changes.close();
  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);
  @override
  Stream<CloudSessionSnapshot> observeSession() => _changes.stream;
  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() => initial.future;
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

final class _UnknownSession implements CloudSessionPort {
  const _UnknownSession();

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.value(
    const CloudSessionSnapshot(status: CloudSessionStatus.unknown),
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
