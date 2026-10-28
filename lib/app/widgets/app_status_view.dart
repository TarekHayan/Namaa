import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

enum AppStatusKind { loading, error, success }

/// Standard full-area loading, error and success feedback.
class AppStatusView extends StatelessWidget {
  const AppStatusView.loading({super.key, this.message})
    : kind = AppStatusKind.loading,
      title = null,
      actionLabel = null,
      onAction = null;

  const AppStatusView.error({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : kind = AppStatusKind.error;

  const AppStatusView.success({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : kind = AppStatusKind.success;

  final AppStatusKind kind;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final statusColor = switch (kind) {
      AppStatusKind.loading => colors.primary,
      AppStatusKind.error => colors.error,
      AppStatusKind.success => colors.success,
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: kind != AppStatusKind.loading,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (kind == AppStatusKind.loading)
                  CircularProgressIndicator(
                    color: statusColor,
                    semanticsLabel: message,
                  )
                else
                  Icon(
                    kind == AppStatusKind.error
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 44,
                    color: statusColor,
                  ),
                if (title != null) ...[
                  const SizedBox(height: 16),
                  AppText(
                    title!,
                    role: AppTextRole.title,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (message != null && kind != AppStatusKind.loading) ...[
                  const SizedBox(height: 8),
                  AppText(
                    message!,
                    color: colors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (message != null && kind == AppStatusKind.loading) ...[
                  const SizedBox(height: 16),
                  AppText(message!, textAlign: TextAlign.center),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 24),
                  AppButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    variant: kind == AppStatusKind.error
                        ? AppButtonVariant.outline
                        : AppButtonVariant.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
