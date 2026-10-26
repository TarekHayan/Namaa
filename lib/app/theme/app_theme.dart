/// Shared Foundation theme definitions.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_menu_design.dart';
import 'app_typography.dart';

export 'app_typography.dart' show kProjectFontFamily;

/// The application root owns the three approved appearance modes; this class
/// supplies only the shared light and dark ThemeData definitions.
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  /// Re-evaluated by the app root when the window crosses a width breakpoint.
  static ThemeData forWidth(ThemeData base, double width) {
    final colors = base.brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final type = AppTypography.textTheme(colors, width);
    return base.copyWith(
      textTheme: type,
      appBarTheme: base.appBarTheme.copyWith(titleTextStyle: type.titleLarge),
    );
  }

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          secondary: colors.secondary,
          surface: colors.surface,
          onSurface: colors.textPrimary,
          error: colors.error,
        );
    return ThemeData(
      brightness: brightness,
      fontFamily: kProjectFontFamily,
      textTheme: AppTypography.textTheme(colors, 390),
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.surface,
      cardColor: colors.surface,
      hoverColor: colors.accentSoft,
      focusColor: colors.accentSoft,
      highlightColor: colors.accentSoft,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme(colors, 390).titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.primary.computeLuminance() > 0.22
                  ? const Color(0xFF062016)
                  : Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              overlayColor: WidgetStatePropertyAll(
                colors.primary.withValues(alpha: 0.14),
              ),
              shadowColor: WidgetStatePropertyAll(colors.cardGlow),
              elevation: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)
                    ? 6
                    : 0,
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)
                    ? colors.accentSoft
                    : null,
              ),
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color:
                      states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.focused)
                      ? colors.primary.withValues(alpha: 0.65)
                      : colors.border,
                ),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: colors.primary,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ).copyWith(
              animationDuration: const Duration(milliseconds: 180),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)
                    ? colors.accentSoft
                    : null,
              ),
            ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 180),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)
                ? colors.accentSoft
                : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)
                ? colors.primary
                : colors.textSecondary,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceSecondary,
        circularTrackColor: colors.surfaceSecondary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceSecondary,
        contentTextStyle: TextStyle(color: colors.textPrimary),
        actionTextColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.border),
        ),
      ),
      popupMenuTheme: AppMenuDesign.popupTheme(colors),
      menuTheme: MenuThemeData(style: AppMenuDesign.menuStyle(colors)),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: AppMenuDesign.menuStyle(colors),
        textStyle: TextStyle(color: colors.textPrimary),
      ),
    );
  }
}
