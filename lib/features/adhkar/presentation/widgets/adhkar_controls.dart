import 'package:flutter/material.dart';

import 'adhkar_style.dart';

/// The filled primary button style of the design: the accent fill, a 16 px
/// radius, and, when disabled, a readable muted label on the secondary
/// surface with a hairline border (disabled buttons keep readable text).
ButtonStyle adhkarPrimaryStyle(
  AdhkarPalette palette, {
  double minHeight = 52,
  double radius = 16,
}) => ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, minHeight)),
  padding: const WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 20, vertical: 6),
  ),
  elevation: const WidgetStatePropertyAll(0),
  shadowColor: const WidgetStatePropertyAll(Colors.transparent),
  surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
  backgroundColor: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.disabled)
        ? palette.surface2
        : palette.button,
  ),
  foregroundColor: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.disabled)
        ? palette.text2
        : palette.onButton,
  ),
  shape: WidgetStateProperty.resolveWith(
    (states) => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: states.contains(WidgetState.disabled)
          ? BorderSide(color: palette.border)
          : BorderSide.none,
    ),
  ),
  textStyle: const WidgetStatePropertyAll(
    TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  ),
);

/// The quiet button style (Cancel): the secondary surface with a hairline.
ButtonStyle adhkarSecondaryStyle(
  AdhkarPalette palette, {
  double minHeight = 52,
  double radius = 16,
  Color? background,
}) => ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, minHeight)),
  padding: const WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 20, vertical: 6),
  ),
  elevation: const WidgetStatePropertyAll(0),
  shadowColor: const WidgetStatePropertyAll(Colors.transparent),
  surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
  backgroundColor: WidgetStatePropertyAll(background ?? palette.surface2),
  foregroundColor: WidgetStatePropertyAll(palette.text),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: palette.border),
    ),
  ),
  textStyle: const WidgetStatePropertyAll(
    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  ),
);

/// The destructive button style (confirm a delete).
ButtonStyle adhkarDangerStyle(AdhkarPalette palette, {double radius = 14}) =>
    ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? palette.surface2
            : palette.error,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? palette.text2
            : palette.onError,
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );

/// Puts the filled button's glow behind [child] while it is enabled.
final class AdhkarGlow extends StatelessWidget {
  const AdhkarGlow({
    super.key,
    required this.enabled,
    required this.child,
    this.radius = 16,
  });

  final bool enabled;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: enabled ? AdhkarPalette.of(context).buttonGlow : null,
    ),
    child: child,
  );
}

/// A line of inline warning or error text with its leading icon, as the
/// design shows limits and field errors.
final class AdhkarNote extends StatelessWidget {
  const AdhkarNote({
    super.key,
    required this.text,
    this.color,
    this.iconColor,
    this.weight = FontWeight.w400,
  });

  final String text;
  final Color? color;
  final Color? iconColor;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            Icons.error_outline,
            size: 18,
            color: iconColor ?? palette.warn,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: adhkarText(14, weight, color ?? palette.text, height: 1.6),
          ),
        ),
      ],
    );
  }
}

/// The three-dot overflow menu button (48 px, rounded square) wrapped around
/// a [PopupMenuButton] with the design's menu surface.
final class AdhkarMenu<T> extends StatelessWidget {
  const AdhkarMenu({
    super.key,
    required this.tooltip,
    required this.onSelected,
    required this.items,
  });

  final String tooltip;
  final ValueChanged<T> onSelected;
  final List<AdhkarMenuEntry<T>> items;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return PopupMenuButton<T>(
      tooltip: tooltip,
      onSelected: onSelected,
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: palette.glow.last.color,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 210),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.border),
      ),
      itemBuilder: (_) => [
        for (final entry in items)
          PopupMenuItem<T>(
            value: entry.value,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  entry.icon,
                  size: 20,
                  color: entry.destructive ? palette.errorText : palette.text,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    entry.label,
                    style: adhkarText(
                      16,
                      FontWeight.w600,
                      entry.destructive ? palette.errorText : palette.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.more_vert, size: 22, color: palette.text),
      ),
    );
  }
}

/// One entry of an [AdhkarMenu].
final class AdhkarMenuEntry<T> {
  const AdhkarMenuEntry({
    required this.value,
    required this.label,
    required this.icon,
    this.destructive = false,
  });

  final T value;
  final String label;
  final IconData icon;
  final bool destructive;
}
