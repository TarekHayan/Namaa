import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A short confirmation toast: a pill in the main text color on the page
/// background color, shown for about two seconds above the bottom edge.
///
/// Capture the toast with [AppToast.of] before an `await`, then call [show]
/// after it, so no `BuildContext` is used across the gap. The caller passes
/// the translated message.
final class AppToast {
  const AppToast._(this._messenger, this._colors);

  /// Reads the nearest `ScaffoldMessenger` and the active tokens now.
  factory AppToast.of(BuildContext context) =>
      AppToast._(ScaffoldMessenger.maybeOf(context), AppColors.of(context));

  final ScaffoldMessengerState? _messenger;
  final AppColors _colors;

  /// Replaces any toast on screen with one showing [message]. [key] goes on
  /// the snack bar so tests can find it.
  void show(String message, {Key? key}) {
    final messenger = _messenger;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: key,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          duration: const Duration(seconds: 2),
          content: Center(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _colors.textPrimary,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: _colors.background,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message,
                      style: AppTypography.fixed(
                        16,
                        FontWeight.w700,
                        _colors.background,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
