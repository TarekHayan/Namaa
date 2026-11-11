import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_supplication.dart';

/// The supplications card (the prototype's third group): the approved
/// Witr/Sujood supplications of the reviewed catalog, each in Amiri with
/// its authentic source.
final class QiyamSupplicationsCard extends StatelessWidget {
  const QiyamSupplicationsCard({
    super.key,
    required this.copy,
    required this.supplications,
    required this.locale,
  });

  final QiyamStrings copy;
  final List<QiyamSupplication> supplications;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEnglish = locale.startsWith('en');
    return Card(
      key: const Key('qiyam_supplications_card'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_border, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    copy.supplicationsTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final supplication in supplications) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        supplication.textAr,
                        key: Key('qiyam_supplication_${supplication.id}'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontFamily: 'Amiri', height: 1.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEnglish ? supplication.sourceEn : supplication.sourceAr,
                      key: Key('qiyam_supplication_source_${supplication.id}'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
