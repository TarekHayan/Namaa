/// Namaa's default Emerald palette from prototype/src/utils/personalization.ts.
library;

import 'package:flutter/material.dart';

/// Reference tokens shared by the app theme and feature screens.
@immutable
final class AppColors {
  const AppColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.accentSoft,
    required this.inputBackground,
    required this.inputBorder,
    required this.navigationBackground,
    required this.cardGlow,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.accentStrong,
    required this.onAccentStrong,
    required this.track,
    required this.warningSoft,
    required this.errorSoft,
    required this.errorText,
    required this.onError,
    required this.scrim,
    required this.glow,
    required this.cardShadow,
    required this.buttonShadow,
  });

  /// The tokens of the active theme brightness. Shared widgets and feature
  /// views read their colors through this.
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const light = AppColors(
    primary: Color(0xFF059669),
    secondary: Color(0xFF047857),
    background: Color(0xFFF8FAF8),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF0F4F1),
    textPrimary: Color(0xFF0D1410),
    textSecondary: Color(0xFF374151),
    textMuted: Color(0xFF6B7280),
    border: Color(0x14000000),
    accentSoft: Color(0x1F059669),
    inputBackground: Color(0xFFF3F4F6),
    inputBorder: Color(0x1F000000),
    navigationBackground: Color(0xF0FFFFFF),
    cardGlow: Color(0x26059669),
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
    accentStrong: Color(0xFF047857),
    onAccentStrong: Color(0xFFFFFFFF),
    track: Color(0x29059669),
    warningSoft: Color(0x1FD97706),
    errorSoft: Color(0x14DC2626),
    errorText: Color(0xFFB91C1C),
    onError: Color(0xFFFFFFFF),
    scrim: Color(0x6B0D1410),
    glow: Color(0x1F059669),
    cardShadow: [
      BoxShadow(color: Color(0x1F059669), blurRadius: 18, offset: Offset(0, 4)),
    ],
    buttonShadow: [
      BoxShadow(color: Color(0x57059669), blurRadius: 24, offset: Offset(0, 6)),
    ],
  );

  static const dark = AppColors(
    primary: Color(0xFF10B981),
    secondary: Color(0xFF059669),
    background: Color(0xFF050805),
    surface: Color(0xFF0A0F0C),
    surfaceSecondary: Color(0xFF111A14),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB8FFFFFF),
    textMuted: Color(0x6BFFFFFF),
    border: Color(0x1AFFFFFF),
    accentSoft: Color(0x2910B981),
    inputBackground: Color(0xFF0A0D0B),
    inputBorder: Color(0x1AFFFFFF),
    navigationBackground: Color(0xEB0A0F0C),
    cardGlow: Color(0x4010B981),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
    accentStrong: Color(0xFF10B981),
    onAccentStrong: Color(0xFF050805),
    track: Color(0x3310B981),
    warningSoft: Color(0x24F59E0B),
    errorSoft: Color(0x24EF4444),
    errorText: Color(0xFFF87171),
    onError: Color(0xFF050805),
    scrim: Color(0xA8000000),
    glow: Color(0x2410B981),
    cardShadow: [
      BoxShadow(color: Color(0x2410B981), spreadRadius: 1),
      BoxShadow(color: Color(0x2410B981), blurRadius: 22),
    ],
    buttonShadow: [BoxShadow(color: Color(0x6B10B981), blurRadius: 30)],
  );

  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color accentSoft;
  final Color inputBackground;
  final Color inputBorder;
  final Color navigationBackground;
  final Color cardGlow;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  /// Accent for text, icons and filled actions. Deeper than [primary] in the
  /// light theme so it reads on light surfaces; the same as [primary] in dark.
  final Color accentStrong;

  /// Text and icons on a filled [accentStrong] surface.
  final Color onAccentStrong;

  /// The unfilled part of a progress ring.
  final Color track;

  /// Soft fills for warning and error notices.
  final Color warningSoft;
  final Color errorSoft;

  /// Error text and icons on the page surface (stronger than [error] in light).
  final Color errorText;

  /// Text and icons on a filled [error] surface.
  final Color onError;

  /// The dimmed layer behind sheets and dialogs.
  final Color scrim;

  /// The soft glow color (menu shadows).
  final Color glow;

  /// The soft glow around raised cards, sheets and floating controls.
  final List<BoxShadow> cardShadow;

  /// The stronger glow under a filled accent button.
  final List<BoxShadow> buttonShadow;
}
