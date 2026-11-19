import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_layout.dart';
import 'package:namma_project/app/theme/app_typography.dart';

import '../../../support/shared_widget_harness.dart';

void main() {
  group('AppColors design tokens', () {
    test('the light and dark accent, track, soft fills and scrim', () {
      expect(AppColors.light.accentStrong, AppColors.light.secondary);
      expect(AppColors.dark.accentStrong, AppColors.dark.primary);
      expect(AppColors.light.onAccentStrong, const Color(0xFFFFFFFF));
      expect(AppColors.dark.onAccentStrong, const Color(0xFF050805));
      expect(AppColors.light.track, const Color(0x29059669));
      expect(AppColors.dark.track, const Color(0x3310B981));
      expect(AppColors.light.warningSoft, const Color(0x1FD97706));
      expect(AppColors.dark.errorSoft, const Color(0x24EF4444));
      expect(AppColors.light.errorText, const Color(0xFFB91C1C));
      expect(AppColors.dark.errorText, const Color(0xFFF87171));
      expect(AppColors.light.scrim, const Color(0x6B0D1410));
      expect(AppColors.dark.scrim, const Color(0xA8000000));
    });

    test('the glow shadows differ per mode and stay immutable tokens', () {
      expect(AppColors.light.cardShadow, hasLength(1));
      expect(AppColors.dark.cardShadow, hasLength(2));
      expect(AppColors.light.buttonShadow.single.blurRadius, 24);
      expect(AppColors.dark.buttonShadow.single.blurRadius, 30);
      expect(AppColors.light.glow, AppColors.light.cardShadow.last.color);
      expect(AppColors.dark.glow, AppColors.dark.cardShadow.last.color);
    });

    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('of() follows the theme brightness ($name)', (tester) async {
        late AppColors seen;
        await pumpShared(
          tester,
          Builder(
            builder: (context) {
              seen = AppColors.of(context);
              return const SizedBox();
            },
          ),
          brightness: brightness,
          direction: direction,
        );
        expect(
          seen,
          brightness == Brightness.dark ? AppColors.dark : AppColors.light,
        );
      });
    }
  });

  group('AppLayout', () {
    for (final (width, wide) in [(719.0, false), (720.0, true)]) {
      testWidgets('width $width is ${wide ? 'wide' : 'narrow'}', (
        tester,
      ) async {
        late bool seen;
        await pumpShared(
          tester,
          Builder(
            builder: (context) {
              seen = AppLayout.isWide(context);
              return const SizedBox();
            },
          ),
          size: Size(width, 800),
        );
        expect(seen, wide);
      });
    }
  });

  group('AppTypography helpers', () {
    test('fixed is an exact size with no family and a 1.5 default height', () {
      final style = AppTypography.fixed(
        17,
        FontWeight.w700,
        const Color(0xFF123456),
      );
      expect(style.fontSize, 17);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.color, const Color(0xFF123456));
      expect(style.height, 1.5);
      expect(style.fontFamily, isNull);
      expect(
        AppTypography.fixed(
          14,
          FontWeight.w400,
          const Color(0xFF000000),
          height: 1.7,
        ).height,
        1.7,
      );
    });

    test('directionFor reads the first strong character', () {
      expect(
        AppTypography.directionFor('مرحبا', TextDirection.ltr),
        TextDirection.rtl,
      );
      expect(
        AppTypography.directionFor('Hello', TextDirection.rtl),
        TextDirection.ltr,
      );
      expect(
        AppTypography.directionFor('123', TextDirection.rtl),
        TextDirection.rtl,
        reason: 'no strong character keeps the fallback',
      );
      expect(
        AppTypography.directionFor('', TextDirection.ltr),
        TextDirection.ltr,
      );
    });
  });
}
