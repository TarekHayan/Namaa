import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A circular progress ring: a full track circle and a primary arc from the
/// top, clockwise, covering [progress] (0 to 1). The colors come from the
/// theme tokens. Give it a [size], or put it in a box and let it fill that box;
/// an optional [child] is laid out inside it.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.progress,
    required this.strokeWidth,
    this.size,
    this.child,
  });

  final double progress;

  /// The stroke, drawn inside the ring's box.
  final double strokeWidth;
  final double? size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return CustomPaint(
      size: size == null ? Size.zero : Size.square(size!),
      painter: _RingPainter(
        progress: progress,
        strokeWidth: strokeWidth,
        fill: colors.primary,
        track: colors.track,
      ),
      child: child,
    );
  }
}

final class _RingPainter extends CustomPainter {
  const _RingPainter({
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
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.fill != fill ||
      old.track != track;
}
