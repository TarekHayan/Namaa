import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_ink_surface.dart';

/// One choice of a single-select group, drawn as a pill at least 56 x 48 px:
/// the selected choice gets the soft accent fill and the accent outline.
/// Callers pass the translated [label]; [semanticLabel] replaces it for
/// assistive technology when the label is only a number or a symbol.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onSelected != null,
      excludeSemantics: true,
      label: semanticLabel ?? label,
      onTap: onSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 56),
        child: AppInkSurface(
          stadium: true,
          color: selected ? colors.accentSoft : colors.surfaceSecondary,
          borderColor: selected ? colors.primary : colors.border,
          minHeight: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: onSelected,
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.fixed(
                16,
                selected ? FontWeight.w700 : FontWeight.w600,
                selected ? colors.accentStrong : colors.textPrimary,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ),
      ),
    );
  }
}
