import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_state.dart';

/// The tracker card (the prototype's second group): "Did you pray Qiyam
/// tonight?", the best-time note and the Yes/No buttons. Yes opens the
/// details form — the rak'ah chips (default 4), the start and end times, the
/// Witr checkbox (default on) and the note field with its 500 counter. The
/// tracker is read-only while the schedule is unavailable, and the per-
/// command feedback shows under the form.
final class QiyamTrackerCard extends StatelessWidget {
  const QiyamTrackerCard({
    super.key,
    required this.copy,
    required this.night,
    required this.record,
    required this.form,
    required this.status,
    required this.failureMessageKey,
    required this.onYes,
    required this.onNo,
    required this.onRakahs,
    required this.onWitr,
    required this.onTimes,
    required this.onNote,
  });

  final QiyamStrings copy;
  final QiyamNightState? night;
  final QiyamNightRecord? record;
  final QiyamForm? form;
  final QiyamActionStatus? status;
  final String? failureMessageKey;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final ValueChanged<int> onRakahs;
  final VoidCallback onWitr;
  final void Function(String? startTime, String? endTime) onTimes;
  final ValueChanged<String> onNote;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locked = night?.editable != true;
    final form = this.form;
    return Card(
      key: const Key('qiyam_tracker_card'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              copy.didYouPray,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              copy.bestTime,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const Key('qiyam_yes'),
                  onPressed: locked ? null : onYes,
                  child: Text(copy.yesXp),
                ),
                FilledButton.tonal(
                  key: const Key('qiyam_no'),
                  onPressed: locked ? null : onNo,
                  child: Text(copy.no),
                ),
              ],
            ),
            if (locked) ...[
              const SizedBox(height: 12),
              Text(
                copy.recordingLocked,
                key: const Key('qiyam_locked_notice'),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
            if (form != null && form.performed) ...[
              const SizedBox(height: 20),
              Text(
                copy.rakahsLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  for (final rakahs in QiyamNightDraft.allowedRakahs)
                    ChoiceChip(
                      key: Key('qiyam_rakah_chip_$rakahs'),
                      label: Text(copy.rakahsCount(rakahs)),
                      selected: form.rakahs == rakahs,
                      onSelected: (_) => onRakahs(rakahs),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('qiyam_start_time'),
                      initialValue: form.startTime ?? '',
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: InputDecoration(
                        labelText: copy.startTime,
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                      onChanged: (value) => onTimes(value, form.endTime),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('qiyam_end_time'),
                      initialValue: form.endTime ?? '',
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: InputDecoration(
                        labelText: copy.endTime,
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                      onChanged: (value) => onTimes(form.startTime, value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    key: const Key('qiyam_witr'),
                    value: form.witr,
                    onChanged: (_) => onWitr(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: Text(copy.witr)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('qiyam_note'),
                initialValue: form.note ?? '',
                maxLength: 500,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: copy.notesLabel,
                  hintText: copy.notesPlaceholder,
                  border: const OutlineInputBorder(),
                  counter: _NoteCounter(
                    copy: copy,
                    length: form.note?.length ?? 0,
                  ),
                ),
                onChanged: onNote,
              ),
            ],
            if (form != null && !form.performed) ...[
              const SizedBox(height: 12),
              Text(
                copy.readOnly,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
            if (status != null) ...[
              const SizedBox(height: 12),
              Text(
                _statusCopy(),
                key: const Key('qiyam_status'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: status == QiyamActionStatus.failed
                      ? colors.error
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusCopy() => switch (status) {
    QiyamActionStatus.pending => copy.saving,
    QiyamActionStatus.saved => copy.saved,
    QiyamActionStatus.failed => copy.failure(failureMessageKey ?? ''),
    QiyamActionStatus.locked => copy.recordingLocked,
    QiyamActionStatus.nightChanged => copy.nightChanged,
    null => '',
  };
}

final class _NoteCounter extends StatelessWidget {
  const _NoteCounter({required this.copy, required this.length});

  final QiyamStrings copy;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Text(
      copy.noteCounter(length),
      key: const Key('qiyam_note_counter'),
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: Theme.of(context).disabledColor),
    );
  }
}
