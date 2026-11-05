import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';

import '../domain/prayer_conflict_evidence.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_status.dart';

/// Read-only evidence from the encrypted owner-scoped conflict store.
class PrayerConflictsView extends StatelessWidget {
  const PrayerConflictsView({super.key, required this.conflicts});

  final Stream<List<PrayerConflictEvidence>> conflicts;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<List<PrayerConflictEvidence>>(
        stream: conflicts,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <PrayerConflictEvidence>[];
          if (rows.isEmpty) return const SizedBox.shrink();
          final copy = FoundationLocalizations.of(context);
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.prayerConflicts, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final row in rows)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${_name(copy, row.name)} · ${row.date.value}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _VersionLine(
                          label: copy.prayerConflictActive,
                          status: _status(copy, row.activeStatus),
                        ),
                        const SizedBox(height: 6),
                        _VersionLine(
                          label: copy.prayerConflictRetained,
                          status: _status(copy, row.retainedStatus),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          copy.prayerConflictReadOnly,
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

  String _name(FoundationLocalizations copy, PrayerName name) => switch (name) {
    PrayerName.fajr => copy.prayerFajr,
    PrayerName.dhuhr => copy.prayerDhuhr,
    PrayerName.asr => copy.prayerAsr,
    PrayerName.maghrib => copy.prayerMaghrib,
    PrayerName.isha => copy.prayerIsha,
  };

  String _status(FoundationLocalizations copy, PrayerStatus status) =>
      switch (status) {
        PrayerStatus.pending => copy.prayerStatusPending,
        PrayerStatus.completedOnTime => copy.prayerStatusOnTime,
        PrayerStatus.completedLate => copy.prayerStatusLate,
        PrayerStatus.missed => copy.prayerStatusMissed,
      };
}

class _VersionLine extends StatelessWidget {
  const _VersionLine({required this.label, required this.status});
  final String label;
  final String status;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      Flexible(child: Text(status, textAlign: TextAlign.end)),
    ],
  );
}
