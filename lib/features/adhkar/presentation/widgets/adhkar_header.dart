import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';

import '../adhkar_state.dart';

/// The screen heading: title and subtitle, the Adhkar streak chip, and the
/// Morning/Evening switch (the prototype's first group). Without a schedule
/// an inline notice offers the Prayer location setup (FR-006a).
final class AdhkarHeader extends StatelessWidget {
  const AdhkarHeader({
    super.key,
    required this.copy,
    required this.streak,
    required this.selectedMorning,
    required this.scheduleState,
    required this.onTabChanged,
  });

  final AdhkarStrings copy;
  final int streak;
  final bool selectedMorning;
  final AdhkarScheduleState? scheduleState;
  final ValueChanged<AdhkarTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: const Key('adhkar_header'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              copy.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StreakChip(copy: copy, streak: streak),
                _Switch(
                  copy: copy,
                  selectedMorning: selectedMorning,
                  onTabChanged: onTabChanged,
                ),
              ],
            ),
            if (scheduleState == AdhkarScheduleState.setupRequired) ...[
              const SizedBox(height: 8),
              Text(
                copy.setupPrompt,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
            if (scheduleState == AdhkarScheduleState.unavailable) ...[
              const SizedBox(height: 8),
              Text(
                copy.countingLocked,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.copy, required this.streak});

  final AdhkarStrings copy;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('adhkar_streak_chip'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        copy.streak(streak),
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: colors.primary),
      ),
    );
  }
}

final class _Switch extends StatelessWidget {
  const _Switch({
    required this.copy,
    required this.selectedMorning,
    required this.onTabChanged,
  });

  final AdhkarStrings copy;
  final bool selectedMorning;
  final ValueChanged<AdhkarTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment(
          value: true,
          icon: const Icon(Icons.wb_sunny_outlined, size: 16),
          label: Text(
            copy.tabLabel(true),
            key: const Key('adhkar_switch_morning'),
          ),
        ),
        ButtonSegment(
          value: false,
          icon: const Icon(Icons.dark_mode_outlined, size: 16),
          label: Text(
            copy.tabLabel(false),
            key: const Key('adhkar_switch_evening'),
          ),
        ),
      ],
      selected: {selectedMorning},
      onSelectionChanged: (selection) =>
          onTabChanged(selection.first ? AdhkarTab.morning : AdhkarTab.evening),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        side: WidgetStatePropertyAll(BorderSide(color: colors.outlineVariant)),
      ),
    );
  }
}
