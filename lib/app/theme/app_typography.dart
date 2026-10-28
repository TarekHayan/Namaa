import 'package:flutter/material.dart';

import 'app_colors.dart';

const String kProjectFontFamily = 'ThmanyahSans';

/// A small set of semantic text roles shared by feature screens.
enum AppTextRole { display, headline, title, body, caption, label }

abstract final class AppTypography {
  /// Width adjusts the layout hierarchy; the user's text scale still applies
  /// independently through Flutter's MediaQuery text scaler.
  static double scaleForWidth(double width) {
    if (width < 360) return 0.95;
    if (width < 600) return 1;
    if (width < 1024) return 1.05;
    return 1.10;
  }

  static TextTheme textTheme(AppColors colors, double width) {
    final scale = scaleForWidth(width);
    TextStyle style(double size, FontWeight weight, {double height = 1.35}) =>
        TextStyle(
          fontFamily: kProjectFontFamily,
          fontSize: size * scale,
          fontWeight: weight,
          height: height,
          color: colors.textPrimary,
        );

    return TextTheme(
      displayLarge: style(42, FontWeight.w800, height: 1.15),
      displayMedium: style(36, FontWeight.w800, height: 1.18),
      displaySmall: style(32, FontWeight.w800, height: 1.2),
      headlineLarge: style(30, FontWeight.w800, height: 1.2),
      headlineMedium: style(26, FontWeight.w800, height: 1.22),
      headlineSmall: style(22, FontWeight.w800, height: 1.25),
      titleLarge: style(20, FontWeight.w700, height: 1.3),
      titleMedium: style(17, FontWeight.w700, height: 1.3),
      titleSmall: style(15, FontWeight.w700, height: 1.3),
      bodyLarge: style(16, FontWeight.w400),
      bodyMedium: style(14, FontWeight.w400),
      bodySmall: style(12, FontWeight.w400),
      labelLarge: style(14, FontWeight.w700, height: 1.2),
      labelMedium: style(12, FontWeight.w700, height: 1.2),
      labelSmall: style(11, FontWeight.w700, height: 1.2),
    );
  }

  static TextStyle style(BuildContext context, AppTextRole role) {
    final text = Theme.of(context).textTheme;
    return switch (role) {
      AppTextRole.display => text.displaySmall!,
      AppTextRole.headline => text.headlineSmall!,
      AppTextRole.title => text.titleMedium!,
      AppTextRole.body => text.bodyMedium!,
      AppTextRole.caption => text.bodySmall!,
      AppTextRole.label => text.labelMedium!,
    };
  }
}

class AppText extends StatelessWidget {
  const AppText(
    this.value, {
    super.key,
    this.role = AppTextRole.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String value;
  final AppTextRole role;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: AppTypography.style(context, role).copyWith(color: color),
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
  );
}
