import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';

import '../domain/qiyam_conflict_evidence.dart';

/// Read-only evidence from the encrypted owner-scoped conflict store: both
/// versions of each retained night conflict, with no resolve action, and
/// the word "missed" never appears.
class QiyamConflictsView extends StatelessWidget {
  const QiyamConflictsView({super.key, required this.conflicts});

  final Stream<List<QiyamConflictEvidence>> conflicts;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<List<QiyamConflictEvidence>>(
        stream: conflicts,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <QiyamConflictEvidence>[];
          if (rows.isEmpty) return const SizedBox.shrink();
          final copy = FoundationLocalizations.of(context);
          final strings = QiyamStrings(copy);
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.qiyamConflicts, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final row in rows)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(row.nightDate, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),
                        _VersionLine(
                          label: copy.qiyamConflictActive,
                          state: _state(
                            strings,
                            row.activePerformed,
                            row.activeRakahs,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _VersionLine(
                          label: copy.qiyamConflictRetained,
                          state: _state(
                            strings,
                            row.retainedPerformed,
                            row.retainedRakahs,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          copy.qiyamConflictReadOnly,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );

  String _state(QiyamStrings strings, bool performed, int? rakahs) => performed
      ? strings.historyPrayed(rakahs ?? 0)
      : strings.historyNotPerformed;
}

class _VersionLine extends StatelessWidget {
  const _VersionLine({required this.label, required this.state});

  final String label;
  final String state;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      Flexible(child: Text(state, textAlign: TextAlign.end)),
    ],
  );
}
