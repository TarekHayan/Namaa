import 'package:flutter/widgets.dart';

/// Layout breakpoints and widths shared by every screen. A redesign changes
/// them here, once.
abstract final class AppLayout {
  /// The width from which a screen uses its wide layout: forms open as
  /// dialogs instead of bottom sheets, and readers show keyboard hints.
  static const double wideBreakpoint = 720;

  /// The readable column width on wide windows.
  static const double columnMaxWidth = 720;

  /// Whether the window is wide enough for the wide layout.
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint;
}
