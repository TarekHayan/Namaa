import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

import '../domain/adhkar_conflict_evidence.dart';

/// Read-only evidence from the encrypted owner-scoped conflict store
/// (contracts/adhkar-qiyam-ui.md): both versions of each retained count
/// conflict, with no resolve action of any kind. Entries name the list and
/// the item's position from the catalog (never the internal item id), and
/// the day is formatted with the app locale (Phase 6 review finding 3).
class AdhkarConflictsView extends StatelessWidget {
  // Not const: the view caches its catalog future in a late final field.
  AdhkarConflictsView({
    super.key,
    required this.conflicts,
    required this.catalog,
    required this.ownerId,
    required this.locale,
  });

  final Stream<List<AdhkarConflictEvidence>> conflicts;
  final AdhkarCatalogPort catalog;
  final String ownerId;
  final String locale;

  /// The catalog resolves once per view; every row's title is a synchronous
  /// lookup over it (a future created inside build would be replaced on
  /// every rebuild and never surface).
  late final Future<AdhkarCatalog?> _catalogFuture = catalog
      .snapshot(ownerId)
      .then((result) => result.valueOrNull);

  @override
  Widget build(BuildContext context) => FutureBuilder<AdhkarCatalog?>(
    future: _catalogFuture,
    builder: (context, catalogSnapshot) =>
        StreamBuilder<List<AdhkarConflictEvidence>>(
          stream: conflicts,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <AdhkarConflictEvidence>[];
            if (rows.isEmpty) return const SizedBox.shrink();
            final copy = FoundationLocalizations.of(context);
            final theme = Theme.of(context);
            final resolvedCatalog = catalogSnapshot.data;
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
                            _titleFor(copy, resolvedCatalog, row),
                            key: ValueKey('adhkar-conflict-${row.id}'),
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            _day(row),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
        ),
  );

  /// The human entry title: the list name plus the item's position from the
  /// catalog ("Morning adhkar · item 1"); an item the catalog does not know
  /// falls back to the list name alone, and an unknown list or catalog keeps
  /// the formatted day. No internal ids, no religious text.
  String _titleFor(
    FoundationLocalizations copy,
    AdhkarCatalog? resolvedCatalog,
    AdhkarConflictEvidence row,
  ) {
    final list = row.list;
    if (resolvedCatalog == null || list == null) {
      return _day(row);
    }
    final listName = switch (list) {
      'morning' => copy.adhkarConflictListMorning,
      'evening' => copy.adhkarConflictListEvening,
      _ => null,
    };
    if (listName == null) {
      return _day(row);
    }
    final listEnum = list == 'morning'
        ? AdhkarList.morning
        : AdhkarList.evening;
    for (final item in resolvedCatalog.itemsOf(listEnum)) {
      if (item.itemId == row.itemId) {
        return '$listName \u00b7 ${copy.adhkarConflictItem(item.position)}';
      }
    }
    return listName;
  }

  String _day(AdhkarConflictEvidence row) => DateFormat.MMMEd(locale).format(
    DateTime.utc(
      int.parse(row.adhkarDay.substring(0, 4)),
      int.parse(row.adhkarDay.substring(5, 7)),
      int.parse(row.adhkarDay.substring(8, 10)),
    ),
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
