import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';
import 'package:namma_project/features/prayer/presentation/prayer_state.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_header.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_status_actions.dart';

void main() {
  testWidgets('keyboard can reach all five prayer choices and reset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final changes = <(PrayerName, PrayerStatus)>[];
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (final name in PrayerName.values)
                  PrayerStatusActions(
                    name: name,
                    status: name == PrayerName.fajr
                        ? PrayerStatus.completedOnTime
                        : PrayerStatus.pending,
                    phase: PrayerActionPhase.idle,
                    onChanged: (status) => changes.add((name, status)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final reached = <String>{};
    for (var i = 0; i < 24; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focus = FocusManager.instance.primaryFocus?.context;
      if (focus == null || !focus.mounted) continue;
      final button = focus.findAncestorWidgetOfExactType<AppButton>();
      if (button?.key is ValueKey<String>) {
        reached.add((button!.key! as ValueKey<String>).value);
      }
    }
    for (final name in PrayerName.values) {
      for (final value in [
        PrayerStatus.completedOnTime,
        PrayerStatus.completedLate,
        PrayerStatus.missed,
      ]) {
        // The currently selected action is intentionally disabled and does
        // not take a keyboard stop.
        if (name == PrayerName.fajr && value == PrayerStatus.completedOnTime) {
          continue;
        }
        expect(
          reached,
          contains('prayer_status_${name.wireName}_${value.wireName}'),
        );
      }
    }
    expect(reached, contains('prayer_status_fajr_pending'));

    final reset = find.byKey(const Key('prayer_status_fajr_pending'));
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    expect(changes, [(PrayerName.fajr, PrayerStatus.pending)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected status has a non-color label; streak is not live', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Column(
            children: [
              const PrayerHeader(
                city: 'Cairo',
                details: 'Africa/Cairo',
                completedCount: 1,
                actions: [],
              ),
              PrayerStatusActions(
                name: PrayerName.fajr,
                status: PrayerStatus.completedOnTime,
                phase: PrayerActionPhase.saved,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    final copy = FoundationLocalizations.of(
      tester.element(find.byType(PrayerHeader)),
    );
    expect(
      find.bySemanticsLabel(copy.prayerStatusSelected(copy.prayerStatusOnTime)),
      findsOneWidget,
    );
    expect(find.text(copy.prayerStreakSoon), findsOneWidget);
    final streak = find.text(copy.prayerStreakSoon);
    final ancestors = tester.widgetList<Semantics>(
      find.ancestor(of: streak, matching: find.byType(Semantics)),
    );
    expect(
      ancestors.every((widget) => widget.properties.liveRegion != true),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
