import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The color family of an [AppPill].
enum AppPillTone {
  /// Soft accent fill, accent text (a count or a tag).
  accent,

  /// Surface fill with a hairline border, main text (an inactive tag).
  neutral,

  /// Solid accent fill, text on accent (an active tag).
  filled,

  /// Soft error fill with an error border, main text (a deleted mark).
  error,
}

/// A small rounded label with an optional leading icon. Callers pass the
/// translated text.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.tone = AppPillTone.accent,
    this.fontSize = 15,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    this.minHeight,
    this.hairline = false,
    this.icon,
    this.maxLines,
    this.labelKey,
  });

  final String label;
  final AppPillTone tone;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double? minHeight;

  /// Adds a hairline border to an accent pill.
  final bool hairline;

  /// A leading icon, drawn in the tone's accent.
  final IconData? icon;
  final int? maxLines;

  /// The key of the label's `Text`.
  final Key? labelKey;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (fill, outline, text, glyph) = switch (tone) {
      AppPillTone.accent => (
        colors.accentSoft,
        hairline ? colors.border : null,
        colors.accentStrong,
        colors.accentStrong,
      ),
      AppPillTone.neutral => (
        colors.surface,
        colors.border,
        colors.textPrimary,
        colors.textPrimary,
      ),
      AppPillTone.filled => (
        colors.accentStrong,
        null,
        colors.onAccentStrong,
        colors.onAccentStrong,
      ),
      AppPillTone.error => (
        colors.errorSoft,
        colors.error,
        colors.textPrimary,
        colors.error,
      ),
    };
    final style = AppTypography.fixed(fontSize, FontWeight.w700, text);
    final Widget content = icon == null
        ? Text(label, key: labelKey, maxLines: maxLines, style: style)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: glyph),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label, key: labelKey, style: style),
              ),
            ],
          );
    return Container(
      constraints: minHeight == null
          ? null
          : BoxConstraints(minHeight: minHeight!),
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: outline == null ? null : Border.all(color: outline),
      ),
      // With a minimum height the label stays centered and the pill still
      // hugs its content.
      child: minHeight == null
          ? content
          : Center(widthFactor: 1, child: content),
    );
  }
}
