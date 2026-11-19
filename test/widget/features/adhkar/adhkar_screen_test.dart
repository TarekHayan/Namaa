import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_state.dart';

import '../../../support/adhkar_screen_harness.dart';
import '../../../support/adhkar_test_support.dart';
import '../../../support/my_adhkar_test_support.dart';

/// T103: the Adhkar page in the approved design (contracts/adhkar-qiyam-ui.md,
/// "Adhkar page"): the title and three tabs, the progress card with its ring,
/// the time-window line, the streak row, the main button in each state, the
/// setup notice, and the layout matrix. The reader is covered by
/// adhkar_reader_test.dart and the sync page by adhkar_conflicts_test.dart.
void main() {
  Finder key(String value) => find.byKey(Key(value));

  Finder text(String value) => find.text(value);

  group('page structure', () {
    adhkarTestWidgets(
      'title, subtitle, tabs, then the progress card, time line, '
      'streak row and main button, in that order',
      (tester) async {
        final harness = AdhkarHarness();
        await harness.pump(tester);
        expect(text('Adhkar'), findsOneWidget);
        expect(
          text('Morning and evening adhkar from authentic hadith'),
          findsOneWidget,
        );
        expect(key('adhkar_switch_morning'), findsOneWidget);
        expect(key('adhkar_switch_evening'), findsOneWidget);
        expect(key('adhkar_switch_my_adhkar'), findsOneWidget);
        double top(String value) => tester.getTopLeft(key(value)).dy;
        final order = [
          top('adhkar_header'),
          top('adhkar_progress_card'),
          top('adhkar_starts_at_notice'),
          top('adhkar_streak_row'),
          top('adhkar_main_button'),
        ];
        expect([...order]..sort(), order, reason: 'the design order');
        // The old list of item cards is gone: no card, no per-item counter.
        expect(find.textContaining('test item'), findsNothing);
        expect(key('adhkar_count_m2'), findsNothing);
        expect(key('adhkar_reader'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    adhkarTestWidgets('the tabs open on the current period and switch only the '
        'content below', (tester) async {
      final harness = AdhkarHarness(
        clock: AdhkarClockState(
          scheduleState: AdhkarScheduleState.available,
          day: '2026-11-10',
          period: AdhkarPeriod.evening,
          nextBoundaryUtc: DateTime.utc(2026, 11, 11, 4, 29),
          morningCountable: false,
          eveningCountable: true,
          fajrUtc: DateTime.utc(2026, 11, 10, 4, 30),
          maghribUtc: DateTime.utc(2026, 11, 10, 16, 50),
          zoneId: 'UTC',
        ),
        counts: {},
      );
      await harness.pump(tester);
      expect(harness.cubit.state.selectedTab, AdhkarTab.evening);
      expect(text('Evening adhkar (0 / 2)'), findsOneWidget);
      final titleBefore = tester.getTopLeft(key('adhkar_header'));
      await tester.tap(key('adhkar_switch_morning'));
      await tester.pump();
      expect(text('Morning adhkar (0 / 4)'), findsOneWidget);
      expect(
        tester.getTopLeft(key('adhkar_header')),
        titleBefore,
        reason: 'the title block and tabs stay put',
      );
    });

    adhkarTestWidgets('the Quran attribution stays on the list page', (
      tester,
    ) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      expect(key('adhkar_attribution'), findsOneWidget);
    });
  });

  group('progress card', () {
    adhkarTestWidgets(
      'shows the list, the counts and the percentage in the ring',
      (tester) async {
        final harness = AdhkarHarness(counts: {'m1': 1, 'm3': 2});
        await harness.pump(tester);
        expect(text('Morning adhkar (2 / 4)'), findsOneWidget);
        expect(text('2 complete'), findsOneWidget);
        expect(text('50%'), findsOneWidget);
        final semantics = tester.ensureSemantics();
        expect(find.bySemanticsLabel('50%'), findsOneWidget);
        semantics.dispose();
      },
    );

    adhkarTestWidgets('finished: the check card replaces the progress card', (
      tester,
    ) async {
      final harness = AdhkarHarness(
        counts: {'m1': 1, 'm2': 3, 'm3': 2, 'm4': 1},
      );
      await harness.pump(tester);
      expect(key('adhkar_progress_card'), findsNothing);
      expect(key('adhkar_finished_card'), findsOneWidget);
      expect(text('Adhkar complete!'), findsOneWidget);
      expect(text('Morning adhkar (4 / 4)'), findsOneWidget);
    });
  });

  group('time line and setup', () {
    adhkarTestWidgets('an open window shows when this list starts', (
      tester,
    ) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      expect(text('Starts at 04:30'), findsOneWidget);
      await tester.tap(key('adhkar_switch_evening'));
      await tester.pump();
      expect(
        text('Starts at 16:50'),
        findsOneWidget,
        reason: 'Evening is not open yet: it starts at Maghrib',
      );
    });

    adhkarTestWidgets('during Evening the Morning line shows the NEXT Fajr', (
      tester,
    ) async {
      final harness = AdhkarHarness(
        clock: AdhkarClockState(
          scheduleState: AdhkarScheduleState.available,
          day: '2026-11-10',
          period: AdhkarPeriod.evening,
          nextBoundaryUtc: DateTime.utc(2026, 11, 11, 4, 29),
          morningCountable: false,
          eveningCountable: true,
          fajrUtc: DateTime.utc(2026, 11, 10, 4, 30),
          maghribUtc: DateTime.utc(2026, 11, 10, 16, 50),
          zoneId: 'UTC',
        ),
      );
      await harness.pump(tester);
      await tester.tap(key('adhkar_switch_morning'));
      await tester.pump();
      expect(text('Starts at 04:29'), findsOneWidget);
      expect(text('Starts at 04:30'), findsNothing);
    });

    adhkarTestWidgets('no saved location: the setup notice and its action, no '
        'time line, and counting stays unrestricted', (tester) async {
      var opened = 0;
      final harness = AdhkarHarness(clock: setupClock);
      await harness.pump(tester, onOpenPrayerSetup: () => opened++);
      expect(key('adhkar_setup_notice'), findsOneWidget);
      expect(
        text('Turn on prayer location so adhkar times apply'),
        findsOneWidget,
      );
      expect(key('adhkar_starts_at_notice'), findsNothing);
      expect(key('adhkar_locked_notice'), findsNothing);
      await tester.tap(key('adhkar_setup_button'));
      await tester.pump();
      expect(opened, 1);
    });

    adhkarTestWidgets('times unavailable: the paused-counting notice with the '
        'setup action', (tester) async {
      var opened = 0;
      final harness = AdhkarHarness(clock: unavailableClock);
      await harness.pump(tester, onOpenPrayerSetup: () => opened++);
      expect(key('adhkar_locked_notice'), findsOneWidget);
      expect(find.textContaining('counting is paused'), findsOneWidget);
      await tester.tap(key('adhkar_setup_button'));
      expect(opened, 1);
    });

    adhkarTestWidgets('without a setup callback no setup button shows', (
      tester,
    ) async {
      final harness = AdhkarHarness(clock: setupClock);
      await harness.pump(tester);
      expect(key('adhkar_setup_notice'), findsOneWidget);
      expect(key('adhkar_setup_button'), findsNothing);
    });
  });

  group('streak row', () {
    adhkarTestWidgets('shows the day streak in both languages', (tester) async {
      final harness = AdhkarHarness();
      await harness.pump(tester);
      expect(text('Day streak: 0'), findsOneWidget);
      await harness.pump(tester, locale: const Locale('ar'));
      expect(text('أيام متتالية: 0'), findsOneWidget);
    });
  });

  group('main button', () {
    adhkarTestWidgets('fresh: Start', (tester) async {
      final harness = AdhkarHarness(counts: {});
      await harness.pump(tester);
      expect(
        find.descendant(of: key('adhkar_main_button'), matching: text('Start')),
        findsOneWidget,
      );
    });

    adhkarTestWidgets('started: Continue from the first dhikr not done', (
      tester,
    ) async {
      // m1 is done, so the first one not done is dhikr 2.
      final harness = AdhkarHarness();
      await harness.pump(tester);
      expect(text('Continue from dhikr 2'), findsOneWidget);
    });

    adhkarTestWidgets('a partly counted first dhikr continues from dhikr 1', (
      tester,
    ) async {
      final harness = AdhkarHarness(counts: {'m2': 1});
      await harness.pump(tester);
      expect(text('Continue from dhikr 1'), findsOneWidget);
    });

    adhkarTestWidgets(
      'finished: the secondary button reads the list again from '
      'dhikr 1',
      (tester) async {
        final harness = AdhkarHarness(
          counts: {'m1': 1, 'm2': 3, 'm3': 2, 'm4': 1},
        );
        await harness.pump(tester);
        expect(text('Read the list again'), findsOneWidget);
        await tester.tap(key('adhkar_main_button'));
        await tester.pumpAndSettle();
        expect(key('adhkar_reader'), findsOneWidget);
        expect(text('1 | 4'), findsOneWidget, reason: 'opens at dhikr 1');
      },
    );

    adhkarTestWidgets('each state in Arabic', (tester) async {
      var harness = AdhkarHarness(counts: {});
      await harness.pump(tester, locale: const Locale('ar'));
      expect(text('ابدأ'), findsOneWidget);
      harness = AdhkarHarness();
      await harness.pump(tester, locale: const Locale('ar'));
      expect(text('متابعة من الذكر 2'), findsOneWidget);
      harness = AdhkarHarness(counts: {'m1': 1, 'm2': 3, 'm3': 2, 'm4': 1});
      await harness.pump(tester, locale: const Locale('ar'));
      expect(text('قراءة القائمة مرة أخرى'), findsOneWidget);
      expect(text('اكتملت الأذكار!'), findsOneWidget);
    });

    adhkarTestWidgets(
      'opens locked with no prayer times: the button still opens '
      'the reader',
      (tester) async {
        final harness = AdhkarHarness(clock: unavailableClock, counts: {});
        await harness.pump(tester);
        await tester.tap(key('adhkar_main_button'));
        await tester.pumpAndSettle();
        expect(key('adhkar_reader'), findsOneWidget);
        expect(key('adhkar_reader_lock_setup'), findsOneWidget);
      },
    );
  });

  group('My Adhkar tab', () {
    adhkarTestWidgets('opens the collection with no progress card or locked '
        'notice, and works when the schedule is unavailable', (tester) async {
      final store = MemoryMyAdhkarStore()..addGroup('group a', id: 'ga');
      final mine = store.cubit();
      addTearDown(mine.close);
      final harness = AdhkarHarness(clock: unavailableClock);
      await harness.pump(tester, myAdhkarCubit: mine);
      expect(find.textContaining('counting is paused'), findsOneWidget);
      await tester.tap(key('adhkar_switch_my_adhkar'));
      await tester.pumpAndSettle();
      expect(key('my_adhkar_tab'), findsOneWidget);
      expect(key('adhkar_progress_card'), findsNothing);
      expect(key('adhkar_main_button'), findsNothing);
      expect(find.textContaining('counting is paused'), findsNothing);
      expect(key('my_adhkar_group_ga'), findsOneWidget);
      expect(
        tester.widget<AppButton>(key('my_adhkar_create_group')).onPressed,
        isNotNull,
        reason: 'My Adhkar has no locked state',
      );
    });

    adhkarTestWidgets('leaving the tab closes an open group', (tester) async {
      final store = MemoryMyAdhkarStore();
      final group = store.addGroup('group a', id: 'ga');
      store.addItem(text: 'entry text 1', groupIds: [group.groupId], id: 'i1');
      final mine = store.cubit();
      addTearDown(mine.close);
      final harness = AdhkarHarness();
      await harness.pump(tester, myAdhkarCubit: mine);
      await tester.tap(key('adhkar_switch_my_adhkar'));
      await tester.pumpAndSettle();
      await tester.tap(key('my_adhkar_group_ga'));
      await tester.pumpAndSettle();
      expect(key('my_adhkar_entry_i1'), findsOneWidget);

      await tester.tap(key('adhkar_switch_morning'));
      await tester.pumpAndSettle();
      await tester.tap(key('adhkar_switch_my_adhkar'));
      await tester.pumpAndSettle();
      expect(key('my_adhkar_entry_i1'), findsNothing);
      expect(
        key('my_adhkar_group_ga'),
        findsOneWidget,
        reason: 'coming back shows the group list',
      );
    });
  });

  group('content unavailable', () {
    adhkarTestWidgets('shows the error state, and retry loads the content', (
      tester,
    ) async {
      final catalog = SwitchableCatalog();
      final harness = AdhkarHarness(catalog: catalog);
      await harness.pump(tester);
      expect(key('adhkar_content_error'), findsOneWidget);
      expect(text('Could not load the adhkar content.'), findsOneWidget);
      expect(key('adhkar_switch_morning'), findsNothing);
      catalog.works = true;
      await tester.tap(key('adhkar_retry'));
      await harness.settle(tester);
      expect(key('adhkar_content_error'), findsNothing);
      expect(key('adhkar_switch_morning'), findsOneWidget);
    });
  });

  group('layout matrix', () {
    final clocks = <String, AdhkarClockState>{
      'open window': morningClock(),
      'setup': setupClock,
      'unavailable': unavailableClock,
    };
    final dayStates = <String, Map<String, int>>{
      'fresh': {},
      'started': {'m1': 1},
      'finished': {'m1': 1, 'm2': 3, 'm3': 2, 'm4': 1},
    };
    for (final locale in const [Locale('ar'), Locale('en')]) {
      for (final brightness in Brightness.values) {
        adhkarTestWidgets(
          '${locale.languageCode} ${brightness.name}: every page '
          'state at 320 px and 200% text, and wide, without overflow',
          (tester) async {
            for (final size in const [Size(320, 640), Size(1100, 800)]) {
              for (final clock in clocks.entries) {
                for (final counts in dayStates.entries) {
                  final harness = AdhkarHarness(
                    clock: clock.value,
                    counts: counts.value,
                  );
                  await harness.pump(
                    tester,
                    locale: locale,
                    brightness: brightness,
                    size: size,
                    textScale: size.width < 400 ? 2.0 : 1.0,
                    onOpenPrayerSetup: () {},
                  );
                  expect(
                    tester.takeException(),
                    isNull,
                    reason:
                        '${locale.languageCode} ${brightness.name} $size '
                        '${clock.key} ${counts.key}',
                  );
                  // At 200% on a narrow screen the title block fills the
                  // screen: scroll down so the whole page is laid out.
                  final scrollable = find.byType(Scrollable).first;
                  await tester.scrollUntilVisible(
                    key('adhkar_main_button'),
                    300,
                    scrollable: scrollable,
                  );
                  await tester.ensureVisible(key('adhkar_main_button'));
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull, reason: 'page bottom');
                  await tester.drag(scrollable, const Offset(0, 3000));
                  await tester.pumpAndSettle();
                  await tester.tap(key('adhkar_switch_evening'));
                  await tester.pump();
                  await tester.scrollUntilVisible(
                    key('adhkar_main_button'),
                    300,
                    scrollable: scrollable,
                  );
                  await tester.ensureVisible(key('adhkar_main_button'));
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull, reason: 'evening tab');
                }
              }
            }
          },
        );
      }
    }
  });
}
