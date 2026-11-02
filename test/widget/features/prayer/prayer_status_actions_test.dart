import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';
import 'package:namma_project/features/prayer/presentation/prayer_state.dart';
import 'package:namma_project/features/prayer/presentation/widgets/prayer_status_actions.dart';

Widget _app({
  required PrayerStatus status,
  required PrayerActionPhase phase,
  required ValueChanged<PrayerStatus> onChanged,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  locale: locale,
  supportedLocales: FoundationLocalizations.supportedLocales,
  localizationsDelegates: FoundationLocalizations.localizationsDelegates,
  home: Scaffold(
    body: PrayerStatusActions(
      name: PrayerName.fajr,
      status: status,
      phase: phase,
      onChanged: onChanged,
    ),
  ),
);

void main() {
  testWidgets('selected late and missed actions retain distinct colors', (
    tester,
  ) async {
    for (final entry in [
      (PrayerStatus.completedLate, AppColors.light.warning),
      (PrayerStatus.missed, AppColors.light.error),
    ]) {
      await tester.pumpWidget(
        _app(
          status: entry.$1,
          phase: PrayerActionPhase.idle,
          onChanged: (_) {},
        ),
      );
      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(Key('prayer_status_fajr_${entry.$1.wireName}')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(
        button.style!.backgroundColor!.resolve({WidgetState.disabled}),
        entry.$2,
      );
    }
  });
  testWidgets('keyboard can reach actions for each prayer and reset', (
    tester,
  ) async {
    final focusNodes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (final name in PrayerName.values)
                  PrayerStatusActions(
                    name: name,
                    status: PrayerStatus.completedLate,
                    phase: PrayerActionPhase.idle,
                    onChanged: (_) {},
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 24; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext != null) {
        final action = focusContext.findAncestorWidgetOfExactType<AppButton>();
        if (action?.key case final ValueKey<String> key) {
          focusNodes.add(key.value);
        }
      }
    }
    for (final name in PrayerName.values) {
      expect(
        focusNodes,
        contains('prayer_status_${name.wireName}_completed_on_time'),
      );
      expect(focusNodes, contains('prayer_status_${name.wireName}_pending'));
    }
  });
  testWidgets(
    'three explicit choices submit once and selected state is semantic',
    (tester) async {
      final changes = <PrayerStatus>[];
      await tester.pumpWidget(
        _app(
          status: PrayerStatus.pending,
          phase: PrayerActionPhase.idle,
          onChanged: changes.add,
        ),
      );
      expect(find.text('On time'), findsOneWidget);
      expect(find.text('Completed late'), findsOneWidget);
      expect(find.text('Missed'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('prayer_status_fajr_completed_on_time')),
      );
      await tester.pump();
      expect(changes, [PrayerStatus.completedOnTime]);

      await tester.pumpWidget(
        _app(
          status: PrayerStatus.completedOnTime,
          phase: PrayerActionPhase.saved,
          onChanged: changes.add,
        ),
      );
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Saved on this device'), findsOneWidget);
      final semantics = tester.getSemantics(
        find.byKey(const Key('prayer_status_fajr_completed_on_time')),
      );
      expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
    },
  );

  testWidgets('keyboard activation submits exactly once', (tester) async {
    final changes = <PrayerStatus>[];
    await tester.pumpWidget(
      _app(
        status: PrayerStatus.pending,
        phase: PrayerActionPhase.idle,
        onChanged: changes.add,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(changes, hasLength(1));
  });

  testWidgets('failed save remains retryable and is localized in Arabic', (
    tester,
  ) async {
    final changes = <PrayerStatus>[];
    await tester.pumpWidget(
      _app(
        status: PrayerStatus.pending,
        phase: PrayerActionPhase.failed,
        onChanged: changes.add,
        locale: const Locale('ar'),
      ),
    );
    expect(find.text('تعذر حفظ الحالة. حاول مرة أخرى.'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('prayer_status_fajr_completed_late')),
    );
    await tester.pump();
    expect(changes, [PrayerStatus.completedLate]);
  });
}
