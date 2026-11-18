import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_choice_chip.dart';
import 'package:namma_project/app/widgets/app_form_field.dart';
import 'package:namma_project/app/widgets/app_notice.dart';
import 'package:namma_project/app/widgets/app_switch_tile.dart';
import 'package:namma_project/app/widgets/app_time_field.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_state.dart';

import 'qiyam_header.dart' show qiyamLocalTime;

/// The optional details of a "Yes" night (approved design, 2026-11-18): the
/// rak'ah chips (2, 4, 8, 11), the start and end time fields, the Witr switch
/// and the note with its 500-character counter. Every change autosaves — the
/// cubit saves a chip, the switch and a complete time at once, and the note
/// about a second after typing stops — and the status beside the title says
/// "Saving…", "Saved" or that saving failed (the typed values stay, and the
/// next change retries). A value the rules reject is not saved and its message
/// shows under its own field.
///
/// The start and end times are never typed: a tap opens the clock dial (as in
/// Tasks), and any time from tonight's Isha to Fajr is accepted, the end after
/// the start and possibly past midnight (owner decision, 2026-11-18). A pick
/// outside that window, or an end that is not after the start, is not saved
/// and shows its message under its field. Without an Isha for the night (no
/// saved location, or no Isha in the schedule) any time is accepted.
final class QiyamDetailsForm extends StatefulWidget {
  const QiyamDetailsForm({
    super.key,
    required this.copy,
    required this.night,
    required this.form,
    required this.status,
    required this.failureMessageKey,
    required this.onRakahs,
    required this.onWitr,
    required this.onTimes,
    required this.onNote,
  });

  final QiyamStrings copy;

  /// The resolved night; its Isha and Fajr bound the times.
  final QiyamNightState? night;
  final QiyamForm form;
  final QiyamActionStatus? status;
  final String? failureMessageKey;
  final ValueChanged<int> onRakahs;
  final VoidCallback onWitr;
  final void Function(String? startTime, String? endTime) onTimes;
  final ValueChanged<String> onNote;

  @override
  State<QiyamDetailsForm> createState() => _QiyamDetailsFormState();
}

final class _QiyamDetailsFormState extends State<QiyamDetailsForm> {
  // The note controller starts from the stored value and then belongs to the
  // user: a later state emission never overwrites what is being typed.
  late final TextEditingController _note = TextEditingController(
    text: widget.form.note ?? '',
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: _note,
      builder: (context, _) {
        final key = widget.failureMessageKey;
        final failed = widget.status == QiyamActionStatus.failed;
        final noteLength = _note.text.length;
        final noteBad =
            noteLength > QiyamNightDraft.maxNoteLength ||
            (failed && key == 'qiyam.night.note_too_long');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  copy.detailsTitle,
                  style: AppTypography.fixed(
                    16,
                    FontWeight.w700,
                    colors.textPrimary,
                  ),
                ),
                _SaveStatus(
                  copy: copy,
                  status: widget.status,
                  failureMessageKey: key,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              copy.rakahsLabel,
              style: AppTypography.fixed(
                14,
                FontWeight.w700,
                colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rakahs in _rakahChoices)
                  AppChoiceChip(
                    key: Key('qiyam_rakah_chip_$rakahs'),
                    label: '$rakahs',
                    semanticLabel: copy.rakahsCount(rakahs),
                    selected: widget.form.rakahs == rakahs,
                    onSelected: () => widget.onRakahs(rakahs),
                  ),
              ],
            ),
            if (failed && key == 'qiyam.night.invalid_rakahs') ...[
              const SizedBox(height: 8),
              AppInlineNote(
                key: const Key('qiyam_rakahs_error'),
                text: copy.invalidRakahs,
                tone: AppNoticeTone.error,
              ),
            ],
            const SizedBox(height: 20),
            _TimeFields(
              copy: copy,
              night: widget.night,
              startTime: widget.form.startTime,
              endTime: widget.form.endTime,
              onTimes: widget.onTimes,
            ),
            const SizedBox(height: 12),
            AppSwitchTile(
              label: copy.witr,
              value: widget.form.witr,
              onChanged: (_) => widget.onWitr(),
              switchKey: const Key('qiyam_witr'),
            ),
            const SizedBox(height: 12),
            AppLabeledField(
              label: copy.notesLabel,
              field: TextField(
                key: const Key('qiyam_note'),
                controller: _note,
                minLines: 3,
                maxLines: 6,
                textDirection: AppTypography.directionFor(
                  _note.text,
                  Directionality.of(context),
                ),
                style: AppTypography.fixed(
                  16,
                  FontWeight.w400,
                  colors.textPrimary,
                  height: 1.7,
                ),
                decoration: appCountedFieldDecoration(
                  colors,
                  counterText: copy.noteCounter(noteLength),
                  counterKey: const Key('qiyam_note_counter'),
                  counterError: noteBad,
                  errorText: noteBad ? copy.noteTooLong : null,
                ).copyWith(hintText: copy.notesPlaceholder),
                onChanged: widget.onNote,
              ),
            ),
          ],
        );
      },
    );
  }

  static const List<int> _rakahChoices = [2, 4, 8, 11];
}

/// The start and end fields side by side, stacked when the card is too narrow
/// for two fields. Each is a clock-dial field; the picks are checked against
/// the night's Isha-to-Fajr window here, and a valid pick goes up as `HH:mm`.
final class _TimeFields extends StatelessWidget {
  const _TimeFields({
    required this.copy,
    required this.night,
    required this.startTime,
    required this.endTime,
    required this.onTimes,
  });

  final QiyamStrings copy;
  final QiyamNightState? night;
  final String? startTime;
  final String? endTime;
  final void Function(String? startTime, String? endTime) onTimes;

  /// Tonight's Isha-to-Fajr window as wall-clock times in the location's
  /// zone, or null when the night has none.
  AppTimeWindow? get _window {
    final resolved = night;
    final zone = resolved?.zoneId;
    final isha = resolved?.ishaUtc;
    final fajr = resolved?.nextFajrUtc;
    if (zone == null || isha == null || fajr == null) return null;
    final start = qiyamLocalTime(isha, zone);
    final end = qiyamLocalTime(fajr, zone);
    if (start == null || end == null) return null;
    return AppTimeWindow(start: start, end: end);
  }

  static TimeOfDay? _parse(String? value) {
    if (value == null || !QiyamNightDraft.isValidTime(value)) return null;
    return TimeOfDay(
      hour: int.parse(value.substring(0, 2)),
      minute: int.parse(value.substring(3, 5)),
    );
  }

  static String _format24(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final window = _window;
    final start = _parse(startTime);
    final end = _parse(endTime);

    String? outside(TimeOfDay picked) =>
        window == null || window.contains(picked)
        ? null
        : copy.timeOutsideWindow(
            AppTimeField.format(context, window.start),
            AppTimeField.format(context, window.end),
          );

    String? endError(TimeOfDay picked) {
      final bad = outside(picked);
      if (bad != null) return bad;
      if (window != null &&
          start != null &&
          window.offsetOf(picked) <= window.offsetOf(start)) {
        return copy.endAfterStart;
      }
      return null;
    }

    // Where each dial opens when nothing is saved: Isha for the start, an
    // hour after the start for the end, never past Fajr.
    TimeOfDay? endInitial;
    final endBase = start ?? window?.start;
    if (endBase != null) {
      final later = AppTimeWindow.shifted(endBase, 60);
      endInitial = window == null || window.contains(later)
          ? later
          : window.end;
    }

    final startField = AppLabeledField(
      label: copy.startTime,
      field: AppTimeField(
        fieldKey: const Key('qiyam_start_time'),
        errorKey: const Key('qiyam_start_time_error'),
        value: start,
        initialTime: window?.start,
        semanticLabel: copy.startTime,
        pickHint: copy.pickTime,
        validator: outside,
        onPicked: (picked) => onTimes(_format24(picked), endTime),
      ),
    );
    final endField = AppLabeledField(
      label: copy.endTime,
      field: AppTimeField(
        fieldKey: const Key('qiyam_end_time'),
        errorKey: const Key('qiyam_end_time_error'),
        value: end,
        initialTime: endInitial,
        semanticLabel: copy.endTime,
        pickHint: copy.pickTime,
        validator: endError,
        onPicked: (picked) => onTimes(startTime, _format24(picked)),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 312) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [startField, const SizedBox(height: 12), endField],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: startField),
            const SizedBox(width: 12),
            Expanded(child: endField),
          ],
        );
      },
    );
  }
}

/// "Saving…", "Saved" or the save failure, beside the details title. A
/// validation failure is shown under its own field instead, so it adds
/// nothing here.
final class _SaveStatus extends StatelessWidget {
  const _SaveStatus({
    required this.copy,
    required this.status,
    required this.failureMessageKey,
  });

  final QiyamStrings copy;
  final QiyamActionStatus? status;
  final String? failureMessageKey;

  static const Set<String> _fieldMessages = {
    'qiyam.night.invalid_rakahs',
    'qiyam.night.note_too_long',
    'qiyam.night.not_performed_details',
  };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    TextStyle style(Color color) =>
        AppTypography.fixed(14, FontWeight.w600, color);
    switch (status) {
      case QiyamActionStatus.pending:
        return Semantics(
          liveRegion: true,
          child: Row(
            key: const Key('qiyam_status'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: colors.textSecondary,
                  backgroundColor: colors.textSecondary.withValues(alpha: 0.25),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(copy.saving, style: style(colors.textSecondary)),
              ),
            ],
          ),
        );
      case QiyamActionStatus.saved:
        return Semantics(
          liveRegion: true,
          child: Row(
            key: const Key('qiyam_status'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 16, color: colors.accentStrong),
              const SizedBox(width: 6),
              Flexible(
                child: Text(copy.saved, style: style(colors.accentStrong)),
              ),
            ],
          ),
        );
      case QiyamActionStatus.failed:
        if (_fieldMessages.contains(failureMessageKey)) {
          return const SizedBox.shrink();
        }
        return Semantics(
          liveRegion: true,
          child: Row(
            key: const Key('qiyam_status'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.error_outline,
                  size: 16,
                  color: colors.errorText,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(copy.saveFailed, style: style(colors.errorText)),
              ),
            ],
          ),
        );
      case QiyamActionStatus.locked || QiyamActionStatus.nightChanged || null:
        return const SizedBox.shrink();
    }
  }
}
