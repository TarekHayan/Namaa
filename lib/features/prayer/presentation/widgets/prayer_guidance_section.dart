import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';

class PrayerGuidanceSection extends StatelessWidget {
  const PrayerGuidanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    return Card(
      key: const Key('prayer_guidance_section'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width >= 640 ? 32 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              copy.prayerRecitationHeading,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 600 &&
                    MediaQuery.textScalerOf(context).scale(1) <= 1.3;
                final panels = [
                  _panel(
                    context,
                    copy.prayerJahrTitle,
                    copy.prayerJahrDefinition,
                    const Key('prayer_guidance_jahr'),
                  ),
                  _panel(
                    context,
                    copy.prayerSirrTitle,
                    copy.prayerSirrDefinition,
                    const Key('prayer_guidance_sirr'),
                  ),
                ];
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: panels[0]),
                          const SizedBox(width: 12),
                          Expanded(child: panels[1]),
                        ],
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
            const SizedBox(height: 12),
            Text(
              copy.prayerGuidanceScope,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              copy.prayerGuidanceSource,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, String title, String body, Key key) =>
      Container(
        key: key,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}
