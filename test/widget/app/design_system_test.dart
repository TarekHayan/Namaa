import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_theme.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_status_view.dart';

void main() {
  test('text roles scale with width and preserve light/dark identity', () {
    final narrow = AppTheme.forWidth(AppTheme.light, 320);
    final desktop = AppTheme.forWidth(AppTheme.light, 1440);
    expect(
      narrow.textTheme.bodyMedium!.fontSize,
      lessThan(desktop.textTheme.bodyMedium!.fontSize!),
    );
    expect(narrow.textTheme.bodyMedium!.fontFamily, kProjectFontFamily);
    expect(narrow.scaffoldBackgroundColor, AppColors.light.background);
    expect(narrow.appBarTheme.backgroundColor, AppColors.light.background);
    expect(
      AppTheme.dark.appBarTheme.foregroundColor,
      AppColors.dark.textPrimary,
    );
  });

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets('shared buttons and status feedback work in both themes', (
      tester,
    ) async {
      var presses = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Column(
              children: [
                AppButton(
                  key: const Key('primary'),
                  label: 'Save',
                  icon: Icons.save_outlined,
                  onPressed: () => presses++,
                ),
                const AppButton(
                  key: Key('busy'),
                  label: 'Saving',
                  onPressed: null,
                  loading: true,
                ),
                AppButton(
                  key: const Key('outline'),
                  label: 'Cancel',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  onPressed: () => presses++,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const Key('primary')));
      await tester.tap(find.byKey(const Key('outline')));
      expect(presses, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('localized error, retry and success fit a narrow RTL screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: AppStatusView.error(
                  title: 'حدث خطأ في تحميل البيانات',
                  message: 'يمكنك المحاولة مرة أخرى.',
                  actionLabel: 'إعادة المحاولة',
                  onAction: () => retried = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AppStatusView.success(title: 'تم الحفظ')),
      ),
    );
    expect(find.text('تم الحفظ'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
  });
}
