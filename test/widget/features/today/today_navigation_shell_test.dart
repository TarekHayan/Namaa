import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_shell.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_sidebar.dart';

void main() {
  Widget navigation({required TodayNavigationSection initialSection}) {
    var section = initialSection;
    return MaterialApp(
      localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      supportedLocales: FoundationLocalizations.supportedLocales,
      home: StatefulBuilder(
        builder: (context, setState) {
          void show(TodayNavigationSection next) =>
              setState(() => section = next);
          return TodayNavigationShell(
            colors: AppColors.dark,
            section: section,
            onHome: () => show(TodayNavigationSection.home),
            onTasks: () => show(TodayNavigationSection.tasks),
            onHabits: () => show(TodayNavigationSection.habits),
            onMindMaps: () => show(TodayNavigationSection.mindMaps),
            onPreferences: () {},
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(section.name),
                    Builder(
                      builder: (contentContext) => TextButton(
                        onPressed: () => TodayNavigationShell.openPreview(
                          contentContext,
                          title: 'Preview',
                          colors: AppColors.dark,
                        ),
                        child: const Text('Open preview'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  testWidgets('wide destinations retain one sidebar and highlight the page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      navigation(initialSection: TodayNavigationSection.home),
    );
    expect(find.byKey(kTodaySidebarKey), findsOneWidget);
    expect(find.byKey(kTodayBottomNavigationKey), findsNothing);

    for (final (key, section) in [
      (kTodaySidebarTasksKey, TodayNavigationSection.tasks),
      (kTodaySidebarHabitsKey, TodayNavigationSection.habits),
      (kTodaySidebarMindMapsKey, TodayNavigationSection.mindMaps),
    ]) {
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.byKey(kTodaySidebarKey), findsOneWidget);
      expect(find.text(section.name), findsOneWidget);
      expect(
        tester.widget<ListTile>(find.byKey(key)).tileColor,
        AppColors.dark.secondary,
      );
    }
  });

  testWidgets('preview pages keep the same desktop navigation', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      navigation(initialSection: TodayNavigationSection.home),
    );
    await tester.tap(find.byKey(kTodaySidebarTrackKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kTodaySidebarKey), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('content previews keep the sidebar too', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      navigation(initialSection: TodayNavigationSection.home),
    );
    await tester.tap(find.text('Open preview'));
    await tester.pumpAndSettle();
    expect(find.byKey(kTodaySidebarKey), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
  });

  testWidgets('phone uses the five destination bottom bar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      navigation(initialSection: TodayNavigationSection.tasks),
    );
    expect(find.byKey(kTodaySidebarKey), findsNothing);
    expect(find.byKey(kTodayBottomNavigationKey), findsOneWidget);
    expect(
      tester
          .widget<NavigationBar>(find.byKey(kTodayBottomNavigationKey))
          .selectedIndex,
      1,
    );
  });
}
