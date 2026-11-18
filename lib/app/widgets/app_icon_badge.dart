import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The color family of an [AppIconBadge].
enum AppBadgeTone {
  /// Soft accent fill, accent icon.
  accent,

  /// Secondary surface fill, muted icon.
  neutral,

  /// Soft warning fill, warning icon.
  warning,

  /// Soft error fill, error icon.
  error,
}

/// A round badge holding one icon: the mark of an empty, finished or error
/// state and of a leading list icon.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    required this.size,
    required this.iconSize,
    this.tone = AppBadgeTone.accent,
    this.bordered = true,
    this.borderColor,
  });

  final IconData icon;

  /// The diameter of the badge.
  final double size;
  final double iconSize;
  final AppBadgeTone tone;

  /// Draws the border: a hairline, or [borderColor] when given.
  final bool bordered;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (fill, glyph) = switch (tone) {
      AppBadgeTone.accent => (colors.accentSoft, colors.accentStrong),
      AppBadgeTone.neutral => (colors.surfaceSecondary, colors.textSecondary),
      AppBadgeTone.warning => (colors.warningSoft, colors.warning),
      AppBadgeTone.error => (colors.errorSoft, colors.error),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: bordered
            ? Border.all(color: borderColor ?? colors.border)
            : null,
      ),
      child: Icon(icon, size: iconSize, color: glyph),
    );
  }
}
