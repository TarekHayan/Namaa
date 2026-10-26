import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A subtle pointer highlight for desktop cards without changing their size.
/// Touch input never enters the hover state.
class AppHoverSurface extends StatefulWidget {
  const AppHoverSurface({
    super.key,
    required this.child,
    this.radius = 20,
    this.enabled = true,
    this.clickable = false,
  });

  final Widget child;
  final double radius;
  final bool enabled;
  final bool clickable;

  @override
  State<AppHoverSurface> createState() => _AppHoverSurfaceState();
}

class _AppHoverSurfaceState extends State<AppHoverSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final active = widget.enabled && _hovered;
    return MouseRegion(
      cursor: widget.clickable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: colors.cardGlow,
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: active
                ? colors.primary.withValues(alpha: 0.55)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
