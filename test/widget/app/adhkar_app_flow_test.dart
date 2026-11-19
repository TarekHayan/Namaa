import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:namma_project/app/app.dart';
import 'package:namma_project/app/composition/configure_dependencies.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/adhkar/presentation/widgets/adhkar_style.dart';

/// T035/T034 end to end on the real debug-preview graph: the Home Adhkar hub
/// opens `/adhkar`, the reader renders the real approved catalog (Quran items
/// first, in the Quran font), a count is stored locally, and device back
/// closes the reader and then returns Home. Real encrypted database, real asset, no network.
void main() {
  testWidgets('Home opens Adhkar with the real catalog and counts locally', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final temp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('namaa_adhkar_app_'),
    ))!;
    addTearDown(() async {
      await GetIt.instance.reset();
      await tester.runAsync(() => temp.delete(recursive: true));
    });
    await tester.runAsync(
      () => configureDependencies(
        environment: FoundationEnvironment.tasksPreview,
        secureStoreOverride: InMemorySecureKeyValueStore(),
        databasePathOverride: [
          temp.path,
          'foundation_encrypted.db',
        ].join(Platform.pathSeparator),
      ),
    );

    Future<void> pumpUntilTrue(bool Function() done, String what) async {
      for (var i = 0; i < 150; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pump(const Duration(milliseconds: 40));
        if (done()) return;
      }
      fail('timed out waiting for $what');
    }

    Future<void> pumpUntil(Finder finder) =>
        pumpUntilTrue(() => finder.evaluate().isNotEmpty, finder.toString());

    await tester.pumpWidget(const FoundationApp());
    final adhkarHub = find.byIcon(Icons.wb_sunny_rounded);
    await pumpUntil(adhkarHub);

    await tester.ensureVisible(adhkarHub);
    await tester.tap(adhkarHub);
    await pumpUntil(find.byKey(const Key('adhkar_header')));

    // The page: the progress card, the time-window line and the main button
    // (no list of item cards any more). Nothing is counted yet, so «Start».
    await pumpUntil(find.byKey(const Key('adhkar_main_button')));
    expect(find.byKey(const Key('adhkar_progress_card')), findsOneWidget);
    expect(find.byKey(const Key('adhkar_item_card_m25')), findsNothing);
    expect(find.byKey(const Key('adhkar_attribution')), findsOneWidget);

    // The reader opens at the first item: Ayat al-Kursi (m25), a Quran item
    // shown with its isti'adha preface, in the Quran font.
    await tester.tap(find.byKey(const Key('adhkar_main_button')));
    await pumpUntil(find.byKey(const Key('adhkar_reader_page_m25')));
    expect(find.byKey(const Key('adhkar_preface_m25')), findsOneWidget);
    final quranText = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('adhkar_reader_page_m25')),
            matching: find.byType(Text),
          ),
        )
        .where((t) => t.style?.fontFamily == kQuranFontFamily);
    expect(quranText, isNotEmpty);

    // No Prayer location is saved in this run, so counting is unrestricted:
    // one tap counts and the item reaches its target of 1, then the done bar
    // and the slide to the next item.
    final count = find.byKey(const Key('adhkar_reader_count'));
    expect(tester.widget<InkWell>(count).onTap, isNotNull);
    await tester.tap(count);
    await pumpUntil(find.byKey(const Key('adhkar_reader_done_bar')));
    await pumpUntilTrue(
      () => find.byKey(const Key('adhkar_reader_done_bar')).evaluate().isEmpty,
      'the slide to the next item',
    );
    await pumpUntil(find.byKey(const Key('adhkar_reader_page_m11')));
    await pumpUntilTrue(
      () => find.byKey(const Key('adhkar_reader_page_m25')).evaluate().isEmpty,
      'the first page to leave',
    );

    // Device back closes the reader first, back on the Adhkar page.
    await tester.binding.handlePopRoute();
    await pumpUntil(find.byKey(const Key('adhkar_main_button')));
    expect(find.byKey(const Key('adhkar_reader')), findsNothing);
    expect(
      find.byKey(const Key('adhkar_switch_evening')),
      findsOneWidget,
      reason: 'still on the Adhkar page',
    );

    // Evening has its own list and progress.
    final eveningTab = find.byKey(const Key('adhkar_switch_evening'));
    await tester.tap(eveningTab);
    await pumpUntil(find.byKey(const Key('adhkar_progress_card')));
    await tester.tap(find.byKey(const Key('adhkar_main_button')));
    await pumpUntil(find.byKey(const Key('adhkar_reader_page_e23')));
    await tester.tap(find.byKey(const Key('adhkar_reader_close')));
    await pumpUntil(find.byKey(const Key('adhkar_main_button')));

    // The page is a tab: no back arrow, and device back goes Home.
    expect(find.byType(BackButton), findsNothing);
    await tester.binding.handlePopRoute();
    final header = find.byKey(const Key('adhkar_header'));
    await pumpUntilTrue(() => header.evaluate().isEmpty, 'Home after back');
    await pumpUntil(adhkarHub);

    // Unmount and let the store's zero-length close timers run, so nothing
    // is left pending when the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  });
}
