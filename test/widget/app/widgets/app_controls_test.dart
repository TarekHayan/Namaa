import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_action_tile.dart';
import 'package:namma_project/app/widgets/app_back_link.dart';
import 'package:namma_project/app/widgets/app_filter_chip.dart';
import 'package:namma_project/app/widgets/app_ink_surface.dart';
import 'package:namma_project/app/widgets/app_key_cap.dart';
import 'package:namma_project/app/widgets/app_menu_button.dart';
import 'package:namma_project/app/widgets/app_segmented_control.dart';
import 'package:namma_project/app/widgets/app_surface_icon_button.dart';

import '../../../support/shared_widget_harness.dart';

AppColors _colors(Brightness brightness) =>
    brightness == Brightness.dark ? AppColors.dark : AppColors.light;

void main() {
  group('AppSurfaceIconButton', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('square and raised round variants ($name)', (tester) async {
        final colors = _colors(brightness);
        var taps = 0;
        await pumpShared(
          tester,
          Column(
            children: [
              AppSurfaceIconButton(
                key: const Key('square'),
                icon: Icons.close_rounded,
                label: 'Close',
                onTap: () => taps++,
              ),
              AppSurfaceIconButton(
                key: const Key('round'),
                icon: Icons.chevron_left,
                label: 'Previous',
                onTap: () => taps++,
                size: 56,
                iconSize: 24,
                circle: true,
                raised: true,
              ),
            ],
          ),
          brightness: brightness,
          direction: direction,
        );
        expect(
          tester.getSize(find.byKey(const Key('square'))),
          const Size(48, 48),
        );
        expect(
          tester.getSize(find.byKey(const Key('round'))),
          const Size(56, 56),
        );
        final materials = tester
            .widgetList<Material>(
              find.descendant(
                of: find.byType(AppSurfaceIconButton),
                matching: find.byType(Material),
              ),
            )
            .toList();
        expect(materials.first.color, colors.surfaceSecondary);
        expect(materials.last.color, colors.surface);
        expect(materials.last.shape, isA<CircleBorder>());
        final glow = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byKey(const Key('round')),
                matching: find.byType(Container),
              ),
            )
            .first;
        expect(
          (glow.decoration! as BoxDecoration).boxShadow,
          colors.cardShadow,
        );
        await tester.tap(find.byKey(const Key('square')));
        await tester.tap(find.byKey(const Key('round')));
        expect(taps, 2);
      });
    }

    testWidgets('a null onTap dims it, exposes a disabled button label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpShared(
        tester,
        const AppSurfaceIconButton(
          key: Key('off'),
          icon: Icons.restart_alt,
          label: 'Reset',
          onTap: null,
          disabledOpacity: 0.45,
        ),
      );
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byKey(const Key('off')),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.45);
      final node = tester.getSemantics(find.bySemanticsLabel('Reset'));
      expect(node.label, 'Reset');
      expect(node.flagsCollection.isEnabled, ui.Tristate.isFalse);
      semantics.dispose();
    });
  });

  group('AppInkSurface', () {
    testWidgets('fill, outline, radius, min height and tap', (tester) async {
      var taps = 0;
      await pumpShared(
        tester,
        Column(
          children: [
            AppInkSurface(
              key: const Key('tile'),
              color: AppColors.light.surfaceSecondary,
              borderColor: AppColors.light.border,
              radius: 18,
              minHeight: 56,
              padding: const EdgeInsets.all(8),
              onTap: () => taps++,
              child: const Text('tile'),
            ),
            AppInkSurface(
              key: const Key('stadium'),
              stadium: true,
              onTap: () {},
              child: const Text('stadium'),
            ),
          ],
        ),
      );
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(const Key('tile')),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, AppColors.light.surfaceSecondary);
      expect(
        (material.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(18),
      );
      expect(tester.getSize(find.byKey(const Key('tile'))).height, 56);
      final stadium = tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(const Key('stadium')),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(stadium.color, AppColors.light.surface);
      expect(stadium.shape, isA<StadiumBorder>());
      await tester.tap(find.byKey(const Key('tile')));
      expect(taps, 1);
    });
  });

  group('AppSegmentedControl', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('selects a segment and reports taps ($name)', (tester) async {
        final colors = _colors(brightness);
        var selected = 0;
        late StateSetter rebuild;
        await pumpShared(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return AppSegmentedControl(
                selectedIndex: selected,
                onChanged: (index) => setState(() => selected = index),
                segments: const [
                  AppSegment(key: Key('a'), label: 'Morning'),
                  AppSegment(key: Key('b'), label: 'Evening'),
                  AppSegment(key: Key('c'), label: 'Mine'),
                ],
              );
            },
          ),
          brightness: brightness,
          direction: direction,
        );
        Material segment(String key) => tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(segment('a').color, colors.surface);
        expect(segment('b').color, Colors.transparent);
        expect(
          (segment('a').shape! as RoundedRectangleBorder).side.color,
          colors.primary,
        );
        await tester.tap(find.byKey(const Key('c')));
        await tester.pump();
        expect(selected, 2);
        expect(segment('c').color, colors.surface);
        expect(segment('a').color, Colors.transparent);
        // The three segments split the width evenly.
        expect(
          tester.getSize(find.byKey(const Key('a'))).width,
          tester.getSize(find.byKey(const Key('b'))).width,
        );
        rebuild(() {});
      });
    }

    testWidgets('exposes selected state and the label to semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpShared(
        tester,
        AppSegmentedControl(
          selectedIndex: 1,
          onChanged: (_) {},
          segments: const [
            AppSegment(key: Key('a'), label: 'One'),
            AppSegment(key: Key('b'), label: 'Two'),
          ],
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Two'));
      expect(node.label, 'Two');
      expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
      semantics.dispose();
    });
  });

  group('AppActionTile, AppBackLink and AppKeyCap', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('render and react ($name)', (tester) async {
        final colors = _colors(brightness);
        var taps = 0;
        await pumpShared(
          tester,
          Column(
            children: [
              AppActionTile(
                key: const Key('tile'),
                icon: Icons.sync_alt_rounded,
                label: 'Sync differences',
                onTap: () => taps++,
              ),
              AppBackLink(
                key: const Key('back'),
                label: 'Back',
                onTap: () => taps++,
              ),
              const AppKeyCap(key: Key('cap'), label: 'Space'),
            ],
          ),
          brightness: brightness,
          direction: direction,
        );
        expect(tester.getSize(find.byKey(const Key('tile'))).height, 56);
        expect(
          tester.widget<Text>(find.text('Sync differences')).style!.color,
          colors.textPrimary,
        );
        expect(
          tester.widget<Text>(find.text('Back')).style!.color,
          colors.accentStrong,
        );
        expect(
          tester.getSize(find.byKey(const Key('back'))).height,
          greaterThanOrEqualTo(48),
        );
        final cap = tester.widget<Container>(
          find.descendant(
            of: find.byKey(const Key('cap')),
            matching: find.byType(Container),
          ),
        );
        expect(
          (cap.decoration! as BoxDecoration).color,
          colors.surfaceSecondary,
        );
        await tester.tap(find.byKey(const Key('tile')));
        await tester.tap(find.byKey(const Key('back')));
        expect(taps, 2);
      });
    }

    testWidgets('the key cap text always reads left to right', (tester) async {
      await pumpShared(
        tester,
        const AppKeyCap(key: Key('cap'), label: '←'),
        direction: TextDirection.rtl,
      );
      final directionality = tester.widget<Directionality>(
        find.descendant(
          of: find.byKey(const Key('cap')),
          matching: find.byType(Directionality),
        ),
      );
      expect(directionality.textDirection, TextDirection.ltr);
    });
  });

  group('AppFilterChip', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('selected and unselected states ($name)', (tester) async {
        final colors = _colors(brightness);
        final changes = <bool>[];
        await pumpShared(
          tester,
          Row(
            children: [
              AppFilterChip(
                key: const Key('on'),
                label: 'Fajr',
                selected: true,
                onSelected: changes.add,
              ),
              AppFilterChip(
                key: const Key('off'),
                label: 'Ramadan',
                selected: false,
                onSelected: changes.add,
              ),
            ],
          ),
          brightness: brightness,
          direction: direction,
        );
        final on = tester.widget<FilterChip>(
          find.descendant(
            of: find.byKey(const Key('on')),
            matching: find.byType(FilterChip),
          ),
        );
        final off = tester.widget<FilterChip>(
          find.descendant(
            of: find.byKey(const Key('off')),
            matching: find.byType(FilterChip),
          ),
        );
        expect(on.selectedColor, colors.accentSoft);
        expect(on.side!.color, colors.primary);
        expect(off.backgroundColor, colors.surfaceSecondary);
        expect(off.side!.color, colors.border);
        await tester.tap(find.byKey(const Key('off')));
        expect(changes, [true]);
      });
    }

    testWidgets('user text keeps the direction the caller gives it', (
      tester,
    ) async {
      await pumpShared(
        tester,
        AppFilterChip(
          label: 'مجموعة',
          selected: false,
          onSelected: (_) {},
          textDirection: TextDirection.rtl,
        ),
      );
      expect(
        tester.widget<Text>(find.text('مجموعة')).textDirection,
        TextDirection.rtl,
      );
    });
  });

  group('AppMenuButton', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('opens the shared menu and reports the choice ($name)', (
        tester,
      ) async {
        final colors = _colors(brightness);
        final picked = <String>[];
        await pumpShared(
          tester,
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: AppMenuButton<String>(
              key: const Key('menu'),
              tooltip: 'More',
              onSelected: picked.add,
              entries: const [
                AppMenuEntry(
                  value: 'edit',
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                ),
                AppMenuEntry(
                  value: 'delete',
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  destructive: true,
                ),
              ],
            ),
          ),
          brightness: brightness,
          direction: direction,
        );
        expect(
          tester.getSize(find.byKey(const Key('menu'))),
          const Size(48, 48),
        );
        await tester.tap(find.byKey(const Key('menu')));
        await tester.pumpAndSettle();
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('Edit')).style!.color,
          colors.textPrimary,
        );
        expect(
          tester.widget<Text>(find.text('Delete')).style!.color,
          colors.errorText,
        );
        final menu = tester.widget<Material>(
          find
              .ancestor(of: find.text('Edit'), matching: find.byType(Material))
              .first,
        );
        expect(menu.color, colors.surface);
        expect(
          (menu.shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(18),
        );
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(picked, ['delete']);
      });
    }

    testWidgets('the tooltip is the accessibility label', (tester) async {
      await pumpShared(
        tester,
        AppMenuButton<int>(
          tooltip: 'More options',
          onSelected: (_) {},
          entries: const [
            AppMenuEntry(value: 1, label: 'One', icon: Icons.add),
          ],
        ),
      );
      expect(find.byTooltip('More options'), findsOneWidget);
    });
  });
}
