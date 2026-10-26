import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared surface and spacing for choice lists across the app.
abstract final class AppMenuDesign {
  static const BorderRadius radius = BorderRadius.all(Radius.circular(18));
  static const double maxHeight = 320;

  static PopupMenuThemeData popupTheme(AppColors colors) => PopupMenuThemeData(
    color: colors.surface,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.black.withValues(alpha: 0.28),
    elevation: 12,
    shape: RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(color: colors.border),
    ),
    menuPadding: const EdgeInsets.symmetric(vertical: 6),
    position: PopupMenuPosition.under,
    textStyle: TextStyle(
      color: colors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
    ),
  );

  static MenuStyle menuStyle(AppColors colors) => MenuStyle(
    backgroundColor: WidgetStatePropertyAll(colors.surface),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(12),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.border),
      ),
    ),
  );
}
