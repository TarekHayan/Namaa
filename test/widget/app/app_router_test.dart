import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/adhkar_preview_adapters.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/presentation/my_adhkar_cubit.dart';
import 'package:namma_project/features/adhkar/presentation/widgets/my_adhkar_tab.dart';
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_shell.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_sidebar.dart';

import '../../support/my_adhkar_test_support.dart';

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

  group('Adhkar route (T035)', () {
    late MemoryMyAdhkarStore store;
    late MyAdhkarCubit myAdhkar;
    late FoundationAppRouter appRouter;

    setUp(() {
      store = MemoryMyAdhkarStore();
      store.addGroup('group a', id: 'ga');
      store.addItem(text: 'entry text 1', groupIds: ['ga'], id: 'i1');
      myAdhkar = store.cubit();
    });

    tearDown(() async {
      await myAdhkar.close();
    });

    /// The real navigation shell around the real My Adhkar tab, behind the
    /// `/adhkar` route exactly as the app composes it (the Adhkar and
    /// Prayer-based parts need an encrypted store, so the tab stands in for
    /// the page body: it owns the device-back handling inside the page).
    Future<void> pumpApp(WidgetTester tester, {required Size size}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      appRouter = FoundationAppRouter(
        rootBuilder: (_) => const Scaffold(body: Text('home page')),
        adhkarSession: const AdhkarPreviewSession(),
        adhkarBuilder: (context, owner) => TodayNavigationShell(
          colors: AppColors.light,
          section: TodayNavigationSection.adhkar,
          onHome: () => appRouter.go(kTodayRoute),
          onTasks: () => appRouter.go(kTasksRoute),
          onHabits: () => appRouter.go(kHabitsRoute),
          onMindMaps: () => appRouter.go(kMindMapsRoute),
          onPrayer: () => appRouter.go(kPrayerRoute),
          onAdhkar: () {},
          onPreferences: () {},
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text('owner $owner'),
                    BlocProvider.value(
                      value: myAdhkar,
                      child: const MyAdhkarTab(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      addTearDown(appRouter.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: appRouter.router,
          locale: const Locale('en'),
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
        ),
      );
      appRouter.go(kAdhkarRoute);
      await tester.pumpAndSettle();
    }

    String location() =>
        appRouter.router.routerDelegate.currentConfiguration.uri.path;

    testWidgets('go opens the Adhkar page for the resolved preview owner', (
      tester,
    ) async {
      await pumpApp(tester, size: const Size(390, 844));
      expect(location(), kAdhkarRoute);
      expect(find.text('owner $kAdhkarPreviewAccountId'), findsOneWidget);
      expect(find.byKey(const Key('my_adhkar_tab')), findsOneWidget);
      // A sibling page, not a stacked one: nothing to pop under it.
      expect(
        tester.state<NavigatorState>(find.byType(Navigator).first).canPop(),
        isFalse,
      );
    });

    testWidgets('there is no back arrow, and Track stays highlighted', (
      tester,
    ) async {
      await pumpApp(tester, size: const Size(390, 844));
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(BackButtonIcon), findsNothing);
      expect(
        tester
            .widget<NavigationBar>(find.byKey(kTodayBottomNavigationKey))
            .selectedIndex,
        2,
      );
    });

    testWidgets('device back closes an opened group first, then goes Home', (
      tester,
    ) async {
      await pumpApp(tester, size: const Size(390, 844));
      await tester.tap(find.byKey(const Key('my_adhkar_group_ga')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('my_adhkar_entry_i1')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('my_adhkar_entry_i1')), findsNothing);
      expect(find.byKey(const Key('my_adhkar_group_ga')), findsOneWidget);
      expect(location(), kAdhkarRoute, reason: 'still on the page');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(location(), kTodayRoute);
      expect(find.text('home page'), findsOneWidget);
    });

    testWidgets('device back from the page goes Home', (tester) async {
      await pumpApp(tester, size: const Size(390, 844));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(location(), kTodayRoute);
      expect(find.text('home page'), findsOneWidget);
    });

    testWidgets('leaving from an open Track overlay closes it first', (
      tester,
    ) async {
      await pumpApp(tester, size: const Size(390, 844));
      await tester.tap(find.byKey(kTodayBottomTrackKey));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('prayer_track_0')), findsOneWidget);
      expect(location(), kAdhkarRoute);

      // Tasks from the overlay: the overlay closes, then the route changes.
      await tester.tap(find.byKey(kTodayBottomTasksKey).last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('prayer_track_0')), findsNothing);
      expect(location(), kTasksRoute);
    });

    testWidgets(
      'device back from an open Track overlay closes it and goes Home',
      (tester) async {
        await pumpApp(tester, size: const Size(390, 844));
        await tester.tap(find.byKey(kTodayBottomTrackKey));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('prayer_track_0')), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('prayer_track_0')), findsNothing);
        expect(location(), kTodayRoute);
        expect(find.text('home page'), findsOneWidget);
      },
    );

    testWidgets('a signed-out session stays at a localized boundary', (
      tester,
    ) async {
      final signedOut = FoundationAppRouter(
        rootBuilder: (_) => const Scaffold(body: Text('home page')),
        adhkarSession: _CloudSessionFake(null),
        adhkarBuilder: (_, owner) => Scaffold(body: Text('Adhkar $owner')),
      );
      addTearDown(signedOut.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: signedOut.router,
          locale: const Locale('en'),
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
        ),
      );
      signedOut.go(kAdhkarRoute);
      await tester.pumpAndSettle();
      expect(find.byKey(kAdhkarRouteSignedOutKey), findsOneWidget);
      expect(find.text('Open Adhkar after signing in.'), findsOneWidget);
      expect(find.textContaining('Adhkar owner'), findsNothing);
    });
  });
}
