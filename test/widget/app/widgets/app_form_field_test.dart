import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_form_field.dart';

import '../../../support/shared_widget_harness.dart';

AppColors _colors(Brightness brightness) =>
    brightness == Brightness.dark ? AppColors.dark : AppColors.light;

void main() {
  for (final (name, brightness, direction) in kSharedMatrix) {
    testWidgets('a labeled field with the counted decoration ($name)', (
      tester,
    ) async {
      final colors = _colors(brightness);
      late InputDecoration decoration;
      await pumpShared(
        tester,
        Builder(
          builder: (context) {
            decoration = appCountedFieldDecoration(
              AppColors.of(context),
              counterText: '9 / 60',
              counterKey: const Key('counter'),
              counterError: false,
              helperText: 'A short helper',
            );
            return AppLabeledField(
              label: 'Group name',
              field: TextField(key: const Key('field'), decoration: decoration),
            );
          },
        ),
        brightness: brightness,
        direction: direction,
      );
      expect(find.text('Group name'), findsOneWidget);
      expect(find.text('9 / 60'), findsOneWidget);
      expect(find.text('A short helper'), findsOneWidget);
      expect(decoration.filled, isTrue);
      expect(decoration.fillColor, colors.surfaceSecondary);
      expect(
        (decoration.enabledBorder! as OutlineInputBorder).borderSide.color,
        colors.border,
      );
      final focused = decoration.focusedBorder! as OutlineInputBorder;
      expect(focused.borderSide.color, colors.primary);
      expect(focused.borderSide.width, 1.5);
      expect(focused.borderRadius, BorderRadius.circular(16));
      // The label sits above the field.
      expect(
        tester.getBottomLeft(find.text('Group name')).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byKey(const Key('field'))).dy),
      );
    });

    testWidgets('an error shows its note, and the counter stays left to '
        'right ($name)', (tester) async {
      final colors = _colors(brightness);
      await pumpShared(
        tester,
        Builder(
          builder: (context) => TextField(
            decoration: appCountedFieldDecoration(
              AppColors.of(context),
              counterText: '61 / 60',
              counterKey: const Key('counter'),
              counterError: true,
              errorText: 'Enter 1 to 60 characters.',
            ),
          ),
        ),
        brightness: brightness,
        direction: direction,
      );
      expect(find.text('Enter 1 to 60 characters.'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('counter'))).style!.color,
        colors.errorText,
      );
      final counterDirection = tester.widget<Directionality>(
        find
            .ancestor(
              of: find.byKey(const Key('counter')),
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(counterDirection.textDirection, TextDirection.ltr);
    });
  }
}
