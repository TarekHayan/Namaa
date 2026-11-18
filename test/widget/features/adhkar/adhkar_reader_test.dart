import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_layout.dart';
import 'package:namma_project/app/widgets/app_surface_icon_button.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_state.dart';
import 'package:namma_project/features/adhkar/presentation/widgets/adhkar_reader.dart';
import 'package:namma_project/features/adhkar/presentation/widgets/adhkar_style.dart';

import '../../../support/adhkar_screen_harness.dart';
import '../../../support/adhkar_test_support.dart';

/// T104: the reader (contracts/adhkar-qiyam-ui.md, "Reader"): one item per
/// page, the count button with its ring, the done bar and the auto slide in
/// both directions, swipe, the list sheet and jump, the reset dialog, the
/// locked banners, the completion state, the error state, the wide layout
/// with its keyboard, device back, and no second award. The text is the
/// placeholder fixture catalog.
void main() {
  Finder key(String value) => find.byKey(Key(value));
  Finder text(String value) => find.text(value);

  /// Opens the reader from the page's main button.
  Future<void> openReader(WidgetTester tester) async {
    await tester.tap(key('adhkar_main_button'));
    await tester.pumpAndSettle();
    expect(key('adhkar_reader'), findsOneWidget);
  }

  /// One tap on the count button, then the Cubit's command settles.
  Future<void> count(WidgetTester tester, [int times = 1]) async {
    for (var i = 0; i < times; i++) {
      await tester.tap(key('adhkar_reader_count'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  /// Runs the done hold and the slide to the next page.
  Future<void> finishHoldAndSlide(WidgetTester tester) async {
    await tester.pump(kAdhkarDoneHold);
    await tester.pumpAndSettle();
  }

  bool countEnabled(WidgetTester tester) =>
      tester.widget<InkWell>(key('adhkar_reader_count')).onTap != null;

  group('opening and reading', () {
    adhkarTestWidgets('opens at the first dhikr not done, full screen with '
        'no shell', (tester) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      expect(key('harness_shell'), findsOneWidget);
      await openReader(tester);
      expect(
        key('harness_shell'),
        findsNothing,
        reason: 'the reader covers the shell',
      );
      expect(text('Morning adhkar'), findsOneWidget);
      expect(text('test item m2'), findsOneWidget);
      expect(text('test ref m2'), findsOneWidget);
      expect(text('2 | 4'), findsOneWidget);
      expect(text('3 times'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing, reason: 'no app-bar back');
      expect(tester.takeException(), isNull);
    });

    adhkarTestWidgets('the text is Amiri, a Quran item uses the Quran font '
        'in one piece with its preface, and the list top bar shows the '
        'list progress', (tester) async {
      final harness = AdhkarHarness(counts: {'m1': 1, 'm2': 3, 'm3': 2});
      await harness.pump(tester);
      await openReader(tester);
      // m4 is the first one not done: a Quran placeholder item.
      final verses = tester.widget<Text>(text('placeholder verse text'));
      expect(verses.style?.fontFamily, kQuranFontFamily);
      expect(
        find.text('placeholder verse text'),
        findsOneWidget,
        reason: 'the verse text is one piece: no split, no drawn markers',
      );
      expect(text('placeholder preface'), findsOneWidget);
      expect(text('test reference m4'), findsOneWidget);
      expect(text('Once'), findsOneWidget);
      // Back on a dhikr page the text is Amiri.
      await tester.tap(key('adhkar_reader_list'));
      await tester.pumpAndSettle();
      await tester.tap(key('adhkar_reader_sheet_row_m2'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(text('test item m2')).style?.fontFamily,
        'Amiri',
      );
      final bar = tester.getSize(key('adhkar_reader_progress'));
      expect(bar.height, 4);
    });

    adhkarTestWidgets('the virtue is collapsible and only shown when the '
        'item has one', (tester) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      await openReader(tester);
      expect(key('adhkar_virtue_toggle_m2'), findsOneWidget);
      expect(text('test virtue m2'), findsNothing);
      await tester.tap(key('adhkar_virtue_toggle_m2'));
      await tester.pumpAndSettle();
      expect(text('test virtue m2'), findsOneWidget);
      await tester.tap(key('adhkar_virtue_toggle_m2'));
      await tester.pumpAndSettle();
      expect(text('test virtue m2'), findsNothing);
      // m3 has no virtue, so no pill.
      await tester.drag(key('adhkar_reader_pages'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(text('test item m3'), findsOneWidget);
      expect(key('adhkar_virtue_toggle_m3'), findsNothing);
    });

    adhkarTestWidgets('the close button returns to the same tab of the '
        'page', (tester) async {
      final harness = AdhkarHarness(counts: {});
      await harness.pump(tester);
      await tester.tap(key('adhkar_switch_evening'));
      await tester.pump();
      await openReader(tester);
      expect(text('Evening adhkar'), findsOneWidget);
      expect(text('test item e1'), findsOneWidget);
      await tester.tap(key('adhkar_reader_close'));
      await tester.pumpAndSettle();
      expect(key('adhkar_reader'), findsNothing);
      expect(key('harness_shell'), findsOneWidget);
      expect(harness.cubit.state.selectedTab, AdhkarTab.evening);
      expect(text('Evening adhkar (0 / 2)'), findsOneWidget);
    });
  });

  group('counting', () {
    adhkarTestWidgets('each tap counts once and the count and its semantic '
        'label follow', (tester) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      await openReader(tester);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Count, 0 of 3'), findsOneWidget);
      await count(tester);
      expect(harness.commands.incrementCalls, ['m2']);
      expect(find.bySemanticsLabel('Count, 1 of 3'), findsOneWidget);
      expect(
        find.descendant(of: key('adhkar_reader_controls'), matching: text('1')),
        findsOneWidget,
      );
      await count(tester);
      expect(find.bySemanticsLabel('Count, 2 of 3'), findsOneWidget);
      semantics.dispose();
    });

    adhkarTestWidgets('the audio slot is empty: nothing but a reserved 52 px '
        'box', (tester) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      await openReader(tester);
      final slot = find.descendant(
        of: key('adhkar_reader_controls'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.width == 52 &&
              widget.height == 52 &&
              widget.child == null,
        ),
      );
      expect(slot, findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    adhkarTestWidgets('at the target the number becomes a check, the done bar '
        'holds for about 600 ms, then the page slides to the next dhikr', (
      tester,
    ) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      await openReader(tester);
      await count(tester, 3);
      expect(key('adhkar_reader_done_bar'), findsOneWidget);
      expect(text('Done'), findsOneWidget);
      expect(text('Next'), findsOneWidget);
      expect(
        find.descendant(
          of: key('adhkar_reader_controls'),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(countEnabled(tester), isFalse, reason: 'a done item is closed');
      expect(key('adhkar_reader_next_sliver'), findsOneWidget);
      // Still holding at 500 ms: the same page.
      await tester.pump(const Duration(milliseconds: 500));
      expect(key('adhkar_reader_done_bar'), findsOneWidget);
      expect(text('2 | 4'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(key('adhkar_reader_done_bar'), findsNothing);
      expect(text('3 | 4'), findsOneWidget);
      expect(text('test item m3'), findsOneWidget);
      expect(countEnabled(tester), isTrue);
    });

    adhkarTestWidgets('English slides the next page in from the right', (
      tester,
    ) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      await openReader(tester);
      await count(tester, 3);
      await tester.pump(kAdhkarDoneHold);
      await tester.pump(const Duration(milliseconds: 100));
      final next = tester.getCenter(key('adhkar_reader_page_m3')).dx;
      expect(next, greaterThan(200), reason: 'entering from the right');
      await tester.pumpAndSettle();
    });

    adhkarTestWidgets('Arabic slides the next page in from the left', (
      tester,
    ) async {
      final harness = AdhkarHarness();
      await harness.pump(tester, locale: const Locale('ar'));
      await openReader(tester);
      await count(tester, 3);
      await tester.pump(kAdhkarDoneHold);
      await tester.pump(const Duration(milliseconds: 100));
      final next = tester.getCenter(key('adhkar_reader_page_m3')).dx;
      expect(next, lessThan(200), reason: 'entering from the left');
      await tester.pumpAndSettle();
      expect(text('3 | 4'), findsOneWidget);
    });

    adhkarTestWidgets('a swipe away during the hold leaves the person where '
        'they went', (tester) async {
      final harness = AdhkarHarness(counts: {'m1': 1, 'm2': 3});
      await harness.pump(tester);
      await openReader(tester);
      // The first not done is m3: count it twice, then swipe back at once.
      await count(tester, 2);
      await tester.drag(key('adhkar_reader_pages'), const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await finishHoldAndSlide(tester);
      expect(text('test item m2'), findsOneWidget);
      expect(text('2 | 4'), findsOneWidget);
    });
  });

  group('swipe and jump', () {
    adhkarTestWidgets('swipe moves both ways in English and stops at the '
        'ends', (tester) async {
      final harness = AdhkarHarness(counts: {'m1': 1, 'm2': 3, 'm3': 2});
      await harness.pump(tester);
      await tester.tap(key('adhkar_main_button'));
      await tester.pumpAndSettle();
      expect(text('4 | 4'), findsOneWidget);
      // Past the last: stays.
      await tester.drag(key('adhkar_reader_pages'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(text('4 | 4'), findsOneWidget);
      for (var expected = 3; expected >= 1; expected--) {
        await tester.drag(key('adhkar_reader_pages'), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(text('$expected | 4'), findsOneWidget);
      }
      // Before the first: stays.
      await tester.drag(key('adhkar_reader_pages'), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(text('1 | 4'), findsOneWidget);
      await tester.drag(key('adhkar_reader_pages'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(text('2 | 4'), findsOneWidget);
    });

    adhkarTestWidgets('swipe moves the other way in Arabic', (tester) async {
      final harness = AdhkarHarness(counts: {'m1': 1});
      await harness.pump(tester, locale: const Locale('ar'));
      await openReader(tester);
      expect(text('2 | 4'), findsOneWidget);
      await tester.drag(key('adhkar_reader_pages'), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(text('3 | 4'), findsOneWidget, reason: 'right-to-left: next');
      await tester.drag(key('adhkar_reader_pages'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(text('2 | 4'), findsOneWidget);
    });

    adhkarTestWidgets('counts are kept per dhikr when leaving one half '
        'done', (tester) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      await openReader(tester);
      await count(tester, 2);
      await tester.drag(key('adhkar_reader_pages'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Count, 0 of 2'), findsOneWidget);
      await tester.drag(key('adhkar_reader_pages'), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(harness.day.counts['m2'], 2);
      expect(
        find.descendant(of: key('adhkar_reader_controls'), matching: text('2')),
        findsOneWidget,
      );
    });

    adhkarTestWidgets('the list sheet shows every item with its count and '
        'done mark, and a row jumps straight to that dhikr', (tester) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      await openReader(tester);
      await tester.tap(key('adhkar_reader_list'));
      await tester.pumpAndSettle();
      expect(key('adhkar_reader_sheet'), findsOneWidget);
      expect(text('1 / 4'), findsOneWidget, reason: 'one of four done');
      for (final id in ['m1', 'm2', 'm3', 'm4']) {
        expect(key('adhkar_reader_sheet_row_$id'), findsOneWidget);
      }
      expect(text('1 / 1'), findsWidgets);
      expect(text('0 / 3'), findsOneWidget);
      expect(
        find.descendant(
          of: key('adhkar_reader_sheet_row_m1'),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
        reason: 'the done mark',
      );
      expect(
        find.descendant(
          of: key('adhkar_reader_sheet_row_m2'),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsNothing,
      );
      await tester.tap(key('adhkar_reader_sheet_row_m4'));
      await tester.pumpAndSettle();
      expect(key('adhkar_reader_sheet'), findsNothing);
      expect(text('4 | 4'), findsOneWidget);
      expect(
        key('adhkar_reader_page_m3'),
        findsNothing,
        reason: 'a jump does not slide through the ones between',
      );
    });
  });

  group('reset', () {
    adhkarTestWidgets('Cancel and a tap outside change nothing; Reset sets '
        'this dhikr to 0 and stays on the page', (tester) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      await openReader(tester);
      await count(tester, 2);
      await tester.tap(key('adhkar_reader_reset'));
      await tester.pumpAndSettle();
      expect(key('adhkar_reset_dialog'), findsOneWidget);
      expect(text('Reset this count?'), findsOneWidget);
      expect(
        text('The count for this dhikr will go back to zero.'),
        findsOneWidget,
      );
      await tester.tap(key('adhkar_reset_cancel'));
      await tester.pumpAndSettle();
      expect(key('adhkar_reset_dialog'), findsNothing);
      expect(harness.commands.resetCalls, isEmpty);

      await tester.tap(key('adhkar_reader_reset'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(key('adhkar_reset_dialog'), findsNothing);
      expect(harness.commands.resetCalls, isEmpty);

      await tester.tap(key('adhkar_reader_reset'));
      await tester.pumpAndSettle();
      await tester.tap(key('adhkar_reset_confirm'));
      await tester.pumpAndSettle();
      expect(harness.commands.resetCalls, ['m2']);
      expect(harness.day.counts['m2'], 0);
      expect(text('2 | 4'), findsOneWidget, reason: 'stays on this page');
      expect(find.bySemanticsLabel('Count, 0 of 3'), findsOneWidget);
    });
  });

  group('locked', () {
    adhkarTestWidgets('outside the window: a banner, a lock instead of the '
        'number, count and reset disabled, swipe still works, and it '
        'unlocks by itself', (tester) async {
      final harness = AdhkarHarness(
        clock: morningClock(morningCountable: false),
      );
      await harness.pump(tester);
      await openReader(tester);
      expect(key('adhkar_reader_lock_time'), findsOneWidget);
      expect(text('Starts at 16:50'), findsWidgets);
      expect(
        find.descendant(
          of: key('adhkar_reader_controls'),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
      expect(countEnabled(tester), isFalse);
      expect(
        tester.widget<AppSurfaceIconButton>(key('adhkar_reader_reset')).onTap,
        isNull,
      );
      await tester.tap(key('adhkar_reader_count'), warnIfMissed: false);
      await tester.pump();
      expect(harness.commands.incrementCalls, isEmpty);
      // The text stays readable and swipe works.
      expect(text('test item m2'), findsOneWidget);
      await tester.drag(key('adhkar_reader_pages'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(text('test item m3'), findsOneWidget);

      // The window opens: the buttons come back on their own.
      harness.times.state = morningClock();
      await harness.cubit.resume();
      await harness.settle(tester);
      expect(key('adhkar_reader_lock_time'), findsNothing);
      expect(countEnabled(tester), isTrue);
      expect(
        tester.widget<AppSurfaceIconButton>(key('adhkar_reader_reset')).onTap,
        isNotNull,
      );
    });

    adhkarTestWidgets('no prayer times: the setup banner with its action, '
        'and counting is paused', (tester) async {
      var opened = 0;
      final harness = AdhkarHarness(clock: unavailableClock, counts: {});
      await harness.pump(tester, onOpenPrayerSetup: () => opened++);
      await openReader(tester);
      expect(key('adhkar_reader_lock_setup'), findsOneWidget);
      expect(find.textContaining('counting is paused'), findsWidgets);
      expect(countEnabled(tester), isFalse);
      await tester.tap(key('adhkar_reader_setup_button'));
      expect(opened, 1);
    });

    adhkarTestWidgets('no saved location is unrestricted: the reader counts', (
      tester,
    ) async {
      final harness = AdhkarHarness(clock: setupClock, counts: {});
      await harness.pump(tester);
      await openReader(tester);
      expect(key('adhkar_reader_lock_setup'), findsNothing);
      expect(key('adhkar_reader_lock_time'), findsNothing);
      await count(tester);
      expect(harness.commands.incrementCalls, ['m1']);
    });
  });

  group('completion', () {
    adhkarTestWidgets('the last dhikr opens the completion state with the '
        'points, once, and Back returns to the page; reading again never '
        'awards twice', (tester) async {
      final harness = AdhkarHarness(counts: {'m1': 1, 'm2': 3, 'm3': 2});
      await harness.pump(tester);
      await openReader(tester);
      expect(text('4 | 4'), findsOneWidget);
      await count(tester);
      await finishHoldAndSlide(tester);
      expect(key('adhkar_reader_complete'), findsOneWidget);
      expect(text('Adhkar complete!'), findsOneWidget);
      expect(text('+15 points'), findsOneWidget);
      expect(harness.commands.completedSets, 1);
      expect(
        tester
            .widget<FractionallySizedBox>(
              find.descendant(
                of: key('adhkar_reader_progress'),
                matching: find.byType(FractionallySizedBox),
              ),
            )
            .widthFactor,
        1,
      );
      await tester.tap(key('adhkar_reader_back'));
      await tester.pumpAndSettle();
      expect(key('adhkar_reader'), findsNothing);
      expect(key('adhkar_finished_card'), findsOneWidget);

      // Reading again opens item 1 with every count button closed; nothing
      // is counted and nothing is awarded.
      await tester.tap(key('adhkar_main_button'));
      await tester.pumpAndSettle();
      expect(text('1 | 4'), findsOneWidget);
      expect(countEnabled(tester), isFalse);
      await tester.tap(key('adhkar_reader_count'), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));
      expect(harness.commands.completedSets, 1);
      expect(harness.commands.incrementCalls, ['m4']);
      expect(key('adhkar_reader_points'), findsNothing);
      expect(key('adhkar_reader_complete'), findsNothing);
    });

    adhkarTestWidgets('finishing the last dhikr with an earlier one still '
        'open stays on the page', (tester) async {
      final harness = AdhkarHarness(counts: {'m1': 1, 'm3': 2});
      await harness.pump(tester);
      await openReader(tester);
      await tester.tap(key('adhkar_reader_list'));
      await tester.pumpAndSettle();
      await tester.tap(key('adhkar_reader_sheet_row_m4'));
      await tester.pumpAndSettle();
      await count(tester);
      await finishHoldAndSlide(tester);
      expect(key('adhkar_reader_complete'), findsNothing);
      expect(text('4 | 4'), findsOneWidget);
      expect(key('adhkar_reader_done_bar'), findsNothing);
      expect(harness.commands.completedSets, 0);
    });
  });

  group('error', () {
    adhkarTestWidgets('content unavailable shows the error state, and retry '
        'loads it', (tester) async {
      final catalog = SwitchableCatalog();
      final harness = AdhkarHarness(catalog: catalog);
      harness.cubit = harness.buildCubit();
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          home: BlocProvider.value(
            value: harness.cubit,
            child: AdhkarReader(
              list: AdhkarList.morning,
              initialIndex: 0,
              onClose: () {},
            ),
          ),
        ),
      );
      unawaited(harness.cubit.load());
      await harness.settle(tester);
      expect(key('adhkar_reader_error'), findsOneWidget);
      expect(text('Could not load the adhkar content.'), findsOneWidget);
      expect(
        tester.widget<AppSurfaceIconButton>(key('adhkar_reader_list')).onTap,
        isNull,
        reason: 'the list button is off in the error state',
      );
      catalog.works = true;
      await tester.tap(key('adhkar_retry'));
      await harness.settle(tester);
      expect(key('adhkar_reader_error'), findsNothing);
      expect(text('test item m1'), findsOneWidget);
      await harness.cubit.close();
    });
  });

  group('wide layout', () {
    adhkarTestWidgets('a centered column of at most 720 px, round previous '
        'and next buttons, and keyboard hints', (tester) async {
      final harness = AdhkarHarness();
      await harness.pump(tester, size: const Size(1280, 800));
      await openReader(tester);
      expect(
        tester.getSize(key('adhkar_reader_pages')).width,
        lessThanOrEqualTo(AppLayout.columnMaxWidth),
      );
      expect(key('adhkar_reader_prev'), findsOneWidget);
      expect(key('adhkar_reader_next'), findsOneWidget);
      expect(key('adhkar_reader_keyboard_hints'), findsOneWidget);
      await tester.tap(key('adhkar_reader_next'));
      await tester.pumpAndSettle();
      expect(text('3 | 4'), findsOneWidget);
      await tester.tap(key('adhkar_reader_prev'));
      await tester.pumpAndSettle();
      expect(text('2 | 4'), findsOneWidget);
    });

    adhkarTestWidgets('a phone has no round buttons and no keyboard hints', (
      tester,
    ) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      await openReader(tester);
      expect(key('adhkar_reader_prev'), findsNothing);
      expect(key('adhkar_reader_keyboard_hints'), findsNothing);
    });

    adhkarTestWidgets('Space and Enter count; key repeat never goes past the '
        'target', (tester) async {
      final harness = AdhkarHarness(counts: {'m1': 1, 'm2': 3});
      await harness.pump(tester, size: const Size(1280, 800));
      await openReader(tester);
      // m3 has a target of 2.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 10));
      expect(harness.commands.incrementCalls, ['m3', 'm3']);
      expect(harness.day.counts['m3'], 2);
      await finishHoldAndSlide(tester);
    });

    adhkarTestWidgets('the arrow keys follow the screen in English', (
      tester,
    ) async {
      final harness = AdhkarHarness();
      await harness.pump(tester, size: const Size(1280, 800));
      await openReader(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(text('3 | 4'), findsOneWidget, reason: 'right goes next');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(text('2 | 4'), findsOneWidget);
    });

    adhkarTestWidgets('the arrow keys follow the screen in Arabic', (
      tester,
    ) async {
      final harness = AdhkarHarness();
      await harness.pump(
        tester,
        size: const Size(1280, 800),
        locale: const Locale('ar'),
      );
      await openReader(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(text('3 | 4'), findsOneWidget, reason: 'left goes next');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(text('2 | 4'), findsOneWidget);
    });
  });

  group('device back', () {
    adhkarTestWidgets('closes the reset dialog, then the list sheet, then the '
        'reader, and then goes Home', (tester) async {
      final harness = AdhkarHarness();
      await harness.pump(tester, useRouter: true);
      await openReader(tester);

      await tester.tap(key('adhkar_reader_list'));
      await tester.pumpAndSettle();
      expect(key('adhkar_reader_sheet'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(key('adhkar_reader_sheet'), findsNothing);
      expect(key('adhkar_reader'), findsOneWidget, reason: 'sheet first');

      await tester.tap(key('adhkar_reader_reset'));
      await tester.pumpAndSettle();
      expect(key('adhkar_reset_dialog'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(key('adhkar_reset_dialog'), findsNothing);
      expect(key('adhkar_reader'), findsOneWidget, reason: 'dialog first');
      expect(harness.commands.resetCalls, isEmpty);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(key('adhkar_reader'), findsNothing);
      expect(key('adhkar_switch_morning'), findsOneWidget, reason: 'the page');
      expect(find.text('home page'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('home page'), findsOneWidget);
    });
  });

  group('layout matrix', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      for (final brightness in Brightness.values) {
        adhkarTestWidgets(
          '${locale.languageCode} ${brightness.name}: reading, done, sheet, '
          'reset, locked, setup and complete at 320 px and 200% text, and '
          'wide, without overflow',
          (tester) async {
            for (final size in const [Size(320, 640), Size(1280, 800)]) {
              final scale = size.width < 400 ? 2.0 : 1.0;
              Future<AdhkarHarness> open({
                AdhkarClockState? clock,
                Map<String, int>? counts,
              }) async {
                final harness = AdhkarHarness(clock: clock, counts: counts);
                await harness.pump(
                  tester,
                  locale: locale,
                  brightness: brightness,
                  size: size,
                  textScale: scale,
                  onOpenPrayerSetup: () {},
                );
                // At 200% on a narrow screen the title block alone fills the
                // screen: scroll down to the main button first.
                await tester.scrollUntilVisible(
                  key('adhkar_main_button'),
                  300,
                  scrollable: find.byType(Scrollable).first,
                );
                await tester.ensureVisible(key('adhkar_main_button'));
                await tester.pumpAndSettle();
                await tester.tap(key('adhkar_main_button'));
                await tester.pumpAndSettle();
                return harness;
              }

              void noOverflow(String state) => expect(
                tester.takeException(),
                isNull,
                reason:
                    '${locale.languageCode} ${brightness.name} $size '
                    '$state',
              );

              // Reading, with the virtue open, then the done bar.
              await open(counts: {'m1': 1, 'm2': 2});
              noOverflow('reading');
              await tester.tap(key('adhkar_virtue_toggle_m2'));
              await tester.pumpAndSettle();
              noOverflow('virtue open');
              await count(tester);
              noOverflow('done bar');
              await finishHoldAndSlide(tester);
              noOverflow('after the slide');

              // The list sheet and the reset dialog.
              await tester.tap(key('adhkar_reader_list'));
              await tester.pumpAndSettle();
              noOverflow('list sheet');
              await tester.ensureVisible(key('adhkar_reader_sheet_row_m1'));
              await tester.pumpAndSettle();
              await tester.tap(key('adhkar_reader_sheet_row_m1'));
              await tester.pumpAndSettle();
              await tester.tap(key('adhkar_reader_reset'));
              await tester.pumpAndSettle();
              noOverflow('reset dialog');
              await tester.tap(key('adhkar_reset_cancel'));
              await tester.pumpAndSettle();

              // Locked by time and by missing times.
              await open(clock: morningClock(morningCountable: false));
              noOverflow('locked by time');
              await open(clock: unavailableClock, counts: {});
              noOverflow('locked by missing times');

              // The completion state.
              await open(counts: {'m1': 1, 'm2': 3, 'm3': 2});
              await count(tester);
              await finishHoldAndSlide(tester);
              expect(key('adhkar_reader_complete'), findsOneWidget);
              noOverflow('complete');
            }
          },
        );
      }
    }
  });
}
