import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:namma_project/app/theme/app_colors.dart';

/// The Arabic display font for dhikr text (registered in pubspec.yaml).
const String kDhikrFontFamily = 'Amiri';

/// The Quran font for verse text: KFGQPC Uthmanic Hafs, bundled unmodified
/// through the Quran Foundation so the Uthmani script and the QPC Hafs
/// encoding render correctly (FR-019). Verse-end markers are part of the
/// catalog text and are drawn by this font, never by the screen.
const String kQuranFontFamily = 'KFGQPC HAFS';

/// The width from which the Adhkar section uses its wide layout: the reader
/// shows previous/next buttons and keyboard hints, and the My Adhkar forms
/// open as dialogs.
const double kAdhkarWideBreakpoint = 720;

/// The readable column width on wide windows.
const double kAdhkarColumnMaxWidth = 720;

/// The Adhkar section colors from the approved design (2026-11-17). They are
/// the Emerald [AppColors] light and dark tokens, picked by the theme's
/// brightness; the few names that differ from the app tokens (the accent text
/// and the filled-button color) are the design's own.
@immutable
final class AdhkarPalette {
  const AdhkarPalette._({
    required this.dark,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.text2,
    required this.border,
    required this.primary,
    required this.accent,
    required this.soft,
    required this.track,
    required this.button,
    required this.onButton,
    required this.warn,
    required this.warnSoft,
    required this.error,
    required this.errorText,
    required this.errorSoft,
    required this.onError,
    required this.scrim,
  });

  factory AdhkarPalette.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  // The shared tokens come from AppColors; only the design's own values (the
  // ring track, the error text and soft fills, the scrim) are written here.
  static final AdhkarPalette _light = AdhkarPalette._fromTokens(
    AppColors.light,
    dark: false,
    accent: AppColors.light.secondary,
    onButton: const Color(0xFFFFFFFF),
    track: const Color(0x29059669),
    warnSoft: const Color(0x1FD97706),
    errorText: const Color(0xFFB91C1C),
    errorSoft: const Color(0x14DC2626),
    onError: const Color(0xFFFFFFFF),
    scrim: const Color(0x6B0D1410),
  );

  static final AdhkarPalette _dark = AdhkarPalette._fromTokens(
    AppColors.dark,
    dark: true,
    accent: AppColors.dark.primary,
    onButton: const Color(0xFF050805),
    track: const Color(0x3310B981),
    warnSoft: const Color(0x24F59E0B),
    errorText: const Color(0xFFF87171),
    errorSoft: const Color(0x24EF4444),
    onError: const Color(0xFF050805),
    scrim: const Color(0xA8000000),
  );

  factory AdhkarPalette._fromTokens(
    AppColors tokens, {
    required bool dark,
    required Color accent,
    required Color onButton,
    required Color track,
    required Color warnSoft,
    required Color errorText,
    required Color errorSoft,
    required Color onError,
    required Color scrim,
  }) => AdhkarPalette._(
    dark: dark,
    bg: tokens.background,
    surface: tokens.surface,
    surface2: tokens.surfaceSecondary,
    text: tokens.textPrimary,
    text2: tokens.textSecondary,
    border: tokens.border,
    primary: tokens.primary,
    accent: accent,
    soft: tokens.accentSoft,
    track: track,
    button: accent,
    onButton: onButton,
    warn: tokens.warning,
    warnSoft: warnSoft,
    error: tokens.error,
    errorText: errorText,
    errorSoft: errorSoft,
    onError: onError,
    scrim: scrim,
  );

  /// Whether this is the dark palette.
  final bool dark;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color text;
  final Color text2;
  final Color border;

  /// The ring and fill color.
  final Color primary;

  /// The accent used for text and icons (deeper than [primary] in light).
  final Color accent;
  final Color soft;

  /// The unfilled part of a ring.
  final Color track;

  /// The filled primary button color, and the color of text on it.
  final Color button;
  final Color onButton;
  final Color warn;
  final Color warnSoft;
  final Color error;
  final Color errorText;
  final Color errorSoft;
  final Color onError;
  final Color scrim;

  /// The soft card glow.
  List<BoxShadow> get glow => dark
      ? const [
          BoxShadow(color: Color(0x2410B981), spreadRadius: 1),
          BoxShadow(color: Color(0x2410B981), blurRadius: 22),
        ]
      : const [
          BoxShadow(
            color: Color(0x1F059669),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ];

  /// The glow under a filled primary button.
  List<BoxShadow> get buttonGlow => dark
      ? const [BoxShadow(color: Color(0x6B10B981), blurRadius: 30)]
      : const [
          BoxShadow(
            color: Color(0x57059669),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ];

  /// A card surface: the fill, a hairline border and the given corner radius.
  BoxDecoration card({
    double radius = 24,
    Color? color,
    Color? borderColor,
    List<BoxShadow>? shadows,
  }) => BoxDecoration(
    color: color ?? surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? border),
    boxShadow: shadows,
  );
}

/// A text style of the design: only the size, weight, color and line height;
/// the font family comes from the theme (Thmanyah Sans), and the user's text
/// scale applies through the ambient `MediaQuery`.
TextStyle adhkarText(
  double size,
  FontWeight weight,
  Color color, {
  double height = 1.5,
}) =>
    TextStyle(fontSize: size, fontWeight: weight, color: color, height: height);

/// A circular ring: a full track circle and a primary arc from the top,
/// clockwise, covering [progress] (0 to 1), drawn with a stroke of
/// [strokeWidth] inside the painter's box.
final class AdhkarRingPainter extends CustomPainter {
  const AdhkarRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.fill,
    required this.track,
  });

  final double progress;
  final double strokeWidth;
  final Color fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base);
    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = fill;
    if (clamped >= 1) {
      canvas.drawArc(arcRect, 0, math.pi * 2, false, arc);
    } else {
      canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * clamped, false, arc);
    }
  }

  @override
  bool shouldRepaint(AdhkarRingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.fill != fill ||
      old.track != track;
}
