import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_button.dart';

import '../../domain/prayer_name.dart';
import '../../domain/prayer_status.dart';
import '../prayer_state.dart';

class PrayerStatusActions extends StatelessWidget {
  const PrayerStatusActions({
    super.key,
    required this.name,
    required this.status,
    required this.phase,
    required this.onChanged,
  });

  final PrayerName name;
  final PrayerStatus status;
  final PrayerActionPhase phase;
  final ValueChanged<PrayerStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final saving = phase == PrayerActionPhase.saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _choice(
              context,
              PrayerStatus.completedOnTime,
              copy.prayerStatusOnTime,
              Icons.check_circle_outline,
              saving,
            ),
            _choice(
              context,
              PrayerStatus.completedLate,
              copy.prayerStatusLate,
              Icons.schedule_outlined,
              saving,
            ),
            _choice(
              context,
              PrayerStatus.missed,
              copy.prayerStatusMissed,
              Icons.remove_circle_outline,
              saving,
            ),
            if (status != PrayerStatus.pending)
              _choice(
                context,
                PrayerStatus.pending,
                copy.prayerStatusReset,
                Icons.restart_alt,
                saving,
              ),
          ],
        ),
        if (phase != PrayerActionPhase.idle) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: phase == PrayerActionPhase.failed,
            child: Text(
              switch (phase) {
                PrayerActionPhase.saving => copy.prayerStatusSaving,
                PrayerActionPhase.saved => copy.prayerStatusSaved,
                PrayerActionPhase.failed => copy.prayerStatusSaveFailed,
                PrayerActionPhase.idle => '',
              },
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: phase == PrayerActionPhase.failed
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _choice(
    BuildContext context,
    PrayerStatus value,
    String label,
    IconData icon,
    bool saving,
  ) {
    final selected = status == value;
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final semanticLabel = selected
        ? FoundationLocalizations.of(context).prayerStatusSelected(label)
        : label;
    return AppButton(
      key: Key('prayer_status_${name.wireName}_${value.wireName}'),
      label: label,
      semanticLabel: semanticLabel,
      selected: selected,
      icon: selected ? Icons.check_rounded : icon,
      size: AppButtonSize.large,
      wrapLabel: true,
      showDisabledColor: selected && !saving,
      color: switch (value) {
        PrayerStatus.completedOnTime => colors.success,
        PrayerStatus.completedLate => colors.warning,
        PrayerStatus.missed => colors.error,
        PrayerStatus.pending => colors.primary,
      },
      variant: selected ? AppButtonVariant.primary : AppButtonVariant.outline,
      loading: saving && selected,
      onPressed: saving || selected ? null : () => onChanged(value),
    );
  }
}
