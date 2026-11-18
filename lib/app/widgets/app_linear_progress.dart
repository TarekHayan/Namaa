import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A thin rounded progress bar: a hairline track and a primary fill that
/// grows from the start edge (the right in Arabic). [progress] is 0 to 1.
class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({
    super.key,
    required this.progress,
    this.margin,
    this.height = 4,
  });

  final double progress;
  final EdgeInsetsGeometry? margin;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: margin,
      height: height,
      decoration: BoxDecoration(
        color: colors.border,
        borderRadius: BorderRadius.circular(height),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}
