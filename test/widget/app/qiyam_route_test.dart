import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/qiyam_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_theme.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_conflict_evidence.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_cubit.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_screen.dart';
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_shell.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_sidebar.dart';

import '../../support/qiyam_test_support.dart';

final class _SignedOut implements CloudSessionPort {
  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      throw UnimplementedError();

  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.value(
    const CloudSessionSnapshot(status: CloudSessionStatus.signedOut),
  );
}

/// T049: `/qiyam` is a top-level sibling route behind the same account gate
/// as `/prayer` and `/adhkar`, inside the real navigation shell. The phone
/// bottom bar highlights Track and the desktop sidebar selects Qiyam; there is
/// no back arrow, and device back closes the topmost layer (the night
/// details, then the sync page) before going Home.
void main() {
  late QiyamHarness h;
  late QiyamCubit cubit;
  late StreamController<List<QiyamConflictEvidence>> conflicts;
  var latestConflicts = const <QiyamConflictEvidence>[];

  /// Like the store's watch: every new listener first gets the current rows.
  Stream<List<QiyamConflictEvidence>> replaying() => Stream.multi((listener) {
    listener.add(latestConflicts);
    final subscription = conflicts.stream.listen(listener.addSync);
    listener.onCancel = subscription.cancel;
  });
  late FoundationAppRouter appRouter;
  var prayerSetups = 0;

  setUp(() {
    h = QiyamHarness();
    h.repository.seeded['2026-11-10'] = qiyamRecord('2026-11-10');
    cubit = h.buildCubit();
    conflicts = StreamController<List<QiyamConflictEvidence>>.broadcast();
    latestConflicts = const [];
    prayerSetups = 0;
  });

  tearDown(() async {
    await QiyamHarness.closeAll();
    await conflicts.close();
  });

  Future<void> pumpApp(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    appRouter = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('home page')),
      qiyamSession: const QiyamPreviewSession(),
      qiyamBuilder: (context, owner) => BlocProvider.value(
        value: cubit,
        child: QiyamScreen(
          conflicts: replaying(),
          shellBuilder: (context, page) => TodayNavigationShell(
            colors: AppColors.light,
            section: TodayNavigationSection.qiyam,
            onHome: () => appRouter.go(kTodayRoute),
            onTasks: () => appRouter.go(kTasksRoute),
            onHabits: () => appRouter.go(kHabitsRoute),
            onMindMaps: () => appRouter.go(kMindMapsRoute),
            onPrayer: () => appRouter.go(kPrayerRoute),
            onQiyam: () {},
            onPreferences: () {},
            child: page,
          ),
          onOpenPrayerSetup: () => prayerSetups++,
        ),
      ),
    );
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: appRouter.router,
        locale: const Locale('en'),
        theme: AppTheme.light,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      ),
    );
    appRouter.go(kQiyamRoute);
    // The tracker shows a spinner until the night loads, so start the load
    // before waiting for the page to settle.
    unawaited(cubit.load());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  String location() =>
      appRouter.router.routerDelegate.currentConfiguration.uri.path;

  Finder key(String value) => find.byKey(Key(value));

  qiyamTestWidgets(
    'go opens the Qiyam page as a sibling, not a stacked route',
    (tester) async {
      await pumpApp(tester, size: const Size(390, 844));
      expect(location(), kQiyamRoute);
      expect(key('qiyam_header'), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator).first).canPop(),
        isFalse,
      );
    },
  );

  qiyamTestWidgets('there is no back arrow, and Track stays highlighted', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(390, 844));
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    expect(
      tester
          .widget<NavigationBar>(find.byKey(kTodayBottomNavigationKey))
          .selectedIndex,
      2,
    );
  });

  qiyamTestWidgets('on desktop the sidebar selects Qiyam', (tester) async {
    await pumpApp(tester, size: const Size(1500, 900));
    expect(
      tester.widget<ListTile>(find.byKey(kTodaySidebarQiyamKey)).tileColor,
      AppColors.light.secondary,
    );
    expect(
      tester.widget<ListTile>(find.byKey(kTodaySidebarAdhkarKey)).tileColor,
      isNot(AppColors.light.secondary),
    );
  });

  qiyamTestWidgets('the setup button reaches the Prayer setup', (tester) async {
    h.nightPort.state = qiyamSetupRequired();
    await pumpApp(tester, size: const Size(390, 844));
    await tester.ensureVisible(key('qiyam_open_prayer_setup'));
    await tester.pump();
    await tester.tap(key('qiyam_open_prayer_setup'));
    expect(prayerSetups, 1);
  });

  qiyamTestWidgets('device back from the page goes Home', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(location(), kTodayRoute);
    expect(find.text('home page'), findsOneWidget);
  });

  qiyamTestWidgets(
    'device back closes the night details first, then goes Home',
    (tester) async {
      await pumpApp(tester, size: const Size(390, 844));
      await tester.ensureVisible(key('qiyam_history_row_2026-11-10'));
      await tester.pump();
      await tester.tap(key('qiyam_history_row_2026-11-10'));
      await tester.pumpAndSettle();
      expect(key('qiyam_night_details'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(key('qiyam_night_details'), findsNothing);
      expect(location(), kQiyamRoute, reason: 'still on the page');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(location(), kTodayRoute);
    },
  );

  qiyamTestWidgets(
    'the sync row opens the read-only page and device back closes '
    'it before going Home',
    (tester) async {
      await pumpApp(tester, size: const Size(390, 844));
      expect(key('qiyam_sync_row'), findsNothing);
      latestConflicts = [
        QiyamConflictEvidence(
          id: 'c1',
          nightDate: '2026-11-11',
          activePerformed: true,
          retainedPerformed: false,
          activeRakahs: 4,
          retainedRakahs: null,
          activeAt: DateTime.utc(2026, 11, 11, 3, 36),
          retainedAt: DateTime.utc(2026, 11, 11, 3, 12),
          activeWitr: true,
        ),
      ];
      conflicts.add(latestConflicts);
      await tester.pumpAndSettle();
      await tester.ensureVisible(key('qiyam_sync_row'));
      await tester.pump();
      await tester.tap(key('qiyam_sync_row'));
      await tester.pumpAndSettle();
      expect(key('qiyam_sync_page'), findsOneWidget);
      expect(key('qiyam_header'), findsNothing);
      // The shell stays around the page.
      expect(find.byKey(kTodayBottomNavigationKey), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(key('qiyam_sync_page'), findsNothing);
      expect(key('qiyam_header'), findsOneWidget);
      expect(location(), kQiyamRoute);

      // The in-page back link does the same.
      await tester.ensureVisible(key('qiyam_sync_row'));
      await tester.pump();
      await tester.tap(key('qiyam_sync_row'));
      await tester.pumpAndSettle();
      await tester.tap(key('qiyam_sync_back'));
      await tester.pumpAndSettle();
      expect(key('qiyam_header'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(location(), kTodayRoute);
    },
  );

  qiyamTestWidgets('leaving from an open Track overlay closes it first', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(390, 844));
    await tester.tap(find.byKey(kTodayBottomTrackKey));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prayer_track_0')), findsOneWidget);
    await tester.tap(find.byKey(kTodayBottomTasksKey).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prayer_track_0')), findsNothing);
    expect(location(), kTasksRoute);
  });

  qiyamTestWidgets('a signed-out session stays at a localized boundary', (
    tester,
  ) async {
    final signedOut = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('home page')),
      qiyamSession: _SignedOut(),
      qiyamBuilder: (_, owner) => Scaffold(body: Text('Qiyam $owner')),
    );
    addTearDown(signedOut.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: signedOut.router,
        locale: const Locale('en'),
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      ),
    );
    signedOut.go(kQiyamRoute);
    await tester.pumpAndSettle();
    expect(find.byKey(kQiyamRouteSignedOutKey), findsOneWidget);
    expect(find.text('Open Night prayer after signing in.'), findsOneWidget);
    expect(find.textContaining('Qiyam owner'), findsNothing);
  });
}
