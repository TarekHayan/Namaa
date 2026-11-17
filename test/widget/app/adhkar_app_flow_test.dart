import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:namma_project/app/app.dart';
import 'package:namma_project/app/composition/configure_dependencies.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/adhkar/presentation/widgets/dhikr_item_card.dart';

/// T035/T034 end to end on the real debug-preview graph: the Home Adhkar hub
/// opens `/adhkar`, the screen renders the real approved catalog (Quran items
/// first, in the Quran font), a count is stored locally, and device back
/// returns Home. Real encrypted database, real asset, no network.
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

    // The real catalog: the first Morning item is Ayat al-Kursi (m25), a
    // Quran item shown with its isti'adha preface, in the Quran font.
    await pumpUntil(find.byKey(const Key('adhkar_item_card_m25')));
    expect(find.byKey(const Key('adhkar_preface_m25')), findsOneWidget);
    expect(find.byKey(const Key('adhkar_surah_m25')), findsOneWidget);
    final quranText = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('adhkar_item_card_m25')),
            matching: find.byType(Text),
          ),
        )
        .where((t) => t.style?.fontFamily == kQuranFontFamily);
    expect(quranText, isNotEmpty);
    // The attribution line is shown under the cards.
    expect(find.byKey(const Key('adhkar_attribution')), findsOneWidget);

    // No Prayer location is saved in this run, so counting is unrestricted:
    // one tap counts and the item reaches its target of 1.
    final count = find.byKey(const Key('adhkar_count_m25'));
    await tester.ensureVisible(count);
    expect(tester.widget<FilledButton>(count).onPressed, isNotNull);
    await tester.tap(count);
    await pumpUntilTrue(
      () => tester.widget<FilledButton>(count).onPressed == null,
      'the item to reach its target',
    );

    // Evening has its own Quran items first.
    final eveningTab = find.byKey(const Key('adhkar_switch_evening'));
    await tester.ensureVisible(eveningTab);
    await tester.pump();
    await tester.tap(eveningTab);
    await pumpUntil(find.byKey(const Key('adhkar_item_card_e23')));

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
