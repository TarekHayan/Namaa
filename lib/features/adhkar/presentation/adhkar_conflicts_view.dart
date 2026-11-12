import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';

import '../domain/adhkar_conflict_evidence.dart';

/// Read-only evidence from the encrypted owner-scoped conflict store
/// (contracts/adhkar-qiyam-ui.md): both versions of each retained count
/// conflict, with no resolve action of any kind.
class AdhkarConflictsView extends StatelessWidget {
  const AdhkarConflictsView({super.key, required this.conflicts});

  final Stream<List<AdhkarConflictEvidence>> conflicts;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<List<AdhkarConflictEvidence>>(
        stream: conflicts,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <AdhkarConflictEvidence>[];
          if (rows.isEmpty) return const SizedBox.shrink();
          final copy = FoundationLocalizations.of(context);
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.adhkarConflicts, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final row in rows)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${row.itemId} · ${row.adhkarDay}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _VersionLine(
                          label: copy.adhkarConflictActive,
                          state: copy.adhkarConflictCount(row.activeCount),
                        ),
                        const SizedBox(height: 6),
                        _VersionLine(
                          label: copy.adhkarConflictRetained,
                          state: copy.adhkarConflictCount(row.retainedCount),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          copy.adhkarConflictReadOnly,
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
