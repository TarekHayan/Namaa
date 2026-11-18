import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'app_ink_surface.dart';

/// One choice of an [AppSegmentedControl]. The [label] is translated by the
/// caller; the [key] goes on the segment so tests can find it.
class AppSegment {
  const AppSegment({required this.label, this.key});

  final String label;
  final Key? key;
}

/// A row of equal choices in a rounded tray, one selected: the page-level tab
/// switch. The selected segment gets the surface fill and an accent outline.
class AppSegmentedControl extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<AppSegment> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => AppCard(
    tone: AppCardTone.secondary,
    radius: 20,
    padding: const EdgeInsets.all(4),
    child: Row(
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _Segment(
            key: segments[i].key,
            label: segments[i].label,
            selected: i == selectedIndex,
            onTap: () => onChanged(i),
          ),
        ],
      ],
    ),
  );
}

final class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        excludeSemantics: true,
        label: label,
        onTap: onTap,
        child: AppInkSurface(
          color: selected ? colors.surface : Colors.transparent,
          borderColor: selected ? colors.primary : Colors.transparent,
          minHeight: 48,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.fixed(
                15,
                selected ? FontWeight.w700 : FontWeight.w600,
                selected ? colors.accentStrong : colors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
