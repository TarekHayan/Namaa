import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The fill and outline of an [AppCard].
enum AppCardTone {
  /// The page surface with a hairline border.
  surface,

  /// The secondary surface with a hairline border (inset groups, tab bars).
  secondary,

  /// A soft accent fill with an accent border (a highlighted state).
  accent,

  /// A soft warning fill with a warning border (notices).
  warning,

  /// A soft error fill with an error border (destructive confirmations).
  error,
}

/// A rounded card whose fill, border and glow come from the theme tokens.
/// Use it for any boxed block instead of hand-built `BoxDecoration`s.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.tone = AppCardTone.surface,
    this.radius = 24,
    this.padding,
    this.constraints,
    this.elevated = false,
  });

  final Widget child;
  final AppCardTone tone;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  /// Adds the soft card glow.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (fill, outline) = switch (tone) {
      AppCardTone.surface => (colors.surface, colors.border),
      AppCardTone.secondary => (colors.surfaceSecondary, colors.border),
      AppCardTone.accent => (colors.accentSoft, colors.primary),
      AppCardTone.warning => (colors.warningSoft, colors.warning),
      AppCardTone.error => (colors.errorSoft, colors.error),
    };
    return Container(
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: outline),
        boxShadow: elevated ? colors.cardShadow : null,
      ),
      child: child,
    );
  }
}
