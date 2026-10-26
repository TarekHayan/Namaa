import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_theme.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_hover_surface.dart';

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets('buttons highlight and cards glow on mouse hover', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(label: 'Save', onPressed: () {}),
                  const SizedBox(height: 30),
                  const AppHoverSurface(
                    child: SizedBox(width: 140, height: 60),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final normal = button.style!.backgroundColor!.resolve(<WidgetState>{});
      final hovered = button.style!.backgroundColor!.resolve({
        WidgetState.hovered,
      });
      expect(hovered, isNot(normal));
      expect(button.style!.elevation!.resolve({WidgetState.hovered}), 6);

      final surface = find.byType(AppHoverSurface);
      BoxDecoration decoration() =>
          tester
                  .widget<AnimatedContainer>(
                    find.descendant(
                      of: surface,
                      matching: find.byType(AnimatedContainer),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(decoration().boxShadow, isEmpty);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(surface));
      await mouse.moveTo(tester.getCenter(surface));
      await tester.pumpAndSettle();
      expect(decoration().boxShadow, isNotEmpty);

      await mouse.moveTo(const Offset(0, 0));
      await tester.pumpAndSettle();
      expect(decoration().boxShadow, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
