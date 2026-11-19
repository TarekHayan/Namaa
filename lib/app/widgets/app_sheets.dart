import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../theme/app_typography.dart';

/// Opens a modal bottom sheet with the app's scrim and a transparent route
/// background: the content draws its own [AppSheetPanel].
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useSafeArea = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: useSafeArea,
  backgroundColor: Colors.transparent,
  barrierColor: AppColors.of(context).scrim,
  builder: builder,
);

/// Opens a dialog with the app's scrim and a transparent route background:
/// the content draws its own surface (an [AppCard] or [AppSheetPanel]).
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 340,
  double inset = 24,
}) => showDialog<T>(
  context: context,
  barrierColor: AppColors.of(context).scrim,
  builder: (dialogContext) => Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: EdgeInsets.all(inset),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: builder(dialogContext),
    ),
  ),
);

/// Opens [builder] as a bottom sheet on phones and as a dialog from the wide
/// breakpoint ([AppLayout.wideBreakpoint]). The builder runs under the route's
/// own context, so it must not rely on the opener's providers: pass what it
/// needs explicitly. Build its content with [AppFormSheet].
Future<T?> showAppAdaptiveSheet<T>(
  BuildContext context,
  WidgetBuilder builder,
) => AppLayout.isWide(context)
    ? showAppDialog<T>(
        context: context,
        builder: builder,
        maxWidth: 520,
        inset: 40,
      )
    : showAppBottomSheet<T>(
        context: context,
        builder: builder,
        useSafeArea: true,
      );

/// The drag handle of a bottom sheet.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: AppColors.of(context).border,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

/// The surface of a sheet: the page color, a hairline border, the soft glow
/// and 28 px corners (top corners only unless [fullyRounded], as in a dialog).
class AppSheetPanel extends StatelessWidget {
  const AppSheetPanel({
    super.key,
    required this.child,
    this.fullyRounded = false,
    this.height,
  });

  final Widget child;
  final bool fullyRounded;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: fullyRounded
            ? BorderRadius.circular(28)
            : const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: child,
    );
  }
}

/// The content of an adaptive form sheet: a drag handle on phones, the
/// [title], a scrolling body of [fields] spaced 18 px apart, and a [footer]
/// under a hairline (the action buttons). It lifts above the keyboard.
/// [panelKey] goes on the panel so tests can find it.
class AppFormSheet extends StatelessWidget {
  const AppFormSheet({
    super.key,
    required this.panelKey,
    required this.title,
    required this.fields,
    required this.footer,
  });

  final Key panelKey;
  final String title;
  final List<Widget> fields;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final phone = !AppLayout.isWide(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheetPanel(
        key: panelKey,
        fullyRounded: !phone,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (phone)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Center(child: AppSheetHandle()),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: Text(
                title,
                style: AppTypography.fixed(
                  20,
                  FontWeight.w700,
                  colors.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      if (i > 0) const SizedBox(height: 18),
                      fields[i],
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: footer,
            ),
          ],
        ),
      ),
    );
  }
}
