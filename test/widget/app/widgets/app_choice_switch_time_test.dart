import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_choice_chip.dart';
import 'package:namma_project/app/widgets/app_switch_tile.dart';
import 'package:namma_project/app/widgets/app_time_field.dart';

import '../../../support/shared_widget_harness.dart';
import '../../../support/time_dial_support.dart';

AppColors _colors(Brightness brightness) =>
    brightness == Brightness.dark ? AppColors.dark : AppColors.light;

BoxDecoration _surface(WidgetTester tester, Finder owner) {
  final material = tester.widget<Material>(
    find.descendant(of: owner, matching: find.byType(Material)).first,
  );
  final shape = material.shape! as StadiumBorder;
  return BoxDecoration(
    color: material.color,
    border: Border.fromBorderSide(shape.side),
  );
}

void main() {
  group('AppChoiceChip', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('the selected choice takes the accent tokens ($name)', (
        tester,
      ) async {
        final colors = _colors(brightness);
        var picked = 0;
        await pumpShared(
          tester,
          Wrap(
            spacing: 8,
            children: [
              for (final n in [2, 4])
                AppChoiceChip(
                  key: Key('chip_$n'),
                  label: '$n',
                  semanticLabel: '$n rak ahs',
                  selected: n == 4,
                  onSelected: () => picked = n,
                ),
            ],
          ),
          brightness: brightness,
          direction: direction,
        );
        final selected = _surface(tester, find.byKey(const Key('chip_4')));
        final idle = _surface(tester, find.byKey(const Key('chip_2')));
        expect(selected.color, colors.accentSoft);
        expect((selected.border! as Border).top.color, colors.primary);
        expect(idle.color, colors.surfaceSecondary);
        expect((idle.border! as Border).top.color, colors.border);
        final size = tester.getSize(find.byKey(const Key('chip_2')));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(56));
        await tester.tap(find.byKey(const Key('chip_2')));
        expect(picked, 2);
      });
    }

    testWidgets('announces itself as a selected button with its own label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpShared(
        tester,
        AppChoiceChip(
          key: const Key('chip'),
          label: '4',
          semanticLabel: '4 rak ahs',
          selected: true,
          onSelected: () {},
        ),
      );
      final node = tester.getSemantics(find.byKey(const Key('chip')));
      expect(node.label, '4 rak ahs');
      expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('a null callback disables it', (tester) async {
      await pumpShared(
        tester,
        const AppChoiceChip(
          key: Key('chip'),
          label: '8',
          selected: false,
          onSelected: null,
        ),
      );
      await tester.tap(find.byKey(const Key('chip')), warnIfMissed: false);
      expect(tester.takeException(), isNull);
    });
  });

  group('AppSwitchTile', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('toggles and takes its colors from tokens ($name)', (
        tester,
      ) async {
        final colors = _colors(brightness);
        var value = true;
        await pumpShared(
          tester,
          StatefulBuilder(
            builder: (context, setState) => AppSwitchTile(
              label: 'I prayed Witr',
              value: value,
              onChanged: (next) => setState(() => value = next),
              switchKey: const Key('switch'),
            ),
          ),
          brightness: brightness,
          direction: direction,
        );
        final theme = Theme.of(tester.element(find.byKey(const Key('switch'))));
        expect(
          theme.switchTheme.trackColor!.resolve({WidgetState.selected}),
          colors.accentStrong,
        );
        expect(
          theme.switchTheme.thumbColor!.resolve({WidgetState.selected}),
          colors.onAccentStrong,
        );
        expect(
          theme.switchTheme.trackColor!.resolve(<WidgetState>{}),
          colors.surfaceSecondary,
        );
        expect(
          tester.getSize(find.byType(AppSwitchTile)).height,
          greaterThanOrEqualTo(48),
        );
        await tester.tap(find.byKey(const Key('switch')));
        await tester.pump();
        expect(value, isFalse);
        expect(
          tester.widget<Switch>(find.byKey(const Key('switch'))).value,
          isFalse,
        );
      });
    }

    testWidgets('the label and the switch read as one control', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpShared(
        tester,
        AppSwitchTile(
          key: const Key('tile'),
          label: 'I prayed Witr',
          value: true,
          onChanged: (_) {},
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('tile'))).label,
        contains('I prayed Witr'),
      );
      handle.dispose();
    });
  });

  group('AppTimeWindow', () {
    test('a window inside one day holds its ends and nothing outside', () {
      const window = AppTimeWindow(
        start: TimeOfDay(hour: 9, minute: 0),
        end: TimeOfDay(hour: 17, minute: 30),
      );
      expect(window.contains(const TimeOfDay(hour: 9, minute: 0)), isTrue);
      expect(window.contains(const TimeOfDay(hour: 17, minute: 30)), isTrue);
      expect(window.contains(const TimeOfDay(hour: 12, minute: 0)), isTrue);
      expect(window.contains(const TimeOfDay(hour: 8, minute: 59)), isFalse);
      expect(window.contains(const TimeOfDay(hour: 17, minute: 31)), isFalse);
    });

    test('a window may cross midnight', () {
      const window = AppTimeWindow(
        start: TimeOfDay(hour: 19, minute: 12),
        end: TimeOfDay(hour: 4, minute: 51),
      );
      expect(window.length, 9 * 60 + 39);
      expect(window.contains(const TimeOfDay(hour: 19, minute: 12)), isTrue);
      expect(window.contains(const TimeOfDay(hour: 23, minute: 59)), isTrue);
      expect(window.contains(const TimeOfDay(hour: 0, minute: 0)), isTrue);
      expect(window.contains(const TimeOfDay(hour: 4, minute: 51)), isTrue);
      expect(window.contains(const TimeOfDay(hour: 4, minute: 52)), isFalse);
      expect(window.contains(const TimeOfDay(hour: 12, minute: 0)), isFalse);
      expect(window.contains(const TimeOfDay(hour: 19, minute: 11)), isFalse);
    });

    test('offsetOf orders times from the start, past midnight too', () {
      const window = AppTimeWindow(
        start: TimeOfDay(hour: 19, minute: 12),
        end: TimeOfDay(hour: 4, minute: 51),
      );
      expect(
        window.offsetOf(const TimeOfDay(hour: 23, minute: 0)),
        lessThan(window.offsetOf(const TimeOfDay(hour: 1, minute: 0))),
      );
      expect(window.offsetOf(const TimeOfDay(hour: 19, minute: 12)), 0);
    });

    test('shifted wraps around midnight', () {
      expect(
        AppTimeWindow.shifted(const TimeOfDay(hour: 23, minute: 30), 60),
        const TimeOfDay(hour: 0, minute: 30),
      );
    });
  });

  group('AppTimeField', () {
    Widget field(
      List<TimeOfDay> picks, {
      TimeOfDay? value = const TimeOfDay(hour: 13, minute: 5),
      String? Function(TimeOfDay)? validator,
      bool enabled = true,
    }) => AppTimeField(
      fieldKey: const Key('time'),
      errorKey: const Key('time_error'),
      value: value,
      semanticLabel: 'Start time',
      pickHint: 'Pick a time',
      validator: validator,
      enabled: enabled,
      onPicked: picks.add,
    );

    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('shows the time left to right with a clock icon ($name)', (
        tester,
      ) async {
        await pumpShared(
          tester,
          SizedBox(width: 200, child: field(<TimeOfDay>[])),
          brightness: brightness,
          direction: direction,
        );
        expect(find.text('13:05'), findsOneWidget);
        expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
        // It is not a text input: nothing to type into.
        expect(find.byType(TextField), findsNothing);
        expect(find.byType(EditableText), findsNothing);
        // The clock sits on the right whatever the page direction.
        expect(
          tester.getCenter(find.byIcon(Icons.schedule_rounded)).dx,
          greaterThan(tester.getCenter(find.text('13:05')).dx),
        );
      });
    }

    testWidgets('Arabic shows Arabic-Indic digits, English Latin ones', (
      tester,
    ) async {
      Future<void> pumpIn(Locale locale) async {
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            locale: locale,
            supportedLocales: [locale],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(body: field(<TimeOfDay>[])),
          ),
        );
      }

      await pumpIn(const Locale('ar'));
      expect(find.text('١٣:٠٥'), findsOneWidget);
      await pumpIn(const Locale('en'));
      expect(find.text('13:05'), findsOneWidget);
    });

    testWidgets('an empty field shows the placeholder', (tester) async {
      await pumpShared(tester, field(<TimeOfDay>[], value: null));
      expect(find.text('--:--'), findsOneWidget);
    });

    testWidgets('a tap opens the dial only, with no keyboard entry', (
      tester,
    ) async {
      await pumpShared(
        tester,
        field(<TimeOfDay>[]),
        size: const Size(800, 900),
      );
      await tester.tap(find.byKey(const Key('time')));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      // The dial is shown and there is no text input and no button to switch
      // to one.
      expect(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Dial'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.keyboard_outlined), findsNothing);
      expect(find.byIcon(Icons.keyboard), findsNothing);
      // 24-hour form: no AM/PM selector.
      expect(find.text('AM'), findsNothing);
      expect(find.text('PM'), findsNothing);
      await confirmDial(tester);
    });

    testWidgets('a dial pick is passed on and a cancel changes nothing', (
      tester,
    ) async {
      final picks = <TimeOfDay>[];
      await pumpShared(tester, field(picks), size: const Size(800, 900));
      await tester.tap(find.byKey(const Key('time')));
      await tester.pumpAndSettle();
      await cancelDial(tester);
      expect(picks, isEmpty);
      await tester.tap(find.byKey(const Key('time')));
      await tester.pumpAndSettle();
      await pickDialTime(tester, 22, 40);
      expect(picks, [const TimeOfDay(hour: 22, minute: 40)]);
    });

    testWidgets('with no value the dial opens at the initial time', (
      tester,
    ) async {
      await pumpShared(
        tester,
        AppTimeField(
          fieldKey: const Key('time'),
          value: null,
          initialTime: const TimeOfDay(hour: 19, minute: 12),
          semanticLabel: 'Start time',
          pickHint: 'Pick a time',
          onPicked: (_) {},
        ),
        size: const Size(800, 900),
      );
      await tester.tap(find.byKey(const Key('time')));
      await tester.pumpAndSettle();
      expect(find.text('19'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      await cancelDial(tester);
    });

    testWidgets('a refused pick is not passed on, shows its message and a '
        'valid pick clears it', (tester) async {
      final picks = <TimeOfDay>[];
      await pumpShared(
        tester,
        field(
          picks,
          validator: (t) => t.hour < 20 ? 'Pick a later time.' : null,
        ),
        size: const Size(800, 900),
      );
      await tester.tap(find.byKey(const Key('time')));
      await tester.pumpAndSettle();
      await pickDialTime(tester, 10, 15);
      expect(picks, isEmpty);
      expect(find.byKey(const Key('time_error')), findsOneWidget);
      expect(find.text('Pick a later time.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('time')));
      await tester.pumpAndSettle();
      await pickDialTime(tester, 21, 0);
      expect(picks, [const TimeOfDay(hour: 21, minute: 0)]);
      expect(find.text('Pick a later time.'), findsNothing);
    });

    testWidgets('Enter and Space on the focused field open the dial', (
      tester,
    ) async {
      await pumpShared(
        tester,
        field(<TimeOfDay>[]),
        size: const Size(800, 900),
      );
      for (final id in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
        // Tab moves the focus onto the field.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(id);
        await tester.pumpAndSettle();
        expect(find.byType(TimePickerDialog), findsOneWidget, reason: '$id');
        await cancelDial(tester);
      }
    });

    testWidgets('announces its name, its time and that it is a button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpShared(tester, field(<TimeOfDay>[]));
      final node = tester.getSemantics(find.byKey(const Key('time')));
      expect(node.label, 'Start time');
      expect(node.value, '13:05');
      expect(node.hint, 'Pick a time');
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('a disabled field does not open the dial', (tester) async {
      await pumpShared(tester, field(<TimeOfDay>[], enabled: false));
      await tester.tap(find.byKey(const Key('time')));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsNothing);
    });

    testWidgets('fits at 320 px and 200% text, with its message', (
      tester,
    ) async {
      await pumpShared(
        tester,
        field(
          <TimeOfDay>[],
          validator: (_) =>
              'Pick a time between Isha (19:12) and Fajr (04:51).',
        ),
        size: const Size(320, 640),
        textScale: 2,
      );
      await tester.tap(find.byKey(const Key('time')));
      await tester.pumpAndSettle();
      await pickDialTime(tester, 10, 0);
      expect(
        find.text('Pick a time between Isha (19:12) and Fajr (04:51).'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
