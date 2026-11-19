import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_action_tile.dart';
import 'package:namma_project/app/widgets/app_conflicts.dart';

import '../domain/qiyam_conflict_evidence.dart';

/// The compact "Sync differences" row on the Qiyam page: it renders nothing
/// unless the owner has retained night conflicts, and opens the read-only
/// page.
final class QiyamConflictsRow extends StatelessWidget {
  const QiyamConflictsRow({
    super.key,
    required this.conflicts,
    required this.onOpen,
  });

  final Stream<List<QiyamConflictEvidence>> conflicts;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<List<QiyamConflictEvidence>>(
        stream: conflicts,
        builder: (context, snapshot) {
          if (snapshot.data?.isEmpty ?? true) return const SizedBox.shrink();
          return AppActionTile(
            key: const Key('qiyam_sync_row'),
            icon: Icons.sync_alt_rounded,
            label: FoundationLocalizations.of(context).qiyamConflicts,
            onTap: onOpen,
          );
        },
      );
}

/// The read-only "Sync differences" page inside `/qiyam` (approved design,
/// 2026-11-18), the same page as Adhkar's: each retained night conflict shows
/// both versions — stacked on a phone, side by side on a wide window — with
/// the time each was saved, the answer, the times and the note, and the
/// footer saying there is nothing to do. The word "missed" never appears and
/// no resolution action is offered; the only control returns to Qiyam.
final class QiyamConflictsPage extends StatelessWidget {
  const QiyamConflictsPage({
    super.key,
    required this.conflicts,
    required this.currentNight,
    required this.onBack,
    this.now,
  });

  final Stream<List<QiyamConflictEvidence>> conflicts;

  /// Tonight's date, so its entry reads "Tonight" instead of a date.
  final String? currentNight;
  final VoidCallback onBack;

  /// The clock behind "Today" and "Yesterday" in the version times.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final localizations = FoundationLocalizations.of(context);
    final copy = QiyamStrings(localizations);
    final locale = localizations.localeName;
    final clock = now ?? DateTime.now;
    return StreamBuilder<List<QiyamConflictEvidence>>(
      stream: conflicts,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <QiyamConflictEvidence>[];
        String stamp(DateTime at) => appConflictStamp(
          at: at,
          now: clock(),
          locale: locale,
          today: copy.today,
          yesterday: copy.yesterday,
        );
        return AppConflictsPage(
          pageKey: const Key('qiyam_sync_page'),
          backKey: const Key('qiyam_sync_back'),
          footerKey: const Key('qiyam_sync_footer'),
          title: copy.conflicts,
          backLabel: copy.conflictBack,
          onBack: onBack,
          footer: copy.conflictReadOnly,
          entries: [
            for (final row in rows)
              AppConflictEntryCard(
                titleKey: ValueKey('qiyam-conflict-${row.id}'),
                title: row.nightDate == currentNight
                    ? copy.conflictTonight
                    : copy.conflictNight(_night(locale, row.nightDate)),
                active: _Version(
                  copy: copy,
                  label: copy.conflictActive,
                  time: stamp(row.activeAt),
                  activeVersion: true,
                  performed: row.activePerformed,
                  rakahs: row.activeRakahs,
                  witr: row.activeWitr,
                  startTime: row.activeStartTime,
                  endTime: row.activeEndTime,
                  note: row.activeNote,
                ),
                saved: _Version(
                  copy: copy,
                  label: copy.conflictRetained,
                  time: stamp(row.retainedAt),
                  activeVersion: false,
                  performed: row.retainedPerformed,
                  rakahs: row.retainedRakahs,
                  witr: row.retainedWitr,
                  startTime: row.retainedStartTime,
                  endTime: row.retainedEndTime,
                  note: row.retainedNote,
                ),
              ),
          ],
        );
      },
    );
  }

  /// The night formatted with the app locale; a raw ISO date never reaches
  /// the UI.
  static String _night(String locale, String nightDate) =>
      DateFormat.MMMEd(locale).format(
        DateTime.utc(
          int.parse(nightDate.substring(0, 4)),
          int.parse(nightDate.substring(5, 7)),
          int.parse(nightDate.substring(8, 10)),
        ),
      );
}

/// One stored version of a night: the answer (with its rak'ahs and Witr), the
/// time range and the note, each shown only when it was recorded.
final class _Version extends StatelessWidget {
  const _Version({
    required this.copy,
    required this.label,
    required this.time,
    required this.activeVersion,
    required this.performed,
    required this.rakahs,
    required this.witr,
    required this.startTime,
    required this.endTime,
    required this.note,
  });

  final QiyamStrings copy;
  final String label;
  final String time;
  final bool activeVersion;
  final bool performed;
  final int? rakahs;
  final bool witr;
  final String? startTime;
  final String? endTime;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ambient = Directionality.of(context);
    final answer = performed
        ? copy.conflictAnswerYes(rakahs ?? 0, witr: witr)
        : copy.no;
    final range = [?startTime, ?endTime].join(' – ');
    final text = note;
    return AppConflictVersionCard(
      label: label,
      time: time,
      activeVersion: activeVersion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer,
            style: AppTypography.fixed(
              16,
              FontWeight.w600,
              colors.textPrimary,
              height: 1.7,
            ),
          ),
          if (performed) ...[
            if (range.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                range,
                textDirection: TextDirection.ltr,
                style: AppTypography.fixed(
                  14,
                  FontWeight.w400,
                  colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (text != null && text.isNotEmpty)
              Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textDirection: AppTypography.directionFor(text, ambient),
                style: AppTypography.fixed(
                  20,
                  FontWeight.w400,
                  colors.textPrimary,
                  height: 1.9,
                ).copyWith(fontFamily: 'Amiri'),
              )
            else
              Text(
                copy.noNote,
                style: AppTypography.fixed(
                  14,
                  FontWeight.w400,
                  colors.textSecondary,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
