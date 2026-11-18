import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// An accent text link with a back arrow, for returning one level inside a
/// page (there is no app-bar back arrow). Callers pass the translated label.
class AppBackLink extends StatelessWidget {
  const AppBackLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 20, color: colors.accentStrong),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.fixed(
                    16,
                    FontWeight.w700,
                    colors.accentStrong,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
