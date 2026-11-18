import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/features/today/presentation/widgets/prayer_track_hub.dart';
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_coming_soon_page.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_shell.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_sidebar.dart';
import 'package:namma_project/features/today/presentation/widgets/today_quick_hubs.dart';

/// T049: the entries to the real Qiyam screen (Home quick hub, Track hub
/// tile, sidebar item) and the Qiyam section's Track highlight. An entry that
/// is not wired keeps its "coming soon" behavior.
void main() {
  Widget app(Widget home) => MaterialApp(
    localizationsDelegates: FoundationLocalizations.localizationsDelegates,
    supportedLocales: FoundationLocalizations.supportedLocales,
    home: home,
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  void desktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Home quick hub', () {
    testWidgets('the Qiyam hub opens the screen when wired', (tester) async {
      phone(tester);
      var opened = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: TodayQuickHubs(
                colors: AppColors.light,
                onQiyam: () => opened++,
              ),
            ),
          ),
        ),
      );
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayQuickHubs)),
      );
      await tester.tap(find.text(copy.dashboardComingSoonQiyamTitle));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(find.byType(TodayComingSoonPage), findsNothing);
    });

    testWidgets('wiring Qiyam leaves the Adhkar hub on its own entry', (
      tester,
    ) async {
      phone(tester);
      var adhkar = 0;
      var qiyam = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: TodayQuickHubs(
                colors: AppColors.light,
                onAdhkar: () => adhkar++,
                onQiyam: () => qiyam++,
              ),
            ),
          ),
        ),
      );
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayQuickHubs)),
      );
      await tester.tap(find.text(copy.dashboardComingSoonAdhkarTitle));
      await tester.pumpAndSettle();
      expect((adhkar, qiyam), (1, 0));
    });

    testWidgets('unwired, the Qiyam hub still opens the coming-soon page', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: TodayQuickHubs(colors: AppColors.light),
            ),
          ),
        ),
      );
      final copy = FoundationLocalizations.of(
        tester.element(find.byType(TodayQuickHubs)),
      );
      await tester.tap(find.text(copy.dashboardComingSoonQiyamTitle));
      await tester.pumpAndSettle();
      expect(find.byType(TodayComingSoonPage), findsOneWidget);
    });
  });

  group('Track hub tile', () {
    testWidgets('the Qiyam tile is active when wired; Focus and Quran stay '
        'locked', (tester) async {
      phone(tester);
      var opened = 0;
      await tester.pumpWidget(
        app(PrayerTrackHub(onPrayer: () {}, onQiyam: () => opened++)),
      );
      await tester.tap(find.byKey(const Key('prayer_track_4')));
      await tester.pump();
      expect(opened, 1);
      final qiyam = tester.widget<ListTile>(
        find.byKey(const Key('prayer_track_4')),
      );
      expect(qiyam.subtitle, isNull);
      expect((qiyam.trailing! as Icon).icon, Icons.chevron_right);
      for (final locked in const [1, 2, 3]) {
        expect(
          tester
              .widget<ListTile>(find.byKey(Key('prayer_track_$locked')))
              .onTap,
          isNull,
          reason: 'Focus, Quran and (unwired) Adhkar stay coming soon',
        );
      }
    });

    testWidgets('unwired, the Qiyam tile stays coming soon', (tester) async {
      phone(tester);
      await tester.pumpWidget(app(PrayerTrackHub(onPrayer: () {})));
      final qiyam = tester.widget<ListTile>(
        find.byKey(const Key('prayer_track_4')),
      );
      expect(qiyam.onTap, isNull);
      expect(qiyam.subtitle, isNotNull);
    });
  });

  group('Qiyam section in the navigation shell', () {
    Widget shell({
      required TodayNavigationSection section,
      VoidCallback? onQiyam,
    }) => app(
      TodayNavigationShell(
        colors: AppColors.light,
        section: section,
        onHome: () {},
        onTasks: () {},
        onHabits: () {},
        onMindMaps: () {},
        onPrayer: () {},
        onAdhkar: () {},
        onQiyam: onQiyam,
        onPreferences: () {},
        child: const Scaffold(body: Center(child: Text('qiyam page'))),
      ),
    );

    testWidgets('the phone bottom bar highlights Track', (tester) async {
      phone(tester);
      await tester.pumpWidget(
        shell(section: TodayNavigationSection.qiyam, onQiyam: () {}),
      );
      expect(
        tester
            .widget<NavigationBar>(find.byKey(kTodayBottomNavigationKey))
            .selectedIndex,
        2,
      );
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('the desktop sidebar selects Qiyam, not Adhkar, and opens it', (
      tester,
    ) async {
      desktop(tester);
      var opened = 0;
      await tester.pumpWidget(
        shell(section: TodayNavigationSection.qiyam, onQiyam: () => opened++),
      );
      final qiyam = tester.widget<ListTile>(find.byKey(kTodaySidebarQiyamKey));
      final adhkar = tester.widget<ListTile>(
        find.byKey(kTodaySidebarAdhkarKey),
      );
      expect(qiyam.tileColor, AppColors.light.secondary);
      expect(adhkar.tileColor, isNot(AppColors.light.secondary));
      expect(
        find.descendant(
          of: find.byKey(kTodaySidebarQiyamKey),
          matching: find.byIcon(Icons.lock_clock_outlined),
        ),
        findsNothing,
        reason: 'a wired item is not shown as coming soon',
      );
      await tester.tap(find.byKey(kTodaySidebarQiyamKey));
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('the Track overlay opens Qiyam and closes itself first', (
      tester,
    ) async {
      phone(tester);
      var opened = 0;
      await tester.pumpWidget(
        shell(section: TodayNavigationSection.home, onQiyam: () => opened++),
      );
      await tester.tap(find.byKey(kTodayBottomTrackKey));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('prayer_track_4')), findsOneWidget);
      await tester.tap(find.byKey(const Key('prayer_track_4')));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(find.byKey(const Key('prayer_track_4')), findsNothing);
    });

    testWidgets('leaving from the sidebar while on Qiyam goes to the other '
        'section', (tester) async {
      desktop(tester);
      var tasks = 0;
      await tester.pumpWidget(
        app(
          TodayNavigationShell(
            colors: AppColors.light,
            section: TodayNavigationSection.qiyam,
            onHome: () {},
            onTasks: () => tasks++,
            onHabits: () {},
            onMindMaps: () {},
            onPrayer: () {},
            onQiyam: () {},
            onPreferences: () {},
            child: const Scaffold(body: Text('qiyam page')),
          ),
        ),
      );
      await tester.tap(find.byKey(kTodaySidebarTasksKey));
      await tester.pump();
      expect(tasks, 1);
    });

    testWidgets('unwired, the sidebar Qiyam item is the coming-soon preview', (
      tester,
    ) async {
      desktop(tester);
      await tester.pumpWidget(shell(section: TodayNavigationSection.home));
      await tester.tap(find.byKey(kTodaySidebarQiyamKey));
      await tester.pumpAndSettle();
      expect(find.byType(TodayComingSoonPage), findsOneWidget);
    });
  });
}
