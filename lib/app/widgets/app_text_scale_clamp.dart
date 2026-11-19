import 'package:flutter/widgets.dart';

/// Caps the user's text scale for [child] at [max], so banners and chips wrap
/// instead of growing past their space at very large text sizes. Smaller
/// scales pass through unchanged.
class AppTextScaleClamp extends StatelessWidget {
  const AppTextScaleClamp({super.key, required this.max, required this.child});

  final double max;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: max),
    ),
    child: child,
  );
}
