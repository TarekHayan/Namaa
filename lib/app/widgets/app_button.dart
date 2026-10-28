import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }

enum AppButtonSize { small, medium, large }

/// The standard action button. Feature screens choose only intent and size.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.color,
    this.loading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final Color? color;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final effectiveColor =
        color ??
        (variant == AppButtonVariant.danger ? colors.error : colors.primary);
    final foreground = effectiveColor.computeLuminance() > 0.22
        ? const Color(0xFF062016)
        : Colors.white;
    final buttonStyle = ButtonStyle(
      animationDuration: const Duration(milliseconds: 180),
      minimumSize: WidgetStatePropertyAll(Size(0, _height)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: _horizontalPadding),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize:
              _fontSize *
              AppTypography.scaleForWidth(MediaQuery.sizeOf(context).width),
          fontWeight: FontWeight.w800,
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        final highlighted =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return switch (variant) {
          AppButtonVariant.primary || AppButtonVariant.danger =>
            highlighted
                ? Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.14),
                    effectiveColor,
                  )
                : effectiveColor,
          AppButtonVariant.secondary =>
            highlighted
                ? effectiveColor.withValues(alpha: 0.2)
                : colors.accentSoft,
          AppButtonVariant.outline || AppButtonVariant.text =>
            highlighted ? effectiveColor.withValues(alpha: 0.1) : null,
        };
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        return switch (variant) {
          AppButtonVariant.primary || AppButtonVariant.danger => foreground,
          _ => effectiveColor,
        };
      }),
      overlayColor: WidgetStatePropertyAll(
        effectiveColor.withValues(alpha: 0.08),
      ),
      shadowColor: WidgetStatePropertyAll(
        effectiveColor.withValues(alpha: 0.45),
      ),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return 0;
        return states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)
            ? 6
            : 0;
      }),
      side: variant == AppButtonVariant.outline
          ? WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color:
                    states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)
                    ? effectiveColor.withValues(alpha: 0.7)
                    : colors.border,
              ),
            )
          : null,
    );
    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color:
                  variant == AppButtonVariant.primary ||
                      variant == AppButtonVariant.danger
                  ? foreground
                  : effectiveColor,
            ),
          )
        : ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.max(120, MediaQuery.sizeOf(context).width - 80),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: _iconSize),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
    final enabled = loading ? null : onPressed;
    final button = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.danger => FilledButton(
        onPressed: enabled,
        style: buttonStyle,
        child: child,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: enabled,
        style: buttonStyle,
        child: child,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: enabled,
        style: buttonStyle,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: enabled,
        style: buttonStyle,
        child: child,
      ),
    };
    return Semantics(
      label: label,
      button: true,
      child: expanded
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }

  double get _height => switch (size) {
    AppButtonSize.small => 36,
    AppButtonSize.medium => 44,
    AppButtonSize.large => 52,
  };
  double get _horizontalPadding => switch (size) {
    AppButtonSize.small => 12,
    AppButtonSize.medium => 18,
    AppButtonSize.large => 24,
  };
  double get _fontSize => switch (size) {
    AppButtonSize.small => 12,
    AppButtonSize.medium => 14,
    AppButtonSize.large => 16,
  };
  double get _iconSize => switch (size) {
    AppButtonSize.small => 16,
    AppButtonSize.medium => 18,
    AppButtonSize.large => 20,
  };
}
