import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_menu_design.dart';
import '../theme/app_typography.dart';

/// One entry of an [AppMenuButton]. The [label] is translated by the caller.
final class AppMenuEntry<T> {
  const AppMenuEntry({
    required this.value,
    required this.label,
    required this.icon,
    this.destructive = false,
  });

  final T value;
  final String label;
  final IconData icon;

  /// Draws the entry in the error text color (a delete action).
  final bool destructive;
}

/// The three-dot overflow button (48 px) that opens a menu with the shared
/// menu design ([AppMenuDesign]): the surface, outline and 18 px corners.
/// [tooltip] is the accessibility label.
class AppMenuButton<T> extends StatelessWidget {
  const AppMenuButton({
    super.key,
    required this.tooltip,
    required this.onSelected,
    required this.entries,
  });

  final String tooltip;
  final ValueChanged<T> onSelected;
  final List<AppMenuEntry<T>> entries;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final design = AppMenuDesign.popupTheme(colors);
    return PopupMenuButton<T>(
      tooltip: tooltip,
      onSelected: onSelected,
      color: design.color,
      surfaceTintColor: design.surfaceTintColor,
      elevation: AppMenuDesign.overflowElevation,
      shadowColor: colors.glow,
      padding: EdgeInsets.zero,
      position: design.position,
      constraints: AppMenuDesign.overflowConstraints,
      shape: design.shape,
      itemBuilder: (_) => [
        for (final entry in entries)
          PopupMenuItem<T>(
            value: entry.value,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  entry.icon,
                  size: 20,
                  color: entry.destructive
                      ? colors.errorText
                      : colors.textPrimary,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    entry.label,
                    style: AppTypography.fixed(
                      16,
                      FontWeight.w600,
                      entry.destructive ? colors.errorText : colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.more_vert, size: 22, color: colors.textPrimary),
      ),
    );
  }
}
