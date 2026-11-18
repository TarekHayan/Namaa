import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_button.dart';

import '../../../support/shared_widget_harness.dart';

AppColors _colors(Brightness brightness) =>
    brightness == Brightness.dark ? AppColors.dark : AppColors.light;

/// The `FilledButton` an `AppButton` builds.
Finder _inner(String key) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.byType(FilledButton),
);

Color? _background(WidgetTester tester, String key) => tester
    .widget<FilledButton>(_inner(key))
    .style!
    .backgroundColor!
    .resolve({});

Color? _background2(WidgetTester tester, String key, Set<WidgetState> states) =>
    tester
        .widget<FilledButton>(_inner(key))
        .style!
        .backgroundColor!
        .resolve(states);

Color? _foreground(WidgetTester tester, String key, [Set<WidgetState>? s]) =>
    tester
        .widget<FilledButton>(_inner(key))
        .style!
        .foregroundColor!
        .resolve(s ?? {});

OutlinedBorder _shape(WidgetTester tester, String key) =>
    tester.widget<FilledButton>(_inner(key)).style!.shape!.resolve({})!;

Widget _refined(
  String key, {
  AppButtonVariant variant = AppButtonVariant.primary,
  AppButtonSize size = AppButtonSize.medium,
  VoidCallback? onPressed,
  bool enabled = true,
  IconData? icon,
  IconData? trailingIcon,
  Color? color,
  Color? fill,
  AppButtonTuning? tuning,
  bool expanded = false,
}) => AppButton(
  key: Key(key),
  label: 'Label',
  onPressed: enabled ? (onPressed ?? () {}) : null,
  look: AppButtonLook.refined,
  variant: variant,
  size: size,
  icon: icon,
  trailingIcon: trailingIcon,
  color: color,
  fill: fill,
  tuning: tuning,
  expanded: expanded,
);

void main() {
  group('AppButton refined look', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('primary: accent fill, glow, disabled state ($name)', (
        tester,
      ) async {
        final colors = _colors(brightness);
        await pumpShared(
          tester,
          Column(children: [_refined('on'), _refined('off', enabled: false)]),
          brightness: brightness,
          direction: direction,
        );
        expect(_background(tester, 'on'), colors.accentStrong);
        expect(_foreground(tester, 'on'), colors.onAccentStrong);
        expect(_shape(tester, 'on').side, BorderSide.none);
        expect(_background(tester, 'off'), colors.surfaceSecondary);
        expect(_foreground(tester, 'off'), colors.textSecondary);
        expect(_shape(tester, 'off').side.color, colors.border);
        final glow = find.descendant(
          of: find.byKey(const Key('on')),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).boxShadow != null,
          ),
        );
        expect(glow, findsOneWidget);
        expect(
          (tester.widget<DecoratedBox>(glow).decoration as BoxDecoration)
              .boxShadow,
          colors.buttonShadow,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('off')),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).boxShadow != null,
            ),
          ),
          findsNothing,
          reason: 'a disabled primary has no glow',
        );
      });

      testWidgets('secondary, outline and danger variants ($name)', (
        tester,
      ) async {
        final colors = _colors(brightness);
        await pumpShared(
          tester,
          Column(
            children: [
              _refined('secondary', variant: AppButtonVariant.secondary),
              _refined(
                'secondary_fill',
                variant: AppButtonVariant.secondary,
                fill: colors.surface,
              ),
              _refined(
                'outline',
                variant: AppButtonVariant.outline,
                color: colors.warning,
              ),
              _refined('danger', variant: AppButtonVariant.danger),
              _refined(
                'danger_off',
                variant: AppButtonVariant.danger,
                enabled: false,
              ),
            ],
          ),
          brightness: brightness,
          direction: direction,
        );
        expect(_background(tester, 'secondary'), colors.surfaceSecondary);
        expect(_foreground(tester, 'secondary'), colors.textPrimary);
        expect(_shape(tester, 'secondary').side.color, colors.border);
        expect(_background(tester, 'secondary_fill'), colors.surface);
        expect(_background(tester, 'outline'), colors.surface);
        expect(_shape(tester, 'outline').side.color, colors.warning);
        expect(_background(tester, 'danger'), colors.error);
        expect(_foreground(tester, 'danger'), colors.onError);
        expect(_background(tester, 'danger_off'), colors.surfaceSecondary);
        expect(_shape(tester, 'danger_off').side, BorderSide.none);
        // Quiet buttons look the same disabled (a busy form keeps its look).
        expect(
          _background2(tester, 'secondary', {WidgetState.disabled}),
          colors.surfaceSecondary,
        );
      });
    }

    testWidgets('sizes map to height and corner radius, with overrides', (
      tester,
    ) async {
      await pumpShared(
        tester,
        Column(
          children: [
            _refined('small', size: AppButtonSize.small),
            _refined('medium'),
            _refined('large', size: AppButtonSize.large),
            _refined(
              'custom',
              tuning: const AppButtonTuning(radius: 18, minHeight: 56),
            ),
          ],
        ),
      );
      expect(tester.getSize(find.byKey(const Key('small'))).height, 48);
      expect(tester.getSize(find.byKey(const Key('medium'))).height, 52);
      expect(tester.getSize(find.byKey(const Key('large'))).height, 58);
      expect(tester.getSize(find.byKey(const Key('custom'))).height, 56);
      expect(
        (_shape(tester, 'small') as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(14),
      );
      expect(
        (_shape(tester, 'medium') as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(16),
      );
      expect(
        (_shape(tester, 'large') as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(20),
      );
      expect(
        (_shape(tester, 'custom') as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(18),
      );
    });

    testWidgets('label weight follows the variant unless overridden', (
      tester,
    ) async {
      await pumpShared(
        tester,
        Column(
          children: [
            _refined('primary'),
            _refined('secondary', variant: AppButtonVariant.secondary),
            _refined(
              'bold',
              variant: AppButtonVariant.secondary,
              tuning: const AppButtonTuning(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
      FontWeight? weight(String key) => tester
          .widget<FilledButton>(_inner(key))
          .style!
          .textStyle!
          .resolve({})!
          .fontWeight;
      expect(weight('primary'), FontWeight.w700);
      expect(weight('secondary'), FontWeight.w600);
      expect(weight('bold'), FontWeight.w700);
    });

    testWidgets('tuning overrides padding and label line height', (
      tester,
    ) async {
      await pumpShared(
        tester,
        Column(
          children: [
            _refined('plain'),
            _refined(
              'tuned',
              tuning: const AppButtonTuning(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                labelHeight: 1.4,
              ),
            ),
          ],
        ),
      );
      TextStyle style(String key) => tester
          .widget<FilledButton>(_inner(key))
          .style!
          .textStyle!
          .resolve({})!;
      expect(style('plain').height, isNull);
      expect(style('plain').fontSize, 16);
      expect(style('tuned').height, 1.4);
      expect(
        style('tuned').fontFamily,
        DefaultTextStyle.of(
          tester.element(find.byKey(const Key('tuned'))),
        ).style.fontFamily,
      );
      EdgeInsetsGeometry padding(String key) =>
          tester.widget<FilledButton>(_inner(key)).style!.padding!.resolve({})!;
      expect(
        padding('plain'),
        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      );
      expect(
        padding('tuned'),
        const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      );
      expect(
        tester.getSize(find.byKey(const Key('tuned'))).width,
        greaterThan(tester.getSize(find.byKey(const Key('plain'))).width),
      );
    });

    testWidgets('exposes the label once to assistive technology', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpShared(
        tester,
        _refined('button', trailingIcon: Icons.arrow_forward),
      );
      expect(find.bySemanticsLabel('Label'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Label')).label,
        'Label',
      );
      semantics.dispose();
    });

    testWidgets('a custom semantic label replaces the text label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpShared(
        tester,
        AppButton(
          label: 'Label',
          semanticLabel: 'Custom',
          onPressed: () {},
          look: AppButtonLook.refined,
        ),
      );
      expect(find.bySemanticsLabel('Custom'), findsOneWidget);
      expect(find.bySemanticsLabel('Label'), findsNothing);
      semantics.dispose();
    });

    testWidgets('every label uses the theme font', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            fontFamily: 'ThemeFont',
            fontFamilyFallback: const ['FallbackFont'],
          ),
          home: Scaffold(
            body: Column(
              children: [
                _refined('plain'),
                _refined(
                  'tuned',
                  tuning: const AppButtonTuning(labelHeight: 1.4),
                ),
                _refined('trailing', trailingIcon: Icons.arrow_forward),
              ],
            ),
          ),
        ),
      );
      for (final key in ['plain', 'tuned', 'trailing']) {
        final style = tester
            .widget<FilledButton>(_inner(key))
            .style!
            .textStyle!
            .resolve({})!;
        expect(style.fontFamily, 'ThemeFont', reason: key);
        expect(style.fontFamilyFallback, ['FallbackFont'], reason: key);
      }
    });

    testWidgets('icons, expanded layout and taps', (tester) async {
      var taps = 0;
      await pumpShared(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _refined('leading', icon: Icons.add, onPressed: () => taps++),
            _refined(
              'trailing',
              trailingIcon: Icons.arrow_forward,
              size: AppButtonSize.large,
              expanded: true,
              onPressed: () => taps++,
            ),
            _refined('off', enabled: false, onPressed: () => taps += 10),
          ],
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('leading')),
          matching: find.byIcon(Icons.add),
        ),
        findsOneWidget,
      );
      final arrow = find.descendant(
        of: find.byKey(const Key('trailing')),
        matching: find.byIcon(Icons.arrow_forward),
      );
      expect(arrow, findsOneWidget);
      expect(tester.widget<Icon>(arrow).size, 22);
      expect(
        tester.getTopLeft(arrow).dx,
        greaterThan(
          tester
              .getTopLeft(
                find.descendant(
                  of: find.byKey(const Key('trailing')),
                  matching: find.text('Label'),
                ),
              )
              .dx,
        ),
        reason: 'the trailing icon follows the label',
      );
      expect(tester.getSize(find.byKey(const Key('trailing'))).width, 400);
      await tester.tap(find.byKey(const Key('leading')));
      await tester.tap(find.byKey(const Key('trailing')));
      await tester.tap(find.byKey(const Key('off')), warnIfMissed: false);
      expect(taps, 2);
    });

    testWidgets('a long label wraps instead of clipping', (tester) async {
      await pumpShared(
        tester,
        SizedBox(
          width: 200,
          child: AppButton(
            key: const Key('long'),
            label: 'a fairly long action label that must wrap',
            onPressed: () {},
            look: AppButtonLook.refined,
            expanded: true,
          ),
        ),
        size: const Size(320, 800),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.maxLines, isNull);
    });
  });

  group('AppButton classic look is unchanged', () {
    testWidgets('the default look keeps its primary fill and size', (
      tester,
    ) async {
      await pumpShared(
        tester,
        const AppButton(key: Key('classic'), label: 'Save', onPressed: null),
        brightness: Brightness.dark,
      );
      // The classic look does not use the refined tokens or sizes: a 44 px
      // button in a 48 px tap target, not the refined 52 px.
      expect(tester.getSize(find.byKey(const Key('classic'))).height, 48);
      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('classic')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.style!.shape, isNull);
    });
  });
}
