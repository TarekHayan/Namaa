import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A keyboard key cap (for shortcut hints on desktop). The [label] is the key
/// name and always reads left to right.
class AppKeyCap extends StatelessWidget {
  const AppKeyCap({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: colors.border),
          top: BorderSide(color: colors.border),
          right: BorderSide(color: colors.border),
          bottom: BorderSide(color: colors.border, width: 2),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.fixed(
            13,
            FontWeight.w600,
            colors.textPrimary,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
