import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

/// Prototype "Jahr vs Sirr" guide. Copy is Namaa's source-mapped wording
/// (guidance-sources.md), not the prototype's unreviewed text.
class PrayerGuidanceSection extends StatelessWidget {
  const PrayerGuidanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = dark ? AppColors.dark : AppColors.light;
    final note = text.labelSmall?.copyWith(
      color: colors.textMuted,
      fontWeight: FontWeight.w400,
      height: 1.5,
    );
    return Container(
      key: const Key('prayer_guidance_section'),
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width >= 640 ? 32 : 24,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.10)
              : colors.success.withValues(alpha: 0.20),
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: colors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  copy.prayerRecitationHeading,
                  style: text.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= 560 &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.3;
              final panels = [
                _panel(
                  context,
                  colors,
                  copy.prayerJahrTitle,
                  copy.prayerJahrDefinition,
                  const Key('prayer_guidance_jahr'),
                  accent: true,
                ),
                _panel(
                  context,
                  colors,
                  copy.prayerSirrTitle,
                  copy.prayerSirrDefinition,
                  const Key('prayer_guidance_sirr'),
                  accent: false,
                ),
              ];
              return wide
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: panels[0]),
                          const SizedBox(width: 12),
                          Expanded(child: panels[1]),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        panels[0],
                        const SizedBox(height: 12),
                        panels[1],
                      ],
                    );
            },
          ),
          const SizedBox(height: 14),
          Text(copy.prayerGuidanceContext, style: note),
          const SizedBox(height: 2),
          Text(copy.prayerGuidanceScope, style: note),
          const SizedBox(height: 2),
          Text(copy.prayerGuidanceSource, style: note),
        ],
      ),
    );
  }

  Widget _panel(
    BuildContext context,
    AppColors colors,
    String title,
    String body,
    Key key, {
    required bool accent,
  }) {
    final text = Theme.of(context).textTheme;
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        border: Border.all(
          color: accent
              ? colors.success.withValues(alpha: 0.20)
              : colors.border,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.labelLarge?.copyWith(
              color: accent ? colors.success : colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: text.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
