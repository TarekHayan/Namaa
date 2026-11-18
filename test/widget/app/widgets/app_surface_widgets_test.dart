import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_card.dart';
import 'package:namma_project/app/widgets/app_empty_state.dart';
import 'package:namma_project/app/widgets/app_icon_badge.dart';
import 'package:namma_project/app/widgets/app_linear_progress.dart';
import 'package:namma_project/app/widgets/app_notice.dart';
import 'package:namma_project/app/widgets/app_pill.dart';
import 'package:namma_project/app/widgets/app_progress_ring.dart';
import 'package:namma_project/app/widgets/app_text_scale_clamp.dart';

import '../../../support/shared_widget_harness.dart';

AppColors _colors(Brightness brightness) =>
    brightness == Brightness.dark ? AppColors.dark : AppColors.light;

BoxDecoration _decoration(WidgetTester tester, Finder owner) {
  final container = tester.widget<Container>(
    find.descendant(of: owner, matching: find.byType(Container)).first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('AppCard', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('tones take their fill and border from tokens ($name)', (
        tester,
      ) async {
        final colors = _colors(brightness);
        await pumpShared(
          tester,
          Column(
            children: [
              for (final tone in AppCardTone.values)
                AppCard(
                  key: Key('card_${tone.name}'),
                  tone: tone,
                  child: const SizedBox(width: 20, height: 20),
                ),
            ],
          ),
          brightness: brightness,
          direction: direction,
        );
        final expected = {
          AppCardTone.surface: (colors.surface, colors.border),
          AppCardTone.secondary: (colors.surfaceSecondary, colors.border),
          AppCardTone.accent: (colors.accentSoft, colors.primary),
          AppCardTone.warning: (colors.warningSoft, colors.warning),
          AppCardTone.error: (colors.errorSoft, colors.error),
        };
        for (final tone in AppCardTone.values) {
          final box = _decoration(tester, find.byKey(Key('card_${tone.name}')));
          expect(box.color, expected[tone]!.$1, reason: tone.name);
          expect((box.border! as Border).top.color, expected[tone]!.$2);
          expect(box.boxShadow, isNull);
        }
      });
    }

    testWidgets('elevated adds the glow, radius and padding apply', (
      tester,
    ) async {
      await pumpShared(
        tester,
        const AppCard(
          key: Key('card'),
          radius: 28,
          elevated: true,
          padding: EdgeInsets.all(20),
          child: SizedBox(width: 40, height: 40),
        ),
        brightness: Brightness.dark,
      );
      final box = _decoration(tester, find.byKey(const Key('card')));
      expect(box.boxShadow, AppColors.dark.cardShadow);
      expect(box.borderRadius, BorderRadius.circular(28));
      // 40 px content, 20 px padding and the 1 px border on each side.
      expect(tester.getSize(find.byKey(const Key('card'))), const Size(82, 82));
    });
  });

  group('AppIconBadge', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('tones and border ($name)', (tester) async {
        final colors = _colors(brightness);
        await pumpShared(
          tester,
          const Column(
            children: [
              AppIconBadge(
                key: Key('accent'),
                icon: Icons.check,
                size: 72,
                iconSize: 36,
              ),
              AppIconBadge(
                key: Key('neutral'),
                icon: Icons.add,
                size: 72,
                iconSize: 32,
                tone: AppBadgeTone.neutral,
              ),
              AppIconBadge(
                key: Key('warning'),
                icon: Icons.add,
                size: 44,
                iconSize: 24,
                tone: AppBadgeTone.warning,
                bordered: false,
              ),
              AppIconBadge(
                key: Key('error'),
                icon: Icons.error_outline,
                size: 96,
                iconSize: 44,
                tone: AppBadgeTone.error,
              ),
            ],
          ),
          brightness: brightness,
          direction: direction,
        );
        BoxDecoration box(String key) =>
            _decoration(tester, find.byKey(Key(key)));
        Color iconColor(String key) => tester
            .widget<Icon>(
              find.descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(Icon),
              ),
            )
            .color!;
        expect(box('accent').color, colors.accentSoft);
        expect(iconColor('accent'), colors.accentStrong);
        expect((box('accent').border! as Border).top.color, colors.border);
        expect(box('neutral').color, colors.surfaceSecondary);
        expect(iconColor('neutral'), colors.textSecondary);
        expect(box('warning').color, colors.warningSoft);
        expect(box('warning').border, isNull);
        expect(iconColor('warning'), colors.warning);
        expect(box('error').color, colors.errorSoft);
        expect(iconColor('error'), colors.error);
        expect(
          tester.getSize(find.byKey(const Key('error'))),
          const Size(96, 96),
        );
      });
    }

    testWidgets('a border color overrides the hairline', (tester) async {
      await pumpShared(
        tester,
        AppIconBadge(
          key: const Key('badge'),
          icon: Icons.check,
          size: 72,
          iconSize: 36,
          borderColor: AppColors.light.primary,
        ),
      );
      final box = _decoration(tester, find.byKey(const Key('badge')));
      expect((box.border! as Border).top.color, AppColors.light.primary);
    });
  });

  group('AppPill', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('tones ($name)', (tester) async {
        final colors = _colors(brightness);
        await pumpShared(
          tester,
          const Column(
            children: [
              AppPill(key: Key('accent'), label: 'A'),
              AppPill(key: Key('hairline'), label: 'B', hairline: true),
              AppPill(
                key: Key('neutral'),
                label: 'C',
                tone: AppPillTone.neutral,
              ),
              AppPill(key: Key('filled'), label: 'D', tone: AppPillTone.filled),
              AppPill(
                key: Key('error'),
                label: 'E',
                tone: AppPillTone.error,
                icon: Icons.delete_outline,
              ),
            ],
          ),
          brightness: brightness,
          direction: direction,
        );
        BoxDecoration box(String key) =>
            _decoration(tester, find.byKey(Key(key)));
        Color? textColor(String key) => tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(Text),
              ),
            )
            .style
            ?.color;
        expect(box('accent').color, colors.accentSoft);
        expect(box('accent').border, isNull);
        expect(textColor('accent'), colors.accentStrong);
        expect((box('hairline').border! as Border).top.color, colors.border);
        expect(box('neutral').color, colors.surface);
        expect(textColor('neutral'), colors.textPrimary);
        expect(box('filled').color, colors.accentStrong);
        expect(textColor('filled'), colors.onAccentStrong);
        expect(box('error').color, colors.errorSoft);
        expect((box('error').border! as Border).top.color, colors.error);
        expect(textColor('error'), colors.textPrimary);
        expect(
          find.descendant(
            of: find.byKey(const Key('error')),
            matching: find.byIcon(Icons.delete_outline),
          ),
          findsOneWidget,
        );
        expect(box('accent').borderRadius, BorderRadius.circular(999));
      });
    }

    testWidgets('a minimum height keeps the label centered and the pill '
        'hugging its content', (tester) async {
      await pumpShared(
        tester,
        const Column(
          children: [
            AppPill(key: Key('shrink'), label: 'x'),
            AppPill(key: Key('tall'), label: 'x', minHeight: 44),
          ],
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('shrink'))).width,
        lessThan(100),
      );
      expect(
        tester.getSize(find.byKey(const Key('tall'))).width,
        lessThan(100),
      );
      expect(tester.getSize(find.byKey(const Key('tall'))).height, 44);
      final pill = tester.getRect(find.byKey(const Key('tall')));
      final text = tester.getRect(find.text('x').last);
      expect(text.center.dy, closeTo(pill.center.dy, 0.5));
    });
  });

  group('AppProgressRing', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('draws the track and the arc ($name)', (tester) async {
        final colors = _colors(brightness);
        await pumpShared(
          tester,
          const Center(
            child: SizedBox(
              width: 96,
              height: 96,
              child: AppProgressRing(
                key: Key('ring'),
                progress: 0.5,
                strokeWidth: 8,
                child: Center(child: Text('50%')),
              ),
            ),
          ),
          brightness: brightness,
          direction: direction,
        );
        final paint = find.descendant(
          of: find.byKey(const Key('ring')),
          matching: find.byType(CustomPaint),
        );
        expect(
          tester.renderObject(paint.first),
          paints
            ..arc(color: colors.track, strokeWidth: 8)
            ..arc(color: colors.primary, strokeWidth: 8),
        );
        expect(find.text('50%'), findsOneWidget);
      });
    }

    testWidgets('zero progress draws only the track, full draws a circle', (
      tester,
    ) async {
      Future<void> pump(double progress) => pumpShared(
        tester,
        Center(
          child: AppProgressRing(
            key: const Key('ring'),
            size: 104,
            progress: progress,
            strokeWidth: 6,
          ),
        ),
      );
      await pump(0);
      final paint = find.descendant(
        of: find.byKey(const Key('ring')),
        matching: find.byType(CustomPaint),
      );
      expect(
        tester.getSize(find.byKey(const Key('ring'))),
        const Size(104, 104),
      );
      expect(
        tester.renderObject(paint.first),
        paints..arc(color: AppColors.light.track),
      );
      await pump(1);
      expect(
        tester.renderObject(paint.first),
        paints
          ..arc(color: AppColors.light.track)
          ..arc(color: AppColors.light.primary),
      );
      await pump(2);
      expect(tester.takeException(), isNull, reason: 'progress is clamped');
    });
  });

  group('AppLinearProgress', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('the fill grows from the start edge ($name)', (tester) async {
        final colors = _colors(brightness);
        await pumpShared(
          tester,
          const AppLinearProgress(
            key: Key('bar'),
            progress: 0.25,
            margin: EdgeInsets.symmetric(horizontal: 16),
          ),
          brightness: brightness,
          direction: direction,
        );
        // The margin belongs to the widget; the bar itself is 368 px wide.
        expect(
          tester.getSize(find.byKey(const Key('bar'))),
          const Size(400, 4),
        );
        expect(
          tester
              .getSize(
                find
                    .descendant(
                      of: find.byKey(const Key('bar')),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              )
              .width,
          368,
        );
        final fill = tester.widget<FractionallySizedBox>(
          find.descendant(
            of: find.byKey(const Key('bar')),
            matching: find.byType(FractionallySizedBox),
          ),
        );
        expect(fill.widthFactor, 0.25);
        final track = _decoration(tester, find.byKey(const Key('bar')));
        expect(track.color, colors.border);
        final fillRect = tester.getRect(
          find.descendant(
            of: find.byKey(const Key('bar')),
            matching: find.byType(FractionallySizedBox),
          ),
        );
        final bar = tester.getRect(
          find
              .descendant(
                of: find.byKey(const Key('bar')),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        if (direction == TextDirection.rtl) {
          expect(fillRect.right, bar.right);
        } else {
          expect(fillRect.left, bar.left);
        }
      });
    }

    testWidgets('progress is clamped to 0..1', (tester) async {
      await pumpShared(
        tester,
        const AppLinearProgress(key: Key('bar'), progress: 3),
      );
      final fill = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byKey(const Key('bar')),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(fill.widthFactor, 1);
    });
  });

  group('AppInlineNote', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('warning and error tones ($name)', (tester) async {
        final colors = _colors(brightness);
        await pumpShared(
          tester,
          const Column(
            children: [
              AppInlineNote(key: Key('warn'), text: 'Limit reached'),
              AppInlineNote(
                key: Key('error'),
                text: 'Invalid',
                tone: AppNoticeTone.error,
              ),
            ],
          ),
          brightness: brightness,
          direction: direction,
        );
        Text text(String key) => tester.widget<Text>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(Text),
          ),
        );
        Icon icon(String key) => tester.widget<Icon>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(Icon),
          ),
        );
        expect(text('warn').style!.color, colors.textPrimary);
        expect(text('warn').style!.fontWeight, FontWeight.w400);
        expect(icon('warn').color, colors.warning);
        expect(text('error').style!.color, colors.errorText);
        expect(text('error').style!.fontWeight, FontWeight.w600);
        expect(icon('error').color, colors.errorText);
      });
    }

    testWidgets('long text wraps inside the row', (tester) async {
      await pumpShared(
        tester,
        AppInlineNote(text: 'long ' * 80),
        size: const Size(300, 600),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AppBanner', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('warning tint, message and action ($name)', (tester) async {
        final colors = _colors(brightness);
        var taps = 0;
        await pumpShared(
          tester,
          AppBanner(
            key: const Key('banner'),
            message: 'Counting is paused',
            icon: Icons.location_on_outlined,
            actionLabel: 'Open setup',
            onAction: () => taps++,
            actionKey: const Key('banner_action'),
            messageKey: const Key('banner_message'),
          ),
          brightness: brightness,
          direction: direction,
        );
        final box = _decoration(tester, find.byKey(const Key('banner')));
        expect(box.color, colors.warningSoft);
        expect((box.border! as Border).top.color, colors.warning);
        expect(box.borderRadius, BorderRadius.circular(20));
        expect(find.byKey(const Key('banner_message')), findsOneWidget);
        await tester.tap(find.byKey(const Key('banner_action')));
        expect(taps, 1);
      });
    }

    testWidgets('compact uses the dense radius, and the action needs both '
        'a label and a callback', (tester) async {
      await pumpShared(
        tester,
        const AppBanner(
          key: Key('banner'),
          compact: true,
          message: 'Starts at 04:30',
          icon: Icons.schedule_rounded,
          actionLabel: 'Open setup',
        ),
      );
      final box = _decoration(tester, find.byKey(const Key('banner')));
      expect(box.borderRadius, BorderRadius.circular(18));
      expect(find.text('Open setup'), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('banner'))).height,
        greaterThanOrEqualTo(52),
      );
    });
  });

  group('AppTextScaleClamp', () {
    testWidgets('caps a large scale and passes a small one through', (
      tester,
    ) async {
      double? scaled;
      Widget probe() => Builder(
        builder: (context) {
          scaled = MediaQuery.textScalerOf(context).scale(10);
          return const SizedBox();
        },
      );
      await pumpShared(
        tester,
        AppTextScaleClamp(max: 1.3, child: probe()),
        textScale: 2,
      );
      expect(scaled, closeTo(13, 0.001));
      await pumpShared(
        tester,
        AppTextScaleClamp(max: 1.3, child: probe()),
        textScale: 1.1,
      );
      expect(scaled, closeTo(11, 0.001));
    });
  });

  group('AppEmptyState', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('badge, title, body and action are stacked ($name)', (
        tester,
      ) async {
        await pumpShared(
          tester,
          SingleChildScrollView(
            child: AppEmptyState(
              key: const Key('empty'),
              icon: Icons.wb_sunny_outlined,
              title: 'No adhkar yet',
              body: 'Create a group to start.',
              action: ElevatedButton(
                key: const Key('empty_action'),
                onPressed: () {},
                child: const Text('Create'),
              ),
            ),
          ),
          brightness: brightness,
          direction: direction,
        );
        final badge = tester.getTopLeft(find.byType(AppIconBadge)).dy;
        final title = tester.getTopLeft(find.text('No adhkar yet')).dy;
        final body = tester
            .getTopLeft(find.text('Create a group to start.'))
            .dy;
        final action = tester
            .getTopLeft(find.byKey(const Key('empty_action')))
            .dy;
        expect([badge, title, body, action]..sort(), [
          badge,
          title,
          body,
          action,
        ]);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('only an icon and a body still lays out', (tester) async {
      await pumpShared(
        tester,
        const AppEmptyState(
          icon: Icons.add,
          badgeSize: 72,
          iconSize: 32,
          tone: AppBadgeTone.neutral,
          body: 'Empty',
        ),
      );
      expect(find.text('Empty'), findsOneWidget);
      expect(tester.getSize(find.byType(AppIconBadge)), const Size(72, 72));
    });
  });
}
