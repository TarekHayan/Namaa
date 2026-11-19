import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_conflicts.dart';

import '../../../support/shared_widget_harness.dart';

AppColors _colors(Brightness brightness) =>
    brightness == Brightness.dark ? AppColors.dark : AppColors.light;

Widget _page({VoidCallback? onBack, int entries = 2}) => AppConflictsPage(
  pageKey: const Key('page'),
  backKey: const Key('back'),
  footerKey: const Key('footer'),
  title: 'Sync differences',
  backLabel: 'Back',
  onBack: onBack ?? () {},
  footer: 'View only; there is no action to take.',
  entries: [
    for (var i = 0; i < entries; i++)
      AppConflictEntryCard(
        titleKey: Key('title_$i'),
        title: 'Entry $i',
        active: AppConflictVersionCard(
          key: Key('active_$i'),
          label: 'Active version',
          time: 'Today 3:36 AM',
          activeVersion: true,
          child: const Text('value A'),
        ),
        saved: AppConflictVersionCard(
          key: Key('saved_$i'),
          label: 'Saved version',
          activeVersion: false,
          child: const Text('value B'),
        ),
      ),
  ],
);

void main() {
  for (final (name, brightness, direction) in kSharedMatrix) {
    testWidgets('the page shows the title, both versions and the footer, '
        'and offers only the back link ($name)', (tester) async {
      final colors = _colors(brightness);
      var backs = 0;
      await pumpShared(
        tester,
        _page(onBack: () => backs++),
        brightness: brightness,
        direction: direction,
      );
      expect(find.text('Sync differences'), findsOneWidget);
      expect(find.text('Entry 0'), findsOneWidget);
      expect(find.text('Today 3:36 AM'), findsNWidgets(2));
      expect(find.text('value A'), findsNWidgets(2));
      expect(
        find.text('View only; there is no action to take.'),
        findsOneWidget,
      );
      // The active version is highlighted; the saved one is on the secondary
      // surface.
      Color? fill(String key) =>
          ((tester
                      .widget<Container>(
                        find
                            .descendant(
                              of: find.byKey(Key(key)),
                              matching: find.byType(Container),
                            )
                            .first,
                      )
                      .decoration!)
                  as BoxDecoration)
              .color;
      expect(fill('active_0'), colors.accentSoft);
      expect(fill('saved_0'), colors.surfaceSecondary);
      // No action other than the back link.
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      await tester.tap(find.byKey(const Key('back')));
      expect(backs, 1);
    });
  }

  testWidgets('versions stack on a phone and sit side by side when wide', (
    tester,
  ) async {
    await pumpShared(tester, _page(entries: 1), size: const Size(400, 900));
    expect(
      tester.getTopLeft(find.byKey(const Key('saved_0'))).dy,
      greaterThan(tester.getBottomLeft(find.byKey(const Key('active_0'))).dy),
    );
    await pumpShared(tester, _page(entries: 1), size: const Size(1000, 900));
    expect(
      tester.getTopLeft(find.byKey(const Key('saved_0'))).dy,
      tester.getTopLeft(find.byKey(const Key('active_0'))).dy,
    );
  });

  testWidgets('renders at 320 px and 200% text without overflow', (
    tester,
  ) async {
    await pumpShared(tester, _page(), size: const Size(320, 900), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  group('appConflictStamp', () {
    final now = DateTime(2026, 11, 18, 10);
    String stamp(DateTime at) => appConflictStamp(
      at: at,
      now: now,
      locale: 'en',
      today: (time) => 'Today $time',
      yesterday: (time) => 'Yesterday $time',
    );

    setUpAll(() => initializeDateFormatting('en'));

    test('says today and yesterday, then the full date', () {
      expect(stamp(DateTime(2026, 11, 18, 3, 36)), startsWith('Today '));
      expect(stamp(DateTime(2026, 11, 17, 21, 40)), startsWith('Yesterday '));
      expect(stamp(DateTime(2026, 11, 1, 9)), contains('Nov'));
    });
  });
}
