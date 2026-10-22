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
  });
  final String title;
  final TodaySection<T> section;
  final TodayStrings strings;
  final VoidCallback onRetry;
  final Widget Function(T value) content;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (section.status == TodaySectionStatus.loading)
            Text(strings.loading)
          else if (section.value == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.unavailable),
                TextButton(onPressed: onRetry, child: Text(strings.retry)),
              ],
            )
          else ...[
            content(section.value as T),
            if (section.status == TodaySectionStatus.stale)
              Row(
                children: [
                  Flexible(child: Text(strings.unavailable)),
                  TextButton(onPressed: onRetry, child: Text(strings.retry)),
                ],
              ),
          ],
        ],
      ),
    ),
  );
}
