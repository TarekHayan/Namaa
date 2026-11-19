import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A row with a label and an on/off switch, at least 48 px tall: the label
/// starts the row and the switch ends it. The switch takes its colors from the
/// theme tokens. Callers pass the translated [label]; [switchKey] goes on the
/// switch so tests can find it.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.switchKey,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.fixed(
                  16,
                  FontWeight.w600,
                  colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Theme(
              data: theme.copyWith(
                switchTheme: SwitchThemeData(
                  trackColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? colors.accentStrong
                        : colors.surfaceSecondary,
                  ),
                  trackOutlineColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Colors.transparent
                        : colors.border,
                  ),
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? colors.onAccentStrong
                        : colors.textSecondary,
                  ),
                ),
              ),
              child: Switch(key: switchKey, value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}
