import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:namma_project/app/app.dart';
import 'package:namma_project/app/composition/configure_dependencies.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';

/// T049/T107 end to end on the real debug-preview graph: the Home Qiyam hub
/// opens `/qiyam`, the supplications come from the real approved catalog (the
/// Witr supplication and the Qunut, in Amiri), a Yes is recorded locally with
/// its one award and nothing queued for upload, Yes -> No -> Yes never adds a
/// second award, and device back returns Home. Real encrypted database, real
/// asset, no network.
void main() {
  testWidgets('Home opens Qiyam, records locally and awards once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final temp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('namaa_qiyam_app_'),
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

    Future<int> count(String sql) async =>
        (await tester.runAsync(
              () => GetIt.instance<FoundationDatabase>().rawScalar(sql),
            ))!
            as int;

    await tester.pumpWidget(const FoundationApp());
    final qiyamHub = find.byIcon(Icons.nightlight_round);
    await pumpUntil(qiyamHub);
    await tester.ensureVisible(qiyamHub);
    await tester.tap(qiyamHub);
    await pumpUntil(find.byKey(const Key('qiyam_header')));
    await pumpUntil(find.byKey(const Key('qiyam_yes')));

    // The real reviewed supplications: the Witr supplication and the Qunut,
    // in Amiri, collapsed to four lines.
    for (final id in ['s1', 's2']) {
      final text = tester.widget<Text>(
        find.byKey(Key('qiyam_supplication_$id')),
      );
      expect(text.data!.trim(), isNotEmpty);
      expect(text.style?.fontFamily, 'Amiri');
      expect(text.maxLines, 4);
      expect(find.byKey(Key('qiyam_supplication_source_$id')), findsOneWidget);
    }

    // Yes records at once: the points moment and the details appear.
    await tester.ensureVisible(find.byKey(const Key('qiyam_yes')));
    await tester.tap(find.byKey(const Key('qiyam_yes')));
    await pumpUntil(find.byKey(const Key('qiyam_celebration')));
    await pumpUntil(find.byKey(const Key('qiyam_rakah_chip_4')));
    expect(await count('SELECT count(*) FROM qiyam_nights'), 1);
    expect(
      await count("SELECT count(*) FROM xp_awards WHERE source = 'qiyam_done'"),
      1,
    );
    expect(
      await count('SELECT count(*) FROM pending_changes'),
      0,
      reason: 'a preview record queues nothing for upload',
    );

    // Yes -> No -> Yes: still one record and one award.
    await tester.ensureVisible(find.byKey(const Key('qiyam_seg_no')));
    await tester.tap(find.byKey(const Key('qiyam_seg_no')));
    await pumpUntil(find.byKey(const Key('qiyam_calm_no')));
    await tester.tap(find.byKey(const Key('qiyam_seg_yes')));
    await pumpUntil(find.byKey(const Key('qiyam_rakah_chip_4')));
    // The form shows at once; wait for the save itself before reading the
    // store.
    await pumpUntil(find.text('Saved'));
    expect(await count('SELECT count(*) FROM qiyam_nights'), 1);
    expect(
      await count("SELECT count(*) FROM xp_awards WHERE source = 'qiyam_done'"),
      1,
      reason: 'one award per night',
    );

    // The page is a tab: no back arrow, and device back goes Home.
    expect(find.byType(BackButton), findsNothing);
    await tester.binding.handlePopRoute();
    final header = find.byKey(const Key('qiyam_header'));
    await pumpUntilTrue(() => header.evaluate().isEmpty, 'Home after back');
    await pumpUntil(qiyamHub);

    // Unmount and let the store's zero-length close timers run.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  });
}
