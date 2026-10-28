import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_menu_design.dart';
import 'package:namma_project/app/theme/app_select_field.dart';
import 'package:namma_project/app/theme/app_theme.dart';

void main() {
  for (final (theme, colors) in [
    (AppTheme.dark, AppColors.dark),
    (AppTheme.light, AppColors.light),
  ]) {
    testWidgets('shared selector opens and selects with the app menu design', (
      tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: Center(
                child: SizedBox(
                  width: 260,
                  child: AppSelectField<String>(
                    key: const Key('shared_select'),
                    initialValue: 'first',
                    decoration: const InputDecoration(labelText: 'التصنيف'),
                    items: const [
                      DropdownMenuItem(value: 'first', child: Text('الأول')),
                      DropdownMenuItem(value: 'second', child: Text('الثاني')),
                    ],
                    onChanged: (value) => chosen = value,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dropdown.dropdownColor, colors.surface);
      expect(dropdown.borderRadius, AppMenuDesign.radius);
      expect(dropdown.menuMaxHeight, AppMenuDesign.maxHeight);
      expect(
        Theme.of(
          tester.element(find.byKey(const Key('shared_select'))),
        ).popupMenuTheme.color,
        colors.surface,
      );

      await tester.tap(find.byKey(const Key('shared_select')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الثاني').last);
      await tester.pumpAndSettle();
      expect(chosen, 'second');
      expect(tester.takeException(), isNull);
    });

    testWidgets('shared labeled selectors leave room for floating labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final label in ['النوع', 'الأولوية'])
                      AppSelectField<String>(
                        initialValue: 'first',
                        decoration: InputDecoration(labelText: label),
                        items: const [
                          DropdownMenuItem(
                            value: 'first',
                            child: Text('الأول'),
                          ),
                        ],
                        onChanged: (_) {},
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final fields = find.byType(DropdownButtonFormField<String>);
      expect(fields, findsNWidgets(2));
      final gap =
          tester.getTopLeft(fields.at(1)).dy -
          tester.getBottomLeft(fields.at(0)).dy;
      expect(gap, greaterThanOrEqualTo(16));
      expect(tester.takeException(), isNull);
    });
  }
}
