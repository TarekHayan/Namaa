import 'package:flutter/material.dart';

import '../today_strings.dart';

class TodayOverdueSection extends StatelessWidget {
  const TodayOverdueSection({
    super.key,
    required this.count,
    required this.strings,
    required this.onOpenOverdue,
  });

  final int count;
  final TodayStrings strings;
  final VoidCallback onOpenOverdue;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '${strings.overdue}: ${strings.formatCount(count)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      TextButton(
        key: const Key('today_open_overdue'),
        onPressed: onOpenOverdue,
        child: Text(strings.openOverdue),
      ),
    ],
  );
}
