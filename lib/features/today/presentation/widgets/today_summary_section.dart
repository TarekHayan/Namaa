library;

import 'package:flutter/material.dart';
import 'package:namma_project/features/today/domain/today_section.dart';

import '../today_strings.dart';

class TodaySummarySection<T> extends StatelessWidget {
  const TodaySummarySection({
    super.key,
    required this.title,
    required this.section,
    required this.strings,
    required this.onRetry,
    required this.content,
    this.icon,
  });
  final String title;
  final TodaySection<T> section;
  final TodayStrings strings;
  final VoidCallback onRetry;
  final Widget Function(T value) content;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (icon != null)
                Icon(icon, color: Theme.of(context).colorScheme.primary),
            ],
          ),
          const SizedBox(height: 14),
          if (section.status == TodaySectionStatus.loading)
            Semantics(liveRegion: true, child: Text(strings.loading))
          else if (section.value == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(liveRegion: true, child: Text(strings.unavailable)),
                TextButton(onPressed: onRetry, child: Text(strings.retry)),
              ],
            )
          else ...[
            content(section.value as T),
            if (section.status == TodaySectionStatus.stale)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Semantics(liveRegion: true, child: Text(strings.outdated)),
                  TextButton(onPressed: onRetry, child: Text(strings.retry)),
                ],
              ),
          ],
        ],
      ),
    ),
  );
}
