import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_choice_chip.dart';
import 'package:namma_project/app/widgets/app_switch_tile.dart';
import 'package:namma_project/app/widgets/app_time_field.dart';

import '../../../support/shared_widget_harness.dart';

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

  group('AppTimeField', () {
    Widget field(
      TextEditingController controller,
      List<String> changes, {
      bool invalid = false,
    }) => AppTimeField(
      fieldKey: const Key('time'),
      pickerKey: const Key('clock'),
      controller: controller,
      invalid: invalid,
      pickTooltip: 'Pick a time',
      onChanged: changes.add,
    );

    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('is always left to right with a clock button ($name)', (
        tester,
      ) async {
        final controller = TextEditingController(text: '02:41');
        addTearDown(controller.dispose);
        final changes = <String>[];
        await pumpShared(
          tester,
          SizedBox(width: 200, child: field(controller, changes)),
          brightness: brightness,
          direction: direction,
        );
        final text = tester.widget<TextField>(find.byKey(const Key('time')));
        expect(text.textDirection, TextDirection.ltr);
        expect(text.keyboardType, TextInputType.datetime);
        expect(find.byTooltip('Pick a time'), findsOneWidget);
        // The clock button sits on the right whatever the page direction.
        expect(
          tester.getCenter(find.byKey(const Key('clock'))).dx,
          greaterThan(tester.getCenter(find.byKey(const Key('time'))).dx),
        );
        await tester.enterText(find.byKey(const Key('time')), '03:35');
        expect(changes, ['03:35']);
      });
    }

    testWidgets('keeps only digits and a colon, at most five characters', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpShared(tester, field(controller, <String>[]));
      await tester.enterText(find.byKey(const Key('time')), '0a2:4x1999');
      expect(controller.text, '02:41');
    });

    testWidgets('an invalid field draws the error border', (tester) async {
      final controller = TextEditingController(text: '2:41');
      addTearDown(controller.dispose);
      await pumpShared(tester, field(controller, <String>[], invalid: true));
      final decoration = tester
          .widget<TextField>(find.byKey(const Key('time')))
          .decoration!;
      expect(
        (decoration.enabledBorder! as OutlineInputBorder).borderSide.color,
        AppColors.light.error,
      );
    });

    testWidgets('the clock button opens the picker in 24-hour form and a '
        'choice fills the field', (tester) async {
      final controller = TextEditingController(text: '13:05');
      addTearDown(controller.dispose);
      final changes = <String>[];
      await pumpShared(
        tester,
        field(controller, changes),
        size: const Size(800, 900),
      );
      await tester.tap(find.byKey(const Key('clock')));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      // The picker starts at the typed time and has no AM/PM selector.
      expect(find.text('AM'), findsNothing);
      expect(find.text('PM'), findsNothing);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(controller.text, '13:05');
      expect(changes, ['13:05']);
    });

    testWidgets('a cancelled picker changes nothing', (tester) async {
      final controller = TextEditingController(text: '13:05');
      addTearDown(controller.dispose);
      final changes = <String>[];
      await pumpShared(
        tester,
        field(controller, changes),
        size: const Size(800, 900),
      );
      await tester.tap(find.byKey(const Key('clock')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.text, '13:05');
      expect(changes, isEmpty);
    });
  });
}
