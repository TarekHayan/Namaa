import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_pill.dart';
import 'package:namma_project/app/widgets/app_sheets.dart';
import 'package:namma_project/features/qiyam/application/save_qiyam_night.dart';

import '../../../support/qiyam_test_support.dart';
import '../../../support/time_dial_support.dart';

/// T107: the Qiyam screen in the approved design (contracts/
/// adhkar-qiyam-ui.md, "Qiyam screen (approved design, 2026-11-18)"): the
/// heading chips, the tonight tracker with its answered switch, the one-time
/// points badge, the autosaved details form, the collapsible supplications,
/// the states, and the AR/EN, light/dark, 320 px at 200% matrix. The
/// supplication content is placeholder text (real religious text never lives
/// in code or tests).
void main() {
  late QiyamHarness h;

  setUp(() => h = QiyamHarness());

  Finder key(String value) => find.byKey(Key(value));

  Future<void> tapKey(WidgetTester tester, String value) async {
    final finder = key(value);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
    await tester.pump();
  }

  Future<void> answerYes(
    WidgetTester tester, {
    bool firstPerformed = true,
  }) async {
    h.commands.outcome = QiyamNightSaved(firstPerformed: firstPerformed);
    await tapKey(tester, 'qiyam_yes');
  }

  group('the page', () {
    qiyamTestWidgets(
      'the order: heading, tracker, supplications, then history',
      (tester) async {
        h.repository.seeded['2026-11-10'] = qiyamRecord('2026-11-10');
        await h.pump(tester, h.buildCubit());
        double top(String k) => tester.getTopLeft(key(k)).dy;
        expect(top('qiyam_header'), lessThan(top('qiyam_tracker_card')));
        expect(
          top('qiyam_tracker_card'),
          lessThan(top('qiyam_supplications_card')),
        );
        expect(
          top('qiyam_supplications_card'),
          lessThan(top('qiyam_history_section')),
        );
      },
    );

    qiyamTestWidgets('the heading shows the title, subtitle and last third', (
      tester,
    ) async {
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      expect(find.text('Night prayer'), findsOneWidget);
      expect(
        find.text('Prayer of the night and quiet supplication'),
        findsOneWidget,
      );
      expect(find.text('Last third of the night 01:40'), findsOneWidget);
      expect(key('qiyam_open_prayer_setup'), findsNothing);
    });

    qiyamTestWidgets('the Arabic heading', (tester) async {
      await h.pump(tester, h.buildCubit());
      expect(find.text('قيام الليل'), findsOneWidget);
      expect(find.text('صلاة الليل والمناجاة'), findsOneWidget);
      expect(
        tester.widget<AppPill>(key('qiyam_last_third_chip')).label,
        startsWith('الثلث الأخير من الليل'),
      );
    });

    qiyamTestWidgets(
      'the streak chip shows the streak; a failed read shows the '
      'failure and never 0',
      (tester) async {
        h.repository.streakToReturn = 5;
        await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
        expect(find.text('Qiyam streak: 5'), findsOneWidget);
        expect(key('qiyam_streak_failed'), findsNothing);

        final failing = QiyamHarness()..repository.failStreak = true;
        await failing.pump(
          tester,
          failing.buildCubit(),
          locale: const Locale('en'),
        );
        expect(key('qiyam_streak_chip'), findsNothing);
        expect(find.text('Could not load the Qiyam streak.'), findsOneWidget);
        expect(find.textContaining('streak: 0'), findsNothing);
      },
    );

    qiyamTestWidgets(
      'no saved location: the chip says so with the setup button '
      'and recording still works',
      (tester) async {
        h = QiyamHarness(night: qiyamSetupRequired());
        var setups = 0;
        await h.pump(
          tester,
          h.buildCubit(),
          locale: const Locale('en'),
          onOpenPrayerSetup: () => setups++,
        );
        expect(
          find.text('Cannot work out the last third of the night right now'),
          findsOneWidget,
        );
        expect(key('qiyam_locked_notice'), findsNothing);
        await tapKey(tester, 'qiyam_open_prayer_setup');
        expect(setups, 1);
        await answerYes(tester);
        expect(
          h.commands.drafts,
          hasLength(1),
          reason: 'the night rule applies',
        );
      },
    );

    qiyamTestWidgets('a saved schedule that is unavailable pauses recording with '
        'the reason and the setup button', (tester) async {
      h = QiyamHarness(night: kQiyamUnavailable);
      var setups = 0;
      await h.pump(
        tester,
        h.buildCubit(),
        locale: const Locale('en'),
        onOpenPrayerSetup: () => setups++,
      );
      expect(
        find.text(
          'Times are not available right now; recording is paused until they return.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: key('qiyam_yes'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: key('qiyam_no'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await tapKey(tester, 'qiyam_open_prayer_setup');
      expect(setups, 1);
      await tester.tap(key('qiyam_yes'), warnIfMissed: false);
      expect(h.commands.drafts, isEmpty);
    });

    qiyamTestWidgets(
      'while the night loads only the title shows, with no flash '
      'of the paused state',
      (tester) async {
        h.nightPort.gate = Completer<void>();
        await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
        expect(find.text('Night prayer'), findsOneWidget);
        expect(key('qiyam_locked_notice'), findsNothing);
        expect(key('qiyam_tracker_card'), findsNothing);
        expect(key('qiyam_last_third_chip'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        h.nightPort.gate!.complete();
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(key('qiyam_tracker_card'), findsOneWidget);
      },
    );
  });

  group('tonight', () {
    qiyamTestWidgets('unanswered: the question, the best-time note and two '
        'answers, with no Save button', (tester) async {
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      expect(find.text('Did you pray Qiyam tonight?'), findsOneWidget);
      expect(
        find.text(
          'The best time for Qiyam is the last third of the night, before Fajr.',
        ),
        findsOneWidget,
      );
      expect(find.text('Yes, praise be to God (+30 points)'), findsOneWidget);
      expect(find.text('Not yet'), findsOneWidget);
      expect(find.textContaining('Save'), findsNothing);
      expect(key('qiyam_rakah_chip_4'), findsNothing);
    });

    qiyamTestWidgets(
      'Yes saves at once, shows the points badge and the details '
      'with the defaults',
      (tester) async {
        await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
        await answerYes(tester);
        final draft = h.commands.drafts.single;
        expect(draft.performed, isTrue);
        expect(draft.rakahs, 4);
        expect(draft.witr, isTrue);
        expect(find.text('Qiyam complete! +30 points'), findsOneWidget);
        // The two answers became the switch.
        expect(key('qiyam_yes'), findsNothing);
        expect(key('qiyam_answer_switch'), findsOneWidget);
        expect(find.text('Details (optional)'), findsOneWidget);
        for (final n in [2, 4, 8, 11]) {
          expect(key('qiyam_rakah_chip_$n'), findsOneWidget);
        }
        final handle = tester.ensureSemantics();
        expect(
          tester.getSemantics(key('qiyam_rakah_chip_4')).label,
          contains('4'),
        );
        handle.dispose();
        expect(tester.widget<Switch>(key('qiyam_witr')).value, isTrue);
        expect(find.text('Saved'), findsOneWidget);
      },
    );

    qiyamTestWidgets('the status says Saving… while the save runs', (
      tester,
    ) async {
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      h.commands.gate = Completer<void>();
      await tapKey(tester, 'qiyam_yes');
      expect(find.text('Saving…'), findsOneWidget);
      h.commands.gate!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('Saving…'), findsNothing);
      expect(find.text('Saved'), findsOneWidget);
    });

    qiyamTestWidgets('Not yet is calm: no red, the can-change note, no details', (
      tester,
    ) async {
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      await tapKey(tester, 'qiyam_no');
      final draft = h.commands.drafts.single;
      expect(draft.performed, isFalse);
      expect(draft.rakahs, isNull);
      expect(
        find.text(
          'There is still time; you can change your answer to “Yes” at any point tonight.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Details are not kept with the answer “Not yet”.'),
        findsOneWidget,
      );
      expect(key('qiyam_rakah_chip_4'), findsNothing);
      expect(key('qiyam_celebration'), findsNothing);
      expect(find.textContaining('missed'), findsNothing);
      // No error color anywhere on the calm state.
      final errors = AppColors.light.error;
      final reds = tester
          .widgetList<Icon>(find.byType(Icon))
          .where(
            (icon) =>
                icon.color == errors || icon.color == AppColors.light.errorText,
          );
      expect(reds, isEmpty);
    });

    qiyamTestWidgets(
      'the answers switch freely all night, with no confirmation',
      (tester) async {
        await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
        await answerYes(tester);
        h.commands.outcome = const QiyamNightSaved(firstPerformed: false);
        await tapKey(tester, 'qiyam_seg_no');
        expect(h.commands.drafts.last.performed, isFalse);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(Dialog), findsNothing);
        expect(key('qiyam_rakah_chip_4'), findsNothing);
        await tapKey(tester, 'qiyam_seg_yes');
        expect(h.commands.drafts.last.performed, isTrue);
        expect(h.commands.drafts, hasLength(3));
        expect(key('qiyam_rakah_chip_4'), findsOneWidget);
        // Choosing the answer that is already chosen saves nothing.
        await tapKey(tester, 'qiyam_seg_yes');
        expect(h.commands.drafts, hasLength(3));
      },
    );

    qiyamTestWidgets('Yes -> No -> Yes shows the points badge once and never a '
        'second award', (tester) async {
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      await answerYes(tester);
      expect(find.text('Qiyam complete! +30 points'), findsOneWidget);
      h.commands.outcome = const QiyamNightSaved(firstPerformed: false);
      await tapKey(tester, 'qiyam_seg_no');
      expect(find.text('Qiyam complete! +30 points'), findsNothing);
      await tapKey(tester, 'qiyam_seg_yes');
      // The badge is the one earned this visit — it comes back with the Yes,
      // it is not a second award: no save reported one.
      expect(find.text('Qiyam complete! +30 points'), findsOneWidget);
      expect(
        h.commands.drafts.where((d) => d.performed).length,
        2,
        reason: 'two Yes saves, one first-performed outcome',
      );
    });

    qiyamTestWidgets(
      'the badge stays through edits until the page is left, and '
      'never shows for a night opened with a saved Yes',
      (tester) async {
        await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
        await answerYes(tester);
        h.commands.outcome = const QiyamNightSaved(firstPerformed: false);
        await tapKey(tester, 'qiyam_rakah_chip_8');
        await tapKey(tester, 'qiyam_witr');
        expect(key('qiyam_celebration'), findsOneWidget);

        // Opening the page later with the Yes already saved: the form shows at
        // once, with no badge.
        final reopened = QiyamHarness()
          ..repository.current = qiyamRecord('2026-11-11', rakahs: 8);
        await reopened.pump(
          tester,
          reopened.buildCubit(),
          locale: const Locale('en'),
        );
        expect(key('qiyam_celebration'), findsNothing);
        expect(key('qiyam_rakah_chip_8'), findsOneWidget);
        expect(find.text('Details (optional)'), findsOneWidget);
      },
    );

    qiyamTestWidgets('the night turning while the page is open says so and the '
        'new night is unanswered', (tester) async {
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      await answerYes(tester);
      expect(key('qiyam_answer_switch'), findsOneWidget);
      h.nightPort.state = qiyamAvailable('2026-11-12');
      h.commands.outcome = const QiyamNightChanged();
      await tapKey(tester, 'qiyam_rakah_chip_8');
      await tester.pump();
      expect(
        find.text('The night has changed; record the current night.'),
        findsOneWidget,
      );
      expect(key('qiyam_yes'), findsOneWidget, reason: 'unanswered again');
      expect(key('qiyam_celebration'), findsNothing);
    });

    qiyamTestWidgets('the keyboard reaches Yes and Enter answers it', (
      tester,
    ) async {
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      bool focusIsWithin(String keyValue) {
        final focus = FocusManager.instance.primaryFocus?.context;
        if (focus == null) return false;
        var inside = false;
        focus.visitAncestorElements((element) {
          if (element.widget.key == Key(keyValue)) {
            inside = true;
            return false;
          }
          return true;
        });
        return inside;
      }

      for (var i = 0; i < 15 && !focusIsWithin('qiyam_yes'); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(focusIsWithin('qiyam_yes'), isTrue, reason: 'Tab reaches Yes');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(h.commands.drafts, hasLength(1));
      expect(h.commands.drafts.single.performed, isTrue);
    });

    qiyamTestWidgets('the Yes button is announced to screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      expect(
        find.bySemanticsLabel(RegExp('Yes, praise be to God')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('details', () {
    Future<void> openDetails(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) async {
      await h.pump(tester, h.buildCubit(), locale: locale);
      await answerYes(tester);
      h.commands.outcome = const QiyamNightSaved(firstPerformed: false);
    }

    qiyamTestWidgets('a rak\'ah chip and the Witr switch save at once', (
      tester,
    ) async {
      await openDetails(tester);
      await tapKey(tester, 'qiyam_rakah_chip_8');
      expect(h.commands.drafts.last.rakahs, 8);
      await tapKey(tester, 'qiyam_witr');
      expect(h.commands.drafts.last.witr, isFalse);
      expect(h.commands.drafts.last.rakahs, 8);
    });

    // Opens a time field's dial and picks [hour]:[minute] on it.
    Future<void> pickTime(
      WidgetTester tester,
      String field,
      int hour,
      int minute,
    ) async {
      await tester.ensureVisible(key(field));
      await tester.pump();
      await tester.tap(key(field));
      await tester.pumpAndSettle();
      await pickDialTime(tester, hour, minute);
      await tester.pump();
      await tester.pump();
    }

    const outsideWindow = 'Pick a time between Isha (19:12) and Fajr (04:51).';
    const endNotAfterStart = 'The end time comes after the start time.';
    const startNotBeforeEnd = 'The start time comes before the end time.';

    qiyamTestWidgets('the times are never typed: a tap opens a dial with no '
        'text input', (tester) async {
      await openDetails(tester);
      expect(
        find.descendant(
          of: key('qiyam_start_time'),
          matching: find.byType(EditableText),
        ),
        findsNothing,
      );
      await tester.ensureVisible(key('qiyam_start_time'));
      await tester.pump();
      await tester.tap(key('qiyam_start_time'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TimePickerDialog),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      expect(find.byIcon(Icons.keyboard_outlined), findsNothing);
      // The dial opens at Isha for an empty start.
      expect(find.text('19'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      await cancelDial(tester);
      expect(h.commands.drafts.last.startTime, isNull);
    });

    qiyamTestWidgets('a pick inside the window saves at once and the field '
        'shows it', (tester) async {
      await openDetails(tester);
      await pickTime(tester, 'qiyam_start_time', 22, 30);
      expect(h.commands.drafts.last.startTime, '22:30');
      expect(find.text('22:30'), findsOneWidget);
      expect(find.text(outsideWindow), findsNothing);
    });

    qiyamTestWidgets('the end may cross midnight', (tester) async {
      await openDetails(tester);
      await pickTime(tester, 'qiyam_start_time', 23, 0);
      expect(h.commands.drafts.last.startTime, '23:00');
      await pickTime(tester, 'qiyam_end_time', 1, 0);
      expect(h.commands.drafts.last.endTime, '01:00');
      expect(h.commands.drafts.last.startTime, '23:00');
      expect(find.text(endNotAfterStart), findsNothing);
    });

    qiyamTestWidgets('Isha and Fajr themselves are accepted', (tester) async {
      await openDetails(tester);
      await pickTime(tester, 'qiyam_start_time', 19, 12);
      expect(h.commands.drafts.last.startTime, '19:12');
      await pickTime(tester, 'qiyam_end_time', 4, 51);
      expect(h.commands.drafts.last.endTime, '04:51');
    });

    qiyamTestWidgets('a pick outside Isha to Fajr is not saved and shows its '
        'message under its field', (tester) async {
      await openDetails(tester);
      final saved = h.commands.drafts.length;
      await pickTime(tester, 'qiyam_start_time', 18, 0);
      expect(find.text(outsideWindow), findsOneWidget);
      expect(
        find.descendant(
          of: key('qiyam_start_time_error').first,
          matching: find.text(outsideWindow),
        ),
        findsOneWidget,
      );
      expect(h.commands.drafts, hasLength(saved), reason: 'not saved');
      expect(find.text('18:00'), findsNothing);
      // After Fajr is refused too, then a valid pick clears the message.
      await pickTime(tester, 'qiyam_end_time', 5, 30);
      expect(find.text(outsideWindow), findsNWidgets(2));
      expect(h.commands.drafts, hasLength(saved));
      await pickTime(tester, 'qiyam_start_time', 20, 0);
      expect(find.text(outsideWindow), findsOneWidget);
      expect(h.commands.drafts.last.startTime, '20:00');
    });

    qiyamTestWidgets('an end that is not after the start is not saved', (
      tester,
    ) async {
      await openDetails(tester);
      await pickTime(tester, 'qiyam_start_time', 23, 0);
      final saved = h.commands.drafts.length;
      await pickTime(tester, 'qiyam_end_time', 22, 0);
      expect(find.text(endNotAfterStart), findsOneWidget);
      expect(h.commands.drafts, hasLength(saved));
      // The same minute is not after the start either.
      await pickTime(tester, 'qiyam_end_time', 23, 0);
      expect(find.text(endNotAfterStart), findsOneWidget);
      expect(h.commands.drafts, hasLength(saved));
      await pickTime(tester, 'qiyam_end_time', 23, 1);
      expect(find.text(endNotAfterStart), findsNothing);
      expect(h.commands.drafts.last.endTime, '23:01');
    });

    qiyamTestWidgets('a start that is not before the saved end is not saved', (
      tester,
    ) async {
      await openDetails(tester);
      await pickTime(tester, 'qiyam_start_time', 23, 0);
      await pickTime(tester, 'qiyam_end_time', 1, 0);
      final saved = h.commands.drafts.length;
      // Later than the end (04:00 is after 01:00 across midnight).
      await pickTime(tester, 'qiyam_start_time', 4, 0);
      expect(find.text(startNotBeforeEnd), findsOneWidget);
      expect(
        find.descendant(
          of: key('qiyam_start_time_error'),
          matching: find.text(startNotBeforeEnd),
        ),
        findsOneWidget,
      );
      expect(h.commands.drafts, hasLength(saved));
      expect(h.commands.drafts.last.startTime, '23:00');
      // The same minute is not before the end either.
      await pickTime(tester, 'qiyam_start_time', 1, 0);
      expect(find.text(startNotBeforeEnd), findsOneWidget);
      expect(h.commands.drafts, hasLength(saved));
      // Across midnight is fine: 22:30 is before 01:00 of the same night.
      await pickTime(tester, 'qiyam_start_time', 22, 30);
      expect(find.text(startNotBeforeEnd), findsNothing);
      expect(h.commands.drafts.last.startTime, '22:30');
      expect(h.commands.drafts.last.endTime, '01:00');
    });

    qiyamTestWidgets('a start is not checked against an end that is not '
        'saved, nor without a window', (tester) async {
      await openDetails(tester);
      await pickTime(tester, 'qiyam_start_time', 3, 0);
      expect(h.commands.drafts.last.startTime, '03:00');
      h = QiyamHarness(night: qiyamSetupRequired());
      await openDetails(tester);
      await pickTime(tester, 'qiyam_end_time', 7, 30);
      await pickTime(tester, 'qiyam_start_time', 12, 0);
      expect(h.commands.drafts.last.startTime, '12:00');
      expect(find.text(startNotBeforeEnd), findsNothing);
    });

    qiyamTestWidgets('the end dial opens an hour after the start, never past '
        'Fajr', (tester) async {
      await openDetails(tester);
      await pickTime(tester, 'qiyam_start_time', 23, 30);
      await tester.tap(key('qiyam_end_time'));
      await tester.pumpAndSettle();
      expect(find.text('00'), findsWidgets);
      expect(find.text('30'), findsOneWidget);
      await cancelDial(tester);
      await pickTime(tester, 'qiyam_start_time', 4, 30);
      // 04:30 + 1 h is after Fajr (04:51), so the dial opens at Fajr.
      await tester.tap(key('qiyam_end_time'));
      await tester.pumpAndSettle();
      expect(find.text('04'), findsOneWidget);
      expect(find.text('51'), findsOneWidget);
      await cancelDial(tester);
    });

    qiyamTestWidgets('no saved location: any time is accepted', (tester) async {
      h = QiyamHarness(night: qiyamSetupRequired());
      await openDetails(tester);
      await pickTime(tester, 'qiyam_start_time', 12, 0);
      expect(h.commands.drafts.last.startTime, '12:00');
      await pickTime(tester, 'qiyam_end_time', 7, 30);
      expect(h.commands.drafts.last.endTime, '07:30');
      expect(find.text(outsideWindow), findsNothing);
      expect(find.text(endNotAfterStart), findsNothing);
    });

    qiyamTestWidgets('a saved schedule with no Isha has no window either', (
      tester,
    ) async {
      h = QiyamHarness(night: qiyamAvailableNoIsha());
      await openDetails(tester);
      await pickTime(tester, 'qiyam_start_time', 15, 0);
      expect(h.commands.drafts.last.startTime, '15:00');
      expect(find.text(outsideWindow), findsNothing);
    });

    qiyamTestWidgets('the message and the window are in Arabic too', (
      tester,
    ) async {
      await openDetails(tester, locale: const Locale('ar'));
      await pickTime(tester, 'qiyam_start_time', 18, 0);
      expect(find.textContaining('اختر وقتًا بين العشاء ('), findsOneWidget);
      expect(find.textContaining('والفجر ('), findsOneWidget);
      await pickTime(tester, 'qiyam_start_time', 23, 0);
      await pickTime(tester, 'qiyam_end_time', 22, 0);
      expect(find.text('وقت النهاية بعد وقت البداية.'), findsOneWidget);
      await pickTime(tester, 'qiyam_end_time', 1, 0);
      await pickTime(tester, 'qiyam_start_time', 4, 0);
      expect(find.text('وقت البداية قبل وقت النهاية.'), findsOneWidget);
    });

    qiyamTestWidgets('Arabic shows Arabic-Indic digits everywhere on the page: '
        'the chip, the fields and the message', (tester) async {
      await openDetails(tester, locale: const Locale('ar'));
      await pickTime(tester, 'qiyam_start_time', 22, 30);
      expect(find.text('٢٢:٣٠'), findsOneWidget);
      expect(find.text('22:30'), findsNothing);
      expect(
        find.text('الثلث الأخير من الليل ٠١:٤٠'),
        findsOneWidget,
        reason: 'the chip uses the same digits',
      );
      await pickTime(tester, 'qiyam_end_time', 5, 30);
      expect(
        find.text('اختر وقتًا بين العشاء (١٩:١٢) والفجر (٠٤:٥١).'),
        findsOneWidget,
      );
    });

    qiyamTestWidgets(
      'the note saves about a second after typing stops and shows '
      'its counter',
      (tester) async {
        await openDetails(tester);
        final before = h.commands.drafts.length;
        await tester.enterText(key('qiyam_note'), 'abc');
        await tester.pump();
        expect(find.text('3 / 500'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 900));
        expect(h.commands.drafts.length, before, reason: 'still waiting');
        await tester.enterText(key('qiyam_note'), 'abcd');
        await tester.pump(const Duration(milliseconds: 900));
        expect(h.commands.drafts.length, before, reason: 'typing restarts it');
        await QiyamHarness.settle(tester);
        expect(h.commands.drafts.length, before + 1);
        expect(h.commands.drafts.last.note, 'abcd');
      },
    );

    qiyamTestWidgets('a rejected rakah count shows its message under the '
        'chips', (tester) async {
      await openDetails(tester);
      h.commands.failure = qiyamValidationFailure('qiyam.night.invalid_rakahs');
      await tapKey(tester, 'qiyam_rakah_chip_8');
      expect(
        find.text('Choose a whole number of rak’ahs (2, 4, 8 or 11).'),
        findsOneWidget,
      );
      expect(find.text('Could not save. Try again.'), findsNothing);
    });

    qiyamTestWidgets('a note over 500 characters shows the counter and the '
        'message at once, and is not saved', (tester) async {
      await openDetails(tester);
      h.commands.failure = qiyamValidationFailure('qiyam.night.note_too_long');
      await tester.enterText(key('qiyam_note'), 'a' * 505);
      await tester.pump();
      expect(find.text('505 / 500'), findsOneWidget);
      expect(
        find.text('The note is longer than 500 characters.'),
        findsOneWidget,
      );
      await QiyamHarness.settle(tester);
      expect(
        find.text('The note is longer than 500 characters.'),
        findsOneWidget,
        reason: 'one message, not two',
      );
    });

    qiyamTestWidgets(
      'a failed save says so, keeps what was typed, and the next '
      'change retries',
      (tester) async {
        await openDetails(tester);
        h.commands.failure = qiyamPersistenceFailure();
        await tester.enterText(key('qiyam_note'), 'kept text');
        await QiyamHarness.settle(tester);
        expect(find.text('Could not save. Try again.'), findsOneWidget);
        expect(
          tester.widget<TextField>(key('qiyam_note')).controller!.text,
          'kept text',
        );
        h.commands.failure = null;
        await tester.enterText(key('qiyam_note'), 'kept text more');
        await QiyamHarness.settle(tester);
        expect(find.text('Could not save. Try again.'), findsNothing);
        expect(find.text('Saved'), findsOneWidget);
        expect(h.commands.drafts.last.note, 'kept text more');
      },
    );

    qiyamTestWidgets('opening with a saved record shows its values', (
      tester,
    ) async {
      h.repository.current = qiyamRecord(
        '2026-11-11',
        rakahs: 11,
        witr: false,
        startTime: '02:41',
        endTime: '03:35',
        note: 'a saved note',
      );
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      expect(tester.widget<Switch>(key('qiyam_witr')).value, isFalse);
      expect(
        find.descendant(
          of: key('qiyam_start_time'),
          matching: find.text('02:41'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: key('qiyam_end_time'),
          matching: find.text('03:35'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(key('qiyam_note')).controller!.text,
        'a saved note',
      );
      expect(find.text('11'), findsOneWidget);
    });
  });

  group('supplications', () {
    qiyamTestWidgets('each is collapsed to four lines with Show all, then Show '
        'less', (tester) async {
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      expect(
        find.text('Transmitted supplications for prostration and Qunut'),
        findsOneWidget,
      );
      expect(find.text('Witr supplication'), findsOneWidget);
      expect(find.text('Qunut'), findsOneWidget);
      expect(find.text('Show all'), findsNWidgets(2));
      Text text(String id) =>
          tester.widget<Text>(key('qiyam_supplication_$id'));
      expect(text('s1').maxLines, 4);
      expect(text('s1').style?.fontFamily, 'Amiri');
      await tapKey(tester, 'qiyam_supplication_toggle_s1');
      expect(text('s1').maxLines, isNull);
      expect(text('s2').maxLines, 4, reason: 'each opens on its own');
      expect(find.text('Show less'), findsOneWidget);
      await tapKey(tester, 'qiyam_supplication_toggle_s1');
      expect(text('s1').maxLines, 4);
      expect(find.text('test source s1'), findsOneWidget);
    });

    qiyamTestWidgets('the text is selectable and keeps its right-to-left '
        'direction', (tester) async {
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      expect(
        find.descendant(
          of: key('qiyam_supplications_card'),
          matching: find.byType(SelectionArea),
        ),
        findsOneWidget,
      );
      final direction = tester
          .widget<Directionality>(
            find
                .ancestor(
                  of: key('qiyam_supplication_s1'),
                  matching: find.byType(Directionality),
                )
                .first,
          )
          .textDirection;
      expect(direction, TextDirection.rtl);
    });
  });

  group('history', () {
    void seed(int count) {
      var day = DateTime.utc(2026, 11, 10);
      for (var i = 0; i < count; i++) {
        final nightKey =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        h.repository.seeded[nightKey] = qiyamRecord(
          nightKey,
          performed: i.isEven,
          rakahs: i % 4 == 0 ? 2 : 4,
          witr: i % 3 == 0,
        );
        day = day.subtract(const Duration(days: 1));
      }
    }

    qiyamTestWidgets(
      '30 nights a page; Load more appends the next page without '
      'moving the list',
      (tester) async {
        seed(35);
        await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
        expect(find.text('Previous nights'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w.key is Key && '${w.key}'.contains('qiyam_history_row_'),
          ),
          findsNWidgets(30),
        );
        expect(h.repository.pageLimits, everyElement(30));
        await tester.ensureVisible(key('qiyam_load_more'));
        await tester.pump();
        final firstRow = tester.getTopLeft(key('qiyam_history_row_2026-11-10'));
        await tester.tap(key('qiyam_load_more'));
        await tester.pump();
        await tester.pump();
        expect(
          tester.getTopLeft(key('qiyam_history_row_2026-11-10')),
          firstRow,
          reason: 'the page does not jump',
        );
        expect(
          find.byWidgetPredicate(
            (w) => w.key is Key && '${w.key}'.contains('qiyam_history_row_'),
            skipOffstage: false,
          ),
          findsNWidgets(35),
        );
        expect(key('qiyam_load_more'), findsNothing);
      },
    );

    qiyamTestWidgets('each night reads in its four forms and "missed" never '
        'appears', (tester) async {
      h.repository.seeded['2026-11-10'] = qiyamRecord('2026-11-10');
      h.repository.seeded['2026-11-09'] = qiyamRecord(
        '2026-11-09',
        rakahs: 2,
        witr: false,
      );
      h.repository.seeded['2026-11-08'] = qiyamRecord(
        '2026-11-08',
        performed: false,
      );
      h.repository.seeded['2026-11-06'] = qiyamRecord('2026-11-06');
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      expect(find.text('Prayed · 4 rak’ahs · with Witr'), findsWidgets);
      expect(find.text('Prayed · 2 rak’ahs'), findsOneWidget);
      expect(find.text('Did not pray'), findsOneWidget);
      expect(find.text('Not recorded'), findsOneWidget);
      expect(find.textContaining('issed'), findsNothing);
      // Newest first.
      expect(
        tester.getTopLeft(key('qiyam_history_row_2026-11-10')).dy,
        lessThan(tester.getTopLeft(key('qiyam_history_row_2026-11-09')).dy),
      );
    });

    qiyamTestWidgets('the Arabic forms', (tester) async {
      h.repository.seeded['2026-11-10'] = qiyamRecord('2026-11-10');
      h.repository.seeded['2026-11-09'] = qiyamRecord(
        '2026-11-09',
        rakahs: 2,
        witr: false,
      );
      h.repository.seeded['2026-11-08'] = qiyamRecord(
        '2026-11-08',
        performed: false,
      );
      await h.pump(tester, h.buildCubit());
      expect(find.text('صلى · 4 ركعات · بالوتر'), findsOneWidget);
      expect(find.text('صلى · ركعتان'), findsOneWidget);
      expect(find.text('لم يصلِّ'), findsOneWidget);
      expect(find.textContaining('فات'), findsNothing);
    });

    qiyamTestWidgets(
      'an error shows its message with Try again, never an empty '
      'history',
      (tester) async {
        h.repository.failHistory = true;
        await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
        expect(find.text('Could not load previous nights.'), findsOneWidget);
        expect(key('qiyam_history_failed'), findsOneWidget);
        h.repository.failHistory = false;
        h.repository.seeded['2026-11-10'] = qiyamRecord('2026-11-10');
        await tapKey(tester, 'qiyam_history_retry');
        expect(key('qiyam_history_failed'), findsNothing);
        expect(key('qiyam_history_row_2026-11-10'), findsOneWidget);
      },
    );

    qiyamTestWidgets('nothing recorded yet: the section stays out of the way', (
      tester,
    ) async {
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      expect(find.text('Previous nights'), findsNothing);
      expect(key('qiyam_load_more'), findsNothing);
    });

    qiyamTestWidgets('tapping a night opens read-only details in a sheet on a '
        'phone', (tester) async {
      h.repository.seeded['2026-11-10'] = qiyamRecord(
        '2026-11-10',
        startTime: '02:41',
        endTime: '03:35',
        note: 'a private note',
      );
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      await tapKey(tester, 'qiyam_history_row_2026-11-10');
      await tester.pumpAndSettle();
      expect(key('qiyam_night_details'), findsOneWidget);
      expect(find.byType(AppSheetHandle), findsOneWidget);
      expect(find.text('Night details'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Prayed'), findsOneWidget);
      expect(find.text('02:41'), findsOneWidget);
      expect(find.text('03:35'), findsOneWidget);
      expect(find.text('a private note'), findsOneWidget);
      expect(find.text('This night’s record is view only.'), findsOneWidget);
      // Read-only: no field in the sheet, and Close is the only action.
      expect(
        find.descendant(
          of: key('qiyam_night_details'),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      await tester.tap(key('qiyam_night_details_close'));
      await tester.pumpAndSettle();
      expect(key('qiyam_night_details'), findsNothing);
    });

    qiyamTestWidgets('on a wide window the details open in a dialog', (
      tester,
    ) async {
      h.repository.seeded['2026-11-10'] = qiyamRecord('2026-11-10');
      await h.pump(
        tester,
        h.buildCubit(),
        locale: const Locale('en'),
        size: const Size(1280, 900),
      );
      await tapKey(tester, 'qiyam_history_row_2026-11-10');
      await tester.pumpAndSettle();
      expect(key('qiyam_night_details'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(AppSheetHandle), findsNothing);
    });

    qiyamTestWidgets('a No night and an unrecorded night open with only their '
        'status', (tester) async {
      h.repository.seeded['2026-11-10'] = qiyamRecord(
        '2026-11-10',
        performed: false,
      );
      h.repository.seeded['2026-11-08'] = qiyamRecord('2026-11-08');
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      await tapKey(tester, 'qiyam_history_row_2026-11-10');
      await tester.pumpAndSettle();
      expect(find.text('Did not pray'), findsWidgets);
      expect(find.text('Witr'), findsNothing);
      await tester.tap(key('qiyam_night_details_close'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'qiyam_history_row_2026-11-09');
      await tester.pumpAndSettle();
      expect(find.text('Not recorded'), findsWidgets);
      expect(find.text('Number of rak’ahs'), findsNothing);
    });

    qiyamTestWidgets('device back closes the night details first', (
      tester,
    ) async {
      h.repository.seeded['2026-11-10'] = qiyamRecord('2026-11-10');
      await h.pump(tester, h.buildCubit(), locale: const Locale('en'));
      await tapKey(tester, 'qiyam_history_row_2026-11-10');
      await tester.pumpAndSettle();
      expect(key('qiyam_night_details'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(key('qiyam_night_details'), findsNothing);
      expect(key('qiyam_header'), findsOneWidget, reason: 'still on the page');
    });
  });

  group('layout', () {
    qiyamTestWidgets('from 1024 px the history sits in a 360 px side column, '
        'below that it follows the supplications', (tester) async {
      h.repository.seeded['2026-11-10'] = qiyamRecord('2026-11-10');
      await h.pump(
        tester,
        h.buildCubit(),
        locale: const Locale('en'),
        size: const Size(1280, 900),
      );
      expect(
        tester.getTopLeft(key('qiyam_history_section')).dy,
        tester.getTopLeft(key('qiyam_header')).dy,
        reason: 'a side column beside the main one',
      );
      expect(tester.getSize(key('qiyam_history_section')).width, 360);

      final narrow = QiyamHarness()
        ..repository.seeded['2026-11-10'] = qiyamRecord('2026-11-10');
      await narrow.pump(
        tester,
        narrow.buildCubit(),
        locale: const Locale('en'),
        size: const Size(1000, 900),
      );
      expect(
        tester.getTopLeft(key('qiyam_history_section')).dy,
        greaterThan(tester.getTopLeft(key('qiyam_supplications_card')).dy),
      );
    });

    qiyamTestWidgets('right to left puts the side column on the left, left to '
        'right on the right', (tester) async {
      h.repository.seeded['2026-11-10'] = qiyamRecord('2026-11-10');
      await h.pump(tester, h.buildCubit(), size: const Size(1280, 900));
      final rtlHistory = tester.getCenter(key('qiyam_history_section')).dx;
      final rtlMain = tester.getCenter(key('qiyam_tracker_card')).dx;
      expect(rtlHistory, lessThan(rtlMain));

      final ltr = QiyamHarness()
        ..repository.seeded['2026-11-10'] = qiyamRecord('2026-11-10');
      await ltr.pump(
        tester,
        ltr.buildCubit(),
        locale: const Locale('en'),
        size: const Size(1280, 900),
      );
      expect(
        tester.getCenter(key('qiyam_history_section')).dx,
        greaterThan(tester.getCenter(key('qiyam_tracker_card')).dx),
      );
    });
  });

  group('every state at AR/EN, light/dark, 320 px and 200% text', () {
    final states = <String, Future<void> Function(WidgetTester, QiyamHarness)>{
      'unanswered': (tester, h) async {},
      'yes with details': (tester, h) async {
        h.commands.outcome = const QiyamNightSaved(firstPerformed: true);
        await _tapVisible(tester, const Key('qiyam_yes'));
        await tester.pump();
        await tester.pump();
      },
      'yes with a long note and times': (tester, h) async {
        h.repository.current = qiyamRecord(
          '2026-11-11',
          rakahs: 11,
          startTime: '02:41',
          endTime: '03:35',
          note: 'long ' * 40,
        );
      },
      'no': (tester, h) async {
        await _tapVisible(tester, const Key('qiyam_no'));
        await tester.pump();
        await tester.pump();
      },
      'paused': (tester, h) async {},
      'no saved location': (tester, h) async {},
      'save failed': (tester, h) async {
        h.commands.outcome = const QiyamNightSaved(firstPerformed: false);
        await _tapVisible(tester, const Key('qiyam_yes'));
        await tester.pump();
        await tester.pump();
        h.commands.failure = qiyamPersistenceFailure();
        await _tapVisible(tester, const Key('qiyam_rakah_chip_8'));
        await tester.pump();
        await tester.pump();
      },
      'validation errors': (tester, h) async {
        h.commands.outcome = const QiyamNightSaved(firstPerformed: false);
        await _tapVisible(tester, const Key('qiyam_yes'));
        await tester.pump();
        await tester.pump();
        await _tapVisible(tester, const Key('qiyam_start_time'));
        await tester.pumpAndSettle();
        await pickDialTime(tester, 18, 0);
        h.commands.failure = qiyamValidationFailure(
          'qiyam.night.note_too_long',
        );
        await tester.enterText(find.byKey(const Key('qiyam_note')), 'a' * 512);
        await tester.pump(const Duration(milliseconds: 1100));
        await tester.pump();
      },
      'night changed': (tester, h) async {
        h.commands.outcome = const QiyamNightChanged();
        h.nightPort.state = qiyamAvailable('2026-11-12');
        await _tapVisible(tester, const Key('qiyam_yes'));
        await tester.pump();
        await tester.pump();
      },
      'streak failed and history error': (tester, h) async {},
      'history with a night open': (tester, h) async {
        await tester.ensureVisible(
          find.byKey(const Key('qiyam_history_row_2026-11-10')),
        );
        await tester.pump();
        await _tapVisible(tester, const Key('qiyam_history_row_2026-11-10'));
        await tester.pumpAndSettle();
      },
      'supplications open': (tester, h) async {
        for (final id in ['s1', 's2']) {
          final toggle = find.byKey(Key('qiyam_supplication_toggle_$id'));
          await tester.ensureVisible(toggle);
          await tester.pump();
          await tester.tap(toggle);
          await tester.pump();
        }
      },
    };

    for (final locale in const [Locale('ar'), Locale('en')]) {
      for (final brightness in Brightness.values) {
        for (final entry in states.entries) {
          qiyamTestWidgets('${entry.key} - $locale $brightness', (
            tester,
          ) async {
            final harness = switch (entry.key) {
              'paused' => QiyamHarness(night: kQiyamUnavailable),
              'no saved location' => QiyamHarness(night: qiyamSetupRequired()),
              _ => QiyamHarness(),
            };
            harness.repository.seeded['2026-11-10'] = qiyamRecord(
              '2026-11-10',
              note: 'a note',
            );
            harness.repository.seeded['2026-11-09'] = qiyamRecord(
              '2026-11-09',
              performed: false,
            );
            if (entry.key == 'streak failed and history error') {
              harness.repository
                ..failStreak = true
                ..failHistory = true;
            }
            await harness.pump(
              tester,
              harness.buildCubit(),
              locale: locale,
              brightness: brightness,
              size: const Size(320, 900),
              textScale: 2.0,
              onOpenPrayerSetup: () {},
            );
            await entry.value(tester, harness);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}

/// Scrolls [key] into view, then taps it (the narrow, enlarged-text layouts
/// are longer than the screen).
Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump();
}
