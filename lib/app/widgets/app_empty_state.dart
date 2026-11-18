import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_icon_badge.dart';

/// A centered empty state: a round icon badge, an optional title, an optional
/// body and an optional action. Callers pass the translated text and the
/// action widget (usually an `AppButton`).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    this.title,
    this.body,
    this.action,
    this.badgeSize = 88,
    this.iconSize = 40,
    this.tone = AppBadgeTone.accent,
  });

  final IconData icon;
  final String? title;
  final String? body;
  final Widget? action;
  final double badgeSize;
  final double iconSize;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final parts = <Widget>[
      AppIconBadge(icon: icon, size: badgeSize, iconSize: iconSize, tone: tone),
      if (title != null)
        Text(
          title!,
          textAlign: TextAlign.center,
          style: AppTypography.fixed(
            20,
            FontWeight.w800,
            colors.textPrimary,
            height: 1.45,
          ),
        ),
      if (body != null)
        Text(
          body!,
          textAlign: TextAlign.center,
          style: AppTypography.fixed(
            16,
            FontWeight.w400,
            colors.textSecondary,
            height: 1.8,
          ),
        ),
      ?action,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Column(
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            parts[i],
          ],
        ],
      ),
    );
  }
}
