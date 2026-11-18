import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// An icon button on a bordered surface: a rounded square by default, a circle
/// with [circle]. It dims when [onTap] is null. [label] is the accessibility
/// label, so callers pass translated text.
class AppSurfaceIconButton extends StatelessWidget {
  const AppSurfaceIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 48,
    this.iconSize = 22,
    this.circle = false,
    this.raised = false,
    this.disabledOpacity = 0.4,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// The width and height of the button.
  final double size;
  final double iconSize;
  final bool circle;

  /// The page-surface fill with the soft glow, instead of the secondary
  /// surface fill (a floating control beside a column).
  final bool raised;
  final double disabledOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final side = BorderSide(color: colors.border);
    final ShapeBorder shape = circle
        ? CircleBorder(side: side)
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: side,
          );
    final ShapeBorder ripple = circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    final Widget button = Material(
      color: raised ? colors.surface : colors.surfaceSecondary,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: ripple,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: colors.textPrimary),
        ),
      ),
    );
    return Opacity(
      opacity: onTap == null ? disabledOpacity : 1,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: raised
            ? Container(
                decoration: BoxDecoration(
                  shape: circle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: circle ? null : BorderRadius.circular(16),
                  boxShadow: colors.cardShadow,
                ),
                child: button,
              )
            : button,
      ),
    );
  }
}
