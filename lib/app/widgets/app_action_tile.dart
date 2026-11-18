import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_ink_surface.dart';

/// A bordered tappable row on the secondary surface: a leading icon, a label
/// and a chevron. Callers pass the translated label.
class AppActionTile extends StatelessWidget {
  const AppActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppInkSurface(
      color: colors.surfaceSecondary,
      borderColor: colors.border,
      radius: 18,
      minHeight: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.fixed(
                14,
                FontWeight.w600,
                colors.textPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: colors.textPrimary),
        ],
      ),
    );
  }
}
