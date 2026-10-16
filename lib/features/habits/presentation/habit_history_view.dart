import 'package:flutter/material.dart';
import 'package:namma_project/features/habits/application/habit_queries.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/presentation/habits_strings.dart';

const Key kHabitHistoryDialogKey = Key('habit_history_dialog');

/// Read-only history. Current-day actions remain on the owning Habits screen.
abstract final class HabitHistoryView {
  static Future<void> show(
    BuildContext context, {
    required HabitHistory history,
    required HabitsStrings strings,
  }) => showDialog<void>(
    context: context,
    builder: (context) {
      final material = MaterialLocalizations.of(context);
      String dateLabel(String value) =>
          material.formatMediumDate(parseHabitLocalDate(value));
      return AlertDialog(
        key: kHabitHistoryDialogKey,
        title: Text('${history.habit.name} · ${strings.history}'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${strings.currentStreak}: ${history.currentStreak}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (history.isTodayPending) ...[
                  const SizedBox(height: 4),
                  Text(strings.pendingToday),
                ],
                const SizedBox(height: 16),
                Text(
                  strings.completedDates,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (history.completedDates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(strings.noCompletedDates),
                  )
                else
                  for (final date in history.completedDates)
                    ListTile(
                      key: ValueKey(
                        'habit-history-date-${history.habit.id}-$date',
                      ),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(dateLabel(date)),
                      subtitle: Text(strings.completedOn),
                    ),
                const SizedBox(height: 16),
                Text(
                  strings.scheduleHistory,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final revision in history.scheduleRevisions.reversed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      revision.weekdays.map(strings.weekday).join(' • '),
                    ),
                    subtitle: Text(
                      '${strings.effectiveFrom} ${dateLabel(revision.effectiveLocalDate)}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.closeHistory),
          ),
        ],
      );
    },
  );
}
