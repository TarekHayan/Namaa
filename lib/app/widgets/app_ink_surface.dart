import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A tappable rounded surface with an ink ripple: the base of tiles, rows and
/// chips. The fill and border come from the theme tokens unless a caller
/// picks another token color. Callers add their own `Semantics` when the
/// control needs a label.
class AppInkSurface extends StatelessWidget {
  const AppInkSurface({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.borderColor,
    this.radius = 16,
    this.stadium = false,
    this.minHeight,
    this.padding,
    this.clip = Clip.none,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// The fill; the surface color when null.
  final Color? color;

  /// The outline; none when null.
  final Color? borderColor;
  final double radius;

  /// A fully rounded (pill) outline instead of [radius].
  final bool stadium;
  final double? minHeight;
  final EdgeInsetsGeometry? padding;

  /// Clips the content to the rounded outline.
  final Clip clip;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final side = borderColor == null
        ? BorderSide.none
        : BorderSide(color: borderColor!);
    final ShapeBorder shape = stadium
        ? StadiumBorder(side: side)
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: side,
          );
    final ShapeBorder ripple = stadium
        ? const StadiumBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    Widget content = child;
    if (padding != null) content = Padding(padding: padding!, child: content);
    if (minHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight!),
        child: content,
      );
    }
    return Material(
      color: color ?? colors.surface,
      shape: shape,
      clipBehavior: clip,
      child: InkWell(onTap: onTap, customBorder: ripple, child: content),
    );
  }
}
