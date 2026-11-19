import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A selectable pill (48 px tap target) with the accent outline and a check
/// when selected: one choice of a multi-select group. The [label] is the
/// caller's text; pass [textDirection] for user-entered text.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.textDirection,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      checkmarkColor: colors.accentStrong,
      backgroundColor: colors.surfaceSecondary,
      selectedColor: colors.accentSoft,
      surfaceTintColor: Colors.transparent,
      side: BorderSide(color: selected ? colors.primary : colors.border),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      label: Text(
        label,
        textDirection: textDirection,
        style: AppTypography.fixed(
          14,
          selected ? FontWeight.w700 : FontWeight.w600,
          selected ? colors.accentStrong : colors.textPrimary,
        ),
      ),
    );
  }
}
