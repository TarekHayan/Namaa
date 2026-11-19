import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_sheets.dart';

import '../qiyam_state.dart';
import 'qiyam_history_section.dart';

/// Opens one past night's read-only details: a bottom sheet on a phone, a
/// dialog on a wide window (approved design, 2026-11-18). It shows the
/// status, then — for a night that was prayed — the rak'ahs, Witr and times,
/// then the note, and offers only a Close button. The sheet reads its copy
/// from its own route, so it does not depend on the opener's providers.
Future<void> showQiyamNightDetails(
  BuildContext context, {
  required QiyamHistoryEntry entry,
}) => showAppAdaptiveSheet<void>(
  context,
  (sheetContext) => _NightDetails(entry: entry),
);

final class _NightDetails extends StatelessWidget {
  const _NightDetails({required this.entry});

  final QiyamHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final localizations = FoundationLocalizations.of(context);
    final copy = QiyamStrings(localizations);
    final colors = AppColors.of(context);
    final record = entry.record;
    final date = DateFormat.MMMMEEEEd(
      localizations.localeName,
    ).format(qiyamNightDay(entry.nightDate));
    final status = record == null
        ? copy.historyNotRecorded
        : record.performed
        ? copy.detailPrayed
        : copy.historyNotPerformed;
    final note = record?.note;
    final rows = <(String, String, bool)>[
      (copy.detailStatus, status, false),
      if (record != null && record.performed) ...[
        (copy.rakahsLabel, '${record.rakahs}', false),
        (copy.detailWitr, record.witr ? copy.segYes : copy.detailNo, false),
        if (record.startTime != null) (copy.startTime, record.startTime!, true),
        if (record.endTime != null) (copy.endTime, record.endTime!, true),
      ],
    ];
    return AppFormSheet(
      panelKey: const Key('qiyam_night_details'),
      title: copy.nightDetailsTitle,
      fields: [
        Text(
          date,
          key: const Key('qiyam_night_details_date'),
          style: AppTypography.fixed(14, FontWeight.w400, colors.textSecondary),
        ),
        for (final (label, value, ltr) in rows)
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.fixed(
                      14,
                      FontWeight.w400,
                      colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    textDirection: ltr ? TextDirection.ltr : null,
                    style: AppTypography.fixed(
                      16,
                      FontWeight.w600,
                      colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (note != null && note.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.notesLabel,
                style: AppTypography.fixed(
                  14,
                  FontWeight.w400,
                  colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                note,
                key: const Key('qiyam_night_details_note'),
                textDirection: AppTypography.directionFor(
                  note,
                  Directionality.of(context),
                ),
                style: AppTypography.fixed(
                  20,
                  FontWeight.w400,
                  colors.textPrimary,
                  height: 1.9,
                ).copyWith(fontFamily: 'Amiri'),
              ),
            ],
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  copy.readOnly,
                  style: AppTypography.fixed(
                    14,
                    FontWeight.w400,
                    colors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      footer: AppButton(
        key: const Key('qiyam_night_details_close'),
        label: copy.close,
        onPressed: () => Navigator.of(context).pop(),
        look: AppButtonLook.refined,
        variant: AppButtonVariant.secondary,
        size: AppButtonSize.small,
        expanded: true,
      ),
    );
  }
}
