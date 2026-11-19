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

/// T035: the entries to the real Adhkar screen (Home quick hub, Track hub
/// tile, sidebar item) and the Adhkar section's Track highlight. An entry
/// that is not wired keeps its "coming soon" behavior.
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
    testWidgets('the Adhkar hub opens the screen when wired', (tester) async {
      phone(tester);
      var opened = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: TodayQuickHubs(
                colors: AppColors.light,
                onAdhkar: () => opened++,
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
      expect(opened, 1);
      expect(find.byType(TodayComingSoonPage), findsNothing);
    });

    testWidgets('unwired, the Adhkar hub still opens the coming-soon page', (
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
      await tester.tap(find.text(copy.dashboardComingSoonAdhkarTitle));
      await tester.pumpAndSettle();
      expect(find.byType(TodayComingSoonPage), findsOneWidget);
    });
  });

  group('Track hub tile', () {
    testWidgets('the Adhkar tile is active when wired; the rest stay locked', (
      tester,
    ) async {
      phone(tester);
      var opened = 0;
      await tester.pumpWidget(
        app(PrayerTrackHub(onPrayer: () {}, onAdhkar: () => opened++)),
      );
      await tester.tap(find.byKey(const Key('prayer_track_3')));
      await tester.pump();
      expect(opened, 1);
      final adhkar = tester.widget<ListTile>(
        find.byKey(const Key('prayer_track_3')),
      );
      expect(adhkar.subtitle, isNull);
      expect((adhkar.trailing! as Icon).icon, Icons.chevron_right);
      for (final locked in const [1, 2, 4]) {
        expect(
          tester
              .widget<ListTile>(find.byKey(Key('prayer_track_$locked')))
              .onTap,
          isNull,
          reason: 'Focus, Quran and Qiyam stay coming soon',
        );
      }
    });

    testWidgets('unwired, the Adhkar tile stays coming soon', (tester) async {
      phone(tester);
      await tester.pumpWidget(app(PrayerTrackHub(onPrayer: () {})));
      final adhkar = tester.widget<ListTile>(
        find.byKey(const Key('prayer_track_3')),
      );
      expect(adhkar.onTap, isNull);
      expect(adhkar.subtitle, isNotNull);
    });
  });

  group('Adhkar section in the navigation shell', () {
    Widget shell({
      required TodayNavigationSection section,
      VoidCallback? onAdhkar,
    }) => app(
      TodayNavigationShell(
        colors: AppColors.light,
        section: section,
        onHome: () {},
        onTasks: () {},
        onHabits: () {},
        onMindMaps: () {},
        onPrayer: () {},
        onAdhkar: onAdhkar,
        onPreferences: () {},
        child: const Scaffold(body: Center(child: Text('adhkar page'))),
      ),
    );

    testWidgets('the phone bottom bar highlights Track', (tester) async {
      phone(tester);
      await tester.pumpWidget(
        shell(section: TodayNavigationSection.adhkar, onAdhkar: () {}),
      );
      expect(
        tester
            .widget<NavigationBar>(find.byKey(kTodayBottomNavigationKey))
            .selectedIndex,
        2,
      );
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('the desktop sidebar marks the Adhkar item and opens it', (
      tester,
    ) async {
      desktop(tester);
      var opened = 0;
      await tester.pumpWidget(
        shell(section: TodayNavigationSection.adhkar, onAdhkar: () => opened++),
      );
      final tile = tester.widget<ListTile>(find.byKey(kTodaySidebarAdhkarKey));
      expect(tile.tileColor, AppColors.light.secondary);
      expect(
        find.descendant(
          of: find.byKey(kTodaySidebarAdhkarKey),
          matching: find.byIcon(Icons.lock_clock_outlined),
        ),
        findsNothing,
        reason: 'a wired item is not shown as coming soon',
      );
      await tester.tap(find.byKey(kTodaySidebarAdhkarKey));
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('the Track overlay opens Adhkar and closes itself first', (
      tester,
    ) async {
      phone(tester);
      var opened = 0;
      await tester.pumpWidget(
        shell(section: TodayNavigationSection.home, onAdhkar: () => opened++),
      );
      await tester.tap(find.byKey(kTodayBottomTrackKey));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('prayer_track_3')), findsOneWidget);
      await tester.tap(find.byKey(const Key('prayer_track_3')));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(find.byKey(const Key('prayer_track_3')), findsNothing);
    });

    testWidgets('unwired, the sidebar Adhkar item is the coming-soon preview', (
      tester,
    ) async {
      desktop(tester);
      await tester.pumpWidget(shell(section: TodayNavigationSection.home));
      await tester.tap(find.byKey(kTodaySidebarAdhkarKey));
      await tester.pumpAndSettle();
      expect(find.byType(TodayComingSoonPage), findsOneWidget);
    });
  });
}
