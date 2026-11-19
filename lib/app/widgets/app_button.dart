import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }

enum AppButtonSize { small, medium, large }

/// The visual family of an [AppButton].
enum AppButtonLook {
  /// The original look: the tokens' primary color, bold labels and the
  /// animated hover glow. Existing screens use it.
  classic,

  /// The approved 2026-11 design: a stronger accent fill with a soft glow,
  /// quiet buttons on the secondary surface, rounded 14-20 px corners and
  /// 48-58 px heights. Sizes map to small 48, medium 52 and large 58 px.
  /// Labels always wrap. Adhkar uses it; other screens adopt it when they are
  /// redesigned.
  refined,
}

/// One-off adjustments of a refined [AppButton] for a design detail that its
/// size does not cover. Prefer the size's defaults; every use is an exception
/// to the design system.
@immutable
class AppButtonTuning {
  const AppButtonTuning({
    this.radius,
    this.minHeight,
    this.padding,
    this.fontWeight,
    this.labelHeight,
  });

  /// The corner radius, instead of the size's.
  final double? radius;

  /// The minimum height, instead of the size's.
  final double? minHeight;

  /// The padding, instead of the size's horizontal 20-24 and vertical 6.
  final EdgeInsetsGeometry? padding;

  /// The label weight, instead of the variant's.
  final FontWeight? fontWeight;

  /// The label line height, instead of the font's own.
  final double? labelHeight;
}

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
    this.wrapLabel = false,
    this.showDisabledColor = false,
    this.semanticLabel,
    this.selected,
    this.look = AppButtonLook.classic,
    this.trailingIcon,
    this.fill,
    this.tuning,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final Color? color;
  final bool loading;
  final bool expanded;
  final bool wrapLabel;
  final bool showDisabledColor;
  final String? semanticLabel;
  final bool? selected;

  /// The visual family; [AppButtonLook.classic] keeps the original look.
  final AppButtonLook look;

  /// Refined look: an icon after the label (a "continue" arrow).
  final IconData? trailingIcon;

  /// Refined look: the fill of a secondary or outline button, instead of the
  /// default secondary or page surface.
  final Color? fill;

  /// Refined look: one-off adjustments of the size's metrics.
  final AppButtonTuning? tuning;

  @override
  Widget build(BuildContext context) {
    if (look == AppButtonLook.refined) return _buildRefined(context);
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
        if (states.contains(WidgetState.disabled)) {
          return showDisabledColor ? effectiveColor : null;
        }
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
        if (states.contains(WidgetState.disabled)) {
          return showDisabledColor ? foreground : null;
        }
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
                    maxLines: wrapLabel ? null : 1,
                    overflow: wrapLabel
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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
      label: semanticLabel ?? label,
      button: true,
      selected: selected,
      child: expanded
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }

  /// The refined look: every variant is a filled button whose colors,
  /// outline and glow come from the theme tokens.
  Widget _buildRefined(BuildContext context) {
    assert(!loading, 'the refined look has no loading state');
    final colors = AppColors.of(context);
    final (height, corner, pad, iconSize, iconGap) = switch (size) {
      AppButtonSize.small => (48.0, 14.0, 20.0, 20.0, 8.0),
      AppButtonSize.medium => (52.0, 16.0, 20.0, 20.0, 8.0),
      AppButtonSize.large => (58.0, 20.0, 24.0, 22.0, 10.0),
    };
    final cornerRadius = tuning?.radius ?? corner;
    final enabled = onPressed != null;
    final Color background;
    final Color foreground;
    final Color? outline;
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        final danger = variant == AppButtonVariant.danger;
        background = enabled
            ? (color ?? (danger ? colors.error : colors.accentStrong))
            : colors.surfaceSecondary;
        foreground = enabled
            ? (danger ? colors.onError : colors.onAccentStrong)
            : colors.textSecondary;
        outline = enabled || danger ? null : colors.border;
      case AppButtonVariant.secondary:
        background = fill ?? colors.surfaceSecondary;
        foreground = colors.textPrimary;
        outline = colors.border;
      case AppButtonVariant.outline:
        background = fill ?? colors.surface;
        foreground = colors.textPrimary;
        outline = color ?? colors.border;
      case AppButtonVariant.text:
        background = Colors.transparent;
        foreground = colors.accentStrong;
        outline = null;
    }
    final font = DefaultTextStyle.of(context).style;
    final weight =
        tuning?.fontWeight ??
        (variant == AppButtonVariant.secondary
            ? FontWeight.w600
            : FontWeight.w700);
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, tuning?.minHeight ?? height)),
      padding: WidgetStatePropertyAll(
        tuning?.padding ?? EdgeInsets.symmetric(horizontal: pad, vertical: 6),
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStatePropertyAll(background),
      foregroundColor: WidgetStatePropertyAll(foreground),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          side: outline == null ? BorderSide.none : BorderSide(color: outline),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          // A button label does not inherit the theme font by itself, so
          // carry it through from the surrounding text style.
          fontFamily: font.fontFamily,
          fontFamilyFallback: font.fontFamilyFallback,
          fontSize: 16,
          fontWeight: weight,
          height: tuning?.labelHeight,
        ),
      ),
    );
    final Widget button;
    if (trailingIcon != null) {
      button = FilledButton(
        onPressed: onPressed,
        style: style,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(label, textAlign: TextAlign.center)),
            SizedBox(width: iconGap),
            Icon(trailingIcon, size: iconSize),
          ],
        ),
      );
    } else if (icon != null) {
      button = FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: iconSize),
        label: Text(label),
      );
    } else {
      button = FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(label, textAlign: TextAlign.center),
      );
    }
    final glowing = variant == AppButtonVariant.primary && enabled;
    final Widget decorated = glowing
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              boxShadow: colors.buttonShadow,
            ),
            child: button,
          )
        : button;
    final Widget sized = expanded
        ? SizedBox(width: double.infinity, child: decorated)
        : decorated;
    // The button already exposes its own label; wrap it only to replace the
    // label or mark it selected, so assistive technology reads one node.
    if (semanticLabel == null && selected == null) return sized;
    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      enabled: enabled,
      selected: selected,
      excludeSemantics: true,
      onTap: onPressed,
      child: sized,
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
