import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../../domain/prayer_name.dart';
import '../../domain/prayer_status.dart';
import '../prayer_state.dart';

/// Prototype actions: "on time" and "late" with labels, "missed" as an icon
/// button. Reset-to-pending is Namaa's accessible addition (adaptation 4)
/// and appears only once a state is recorded.
class PrayerStatusActions extends StatelessWidget {
  const PrayerStatusActions({
    super.key,
    required this.name,
    required this.status,
    required this.phase,
    required this.onChanged,
    this.fillWidth = false,
  });

  final PrayerName name;
  final PrayerStatus status;
  final PrayerActionPhase phase;
  final ValueChanged<PrayerStatus> onChanged;

  /// Phone layout: keep every control on one row, with the two labelled
  /// actions sharing the width, so reset never drops onto a line of its own.
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final saving = phase == PrayerActionPhase.saving;
    PrayerStatusButton button(
      PrayerStatus value,
      String label,
      IconData icon,
      Color accent, {
      bool iconOnly = false,
    }) => PrayerStatusButton(
      key: Key('prayer_status_${name.wireName}_${value.wireName}'),
      label: label,
      icon: icon,
      accent: accent,
      iconOnly: iconOnly,
      selected: status == value,
      loading: saving && status == value,
      onPressed: saving || status == value ? null : () => onChanged(value),
    );
    final onTime = button(
      PrayerStatus.completedOnTime,
      copy.prayerStatusOnTime,
      Icons.check_circle_outline_rounded,
      colors.success,
    );
    final late = button(
      PrayerStatus.completedLate,
      copy.prayerStatusLate,
      Icons.error_outline_rounded,
      colors.warning,
    );
    final missed = button(
      PrayerStatus.missed,
      copy.prayerStatusMissed,
      Icons.cancel_outlined,
      colors.error,
      iconOnly: true,
    );
    final reset = status == PrayerStatus.pending
        ? null
        : button(
            PrayerStatus.pending,
            copy.prayerStatusReset,
            Icons.restart_alt_rounded,
            colors.primary,
            iconOnly: true,
          );
    // Large text cannot share one row; it falls back to wrapping.
    final oneRow =
        fillWidth && MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final controls = oneRow
        ? Row(
            children: [
              Expanded(child: onTime),
              const SizedBox(width: 6),
              Expanded(child: late),
              const SizedBox(width: 6),
              missed,
              if (reset != null) ...[const SizedBox(width: 6), reset],
            ],
          )
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [onTime, late, missed, ?reset],
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        controls,
        if (phase != PrayerActionPhase.idle) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: phase == PrayerActionPhase.failed,
            child: Text(
              switch (phase) {
                PrayerActionPhase.saving => copy.prayerStatusSaving,
                PrayerActionPhase.saved => copy.prayerStatusSaved,
                PrayerActionPhase.failed => copy.prayerStatusSaveFailed,
                PrayerActionPhase.idle => '',
              },
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: phase == PrayerActionPhase.failed
                    ? colors.error
                    : colors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One rounded prototype status control. Selected: filled with its accent.
/// Otherwise: the secondary surface with an accent hover tint.
class PrayerStatusButton extends StatelessWidget {
  const PrayerStatusButton({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onPressed,
    this.iconOnly = false,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final bool iconOnly;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    // The selected state is named, not only coloured.
    final semanticLabel = selected ? copy.prayerStatusSelected(label) : label;
    final onAccent = accent.computeLuminance() > 0.22
        ? const Color(0xFF0A0A0A)
        : Colors.white;
    final foreground = selected
        ? onAccent
        : iconOnly
        ? colors.textMuted
        : colors.textPrimary;
    final glyph = loading
        ? SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Icon(
            icon,
            size: iconOnly ? 18 : 15,
            semanticLabel: iconOnly ? semanticLabel : null,
          );
    final style = ButtonStyle(
      // Accessible target; the prototype's controls are smaller.
      minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
      padding: WidgetStatePropertyAll(
        iconOnly
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.labelMedium,
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (selected) return accent;
        final hot =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return hot
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.10),
                colors.surfaceSecondary,
              )
            : colors.surfaceSecondary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (selected) return onAccent;
        if (iconOnly &&
            (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused))) {
          return accent;
        }
        return foreground;
      }),
      overlayColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.08)),
      elevation: WidgetStatePropertyAll(selected ? 4 : 0),
      shadowColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.25)),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(color: accent, width: 1.5)
            : BorderSide.none,
      ),
    );
    final control = iconOnly
        ? TextButton(onPressed: onPressed, style: style, child: glyph)
        : TextButton.icon(
            onPressed: onPressed,
            style: style,
            icon: glyph,
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, semanticsLabel: semanticLabel, maxLines: 1),
            ),
          );
    return Semantics(
      selected: selected,
      child: iconOnly
          ? Tooltip(message: label, excludeFromSemantics: true, child: control)
          : control,
    );
  }
}
