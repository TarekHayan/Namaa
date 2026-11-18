import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/app.dart';
import 'package:namma_project/app/composition/configure_dependencies.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';
import 'package:namma_project/features/today/presentation/today_dashboard_view.dart';
import 'package:namma_project/features/today/presentation/widgets/today_bottom_navigation.dart';
import 'package:namma_project/features/today/presentation/widgets/today_navigation_sidebar.dart';

/// T067: the Adhkar and Qiyam routes on the real debug-preview graph (real
/// encrypted store, real catalog, no network), in Arabic and English, by
/// touch and by keyboard.
///
/// Each run goes Home -> Adhkar (from the Home hub), counts one dhikr, goes
/// back with the device back, goes Home -> Qiyam, answers Yes, goes back, and
/// then opens both again from the Track hub. Along the way:
/// - no route shows a back arrow, and the device back returns Home;
/// - the Home Adhkar tile and the Track hub subtitle show exactly the
///   "x / N" the Adhkar page shows, before and after the count;
/// - the Home Qiyam tile and the Track hub subtitle follow the answer saved
///   on the Qiyam page.
///
/// Run locally on Windows:
/// `flutter test integration_test/adhkar_qiyam_localized_route_test.dart -d windows`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final variant in const [
    _Variant('ar', keyboard: false, wide: false),
    _Variant('ar', keyboard: true, wide: false),
    _Variant('en', keyboard: false, wide: false),
    _Variant('en', keyboard: true, wide: false),
    _Variant('ar', keyboard: false, wide: true),
    _Variant('en', keyboard: true, wide: true),
  ]) {
    testWidgets('Adhkar and Qiyam routes: $variant', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = variant.wide
          ? const Size(1280, 900)
          : const Size(390, 2400);
      addTearDown(tester.view.reset);

      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('namaa_adhkar_qiyam_route_'),
      ))!;
      addTearDown(() async {
        await GetIt.instance.reset();
        await tester.runAsync(() => temp.delete(recursive: true));
      });
      await tester.runAsync(() async {
        await configureDependencies(
          environment: FoundationEnvironment.tasksPreview,
          secureStoreOverride: InMemorySecureKeyValueStore(),
          databasePathOverride: [
            temp.path,
            'foundation_encrypted.db',
          ].join(Platform.pathSeparator),
        );
        // The app restores this language when it starts.
        await GetIt.instance<LocaleCubit>().selectLanguage(
          variant.languageCode,
        );
      });

      Future<void> pumpUntilTrue(bool Function() done, String what) async {
        for (var i = 0; i < 200; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)),
          );
          await tester.pump(const Duration(milliseconds: 40));
          if (done()) return;
        }
        final present = [
          for (final key in const [
            'today_screen',
            'today_bottom_track',
            'today_sidebar_track',
            'prayer_track_0',
            'adhkar_header',
            'qiyam_header',
          ])
            if (find.byKey(Key(key)).evaluate().isNotEmpty) key,
        ];
        fail('timed out waiting for $what (present: $present)');
      }

      Future<void> pumpUntil(Finder finder, [String? what]) =>
          pumpUntilTrue(() => finder.evaluate().isNotEmpty, what ?? 'a widget');

      Future<int> count(String sql) async =>
          (await tester.runAsync(
                () => GetIt.instance<FoundationDatabase>().rawScalar(sql),
              ))!
              as int;

      /// Whether the focus is inside [target] (the keyed button, tile or
      /// InkWell the user means).
      bool focusIsOn(Finder target) {
        final focus = FocusManager.instance.primaryFocus?.context;
        if (focus == null || !focus.mounted) return false;
        for (final element in target.evaluate()) {
          var inside = false;
          focus.visitAncestorElements((ancestor) {
            if (identical(ancestor, element)) {
              inside = true;
              return false;
            }
            return true;
          });
          if (inside) return true;
        }
        return false;
      }

      /// Opens [target] the way the variant's user does: a tap, or Tab until
      /// the target has the focus and Enter.
      Future<void> activate(Finder target) async {
        await pumpUntil(target);
        await Scrollable.ensureVisible(
          tester.element(target.first),
          alignment: 0.5,
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (!variant.keyboard) {
          await tester.tap(target.first);
          await tester.pump(const Duration(milliseconds: 100));
          return;
        }
        for (var attempt = 0; attempt < 200; attempt++) {
          if (focusIsOn(target)) {
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pump(const Duration(milliseconds: 100));
            return;
          }
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump(const Duration(milliseconds: 20));
        }
        fail('Keyboard could not focus $target');
      }

      FoundationLocalizations copyOf(Finder anchor) =>
          FoundationLocalizations.of(tester.element(anchor.first));

      /// The value of a Home hero tile, read from its semantic label
      /// ("title: value"); null until the tile exists.
      String? homeTile(String title) {
        for (final semantics in tester.widgetList<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label ?? '').startsWith('$title: '),
          ),
        )) {
          return semantics.properties.label!.substring('$title: '.length);
        }
        return null;
      }

      Future<String> settledHomeTile(String title, RegExp shape) async {
        await pumpUntilTrue(() {
          final value = homeTile(title);
          return value != null && shape.hasMatch(value);
        }, 'the Home tile "$title"');
        return homeTile(title)!;
      }

      final ratio = RegExp(r'^\d+/\d+$');

      /// The "(x / N)" the Adhkar page shows for the open list.
      String adhkarPageRatio() {
        final texts = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(const Key('adhkar_progress_card')),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data ?? '');
        for (final text in texts) {
          final match = RegExp(r'\((\d+) / (\d+)\)').firstMatch(text);
          if (match != null) return '${match.group(1)}/${match.group(2)}';
        }
        fail('The Adhkar page shows no "x / N" progress');
      }

      void expectNoBackArrow() => expect(find.byType(BackButton), findsNothing);

      Future<void> deviceBackToHome(Finder pageMarker) async {
        expectNoBackArrow();
        await tester.binding.handlePopRoute();
        await pumpUntilTrue(
          () => pageMarker.evaluate().isEmpty,
          'Home after the device back',
        );
        await pumpUntil(find.byKey(kDashboardProgressGroup));
      }

      await tester.pumpWidget(const FoundationApp());
      await pumpUntil(find.byKey(kDashboardProgressGroup));
      final copy = copyOf(find.byKey(kDashboardProgressGroup));
      expect(
        copy.localeName,
        variant.languageCode,
        reason: 'the app runs in the language of the variant',
      );
      expect(
        Directionality.of(tester.element(find.byKey(kDashboardProgressGroup))),
        variant.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );

      final hubs = find.byKey(kDashboardHubsGroup);
      // The hub's InkWell: the element that takes the tap and the focus.
      Finder hub(String title) => find.ancestor(
        of: find.descendant(of: hubs, matching: find.text(title)),
        matching: find.byType(InkWell),
      );
      final adhkarHub = hub(copy.dashboardComingSoonAdhkarTitle);
      final qiyamHub = hub(copy.dashboardComingSoonQiyamTitle);
      final track = variant.wide
          ? find.byKey(kTodaySidebarTrackKey)
          : find.byKey(kTodayBottomTrackKey);

      // 1. Home shows the live Adhkar value (the Morning list).
      final homeBefore = await settledHomeTile(copy.adhkarTabMorning, ratio);
      expect(
        homeBefore,
        matches(RegExp(r'^0/\d+$')),
        reason: 'nothing counted',
      );
      final qiyamTitle = copy.dashboardAdhkarQiyam;
      expect(
        await settledHomeTile(qiyamTitle, RegExp('.+')),
        copy.qiyamHistoryNotRecorded,
        reason: 'tonight is not answered yet',
      );

      // 2. Home -> Adhkar. The page shows the same x / N as Home.
      await activate(adhkarHub);
      await pumpUntil(find.byKey(const Key('adhkar_progress_card')));
      expect(adhkarPageRatio(), homeBefore, reason: 'Home equals the page');
      expectNoBackArrow();

      // 3. Count one dhikr in the reader, then close it.
      await activate(find.byKey(const Key('adhkar_main_button')));
      await pumpUntil(find.byKey(const Key('adhkar_reader')));
      if (variant.keyboard) {
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump(const Duration(milliseconds: 100));
      } else {
        await tester.tap(find.byKey(const Key('adhkar_reader_count')));
      }
      // The reader reacts to the count: the done bar for a one-tap dhikr, or
      // the position line while it stays on a multi-tap one.
      await pumpUntilTrue(
        () =>
            find
                .byKey(const Key('adhkar_reader_done_bar'))
                .evaluate()
                .isNotEmpty ||
            find
                .byKey(const Key('adhkar_reader_position'))
                .evaluate()
                .isNotEmpty,
        'the reader to react to the count',
      );
      await activate(find.byKey(const Key('adhkar_reader_close')));
      await pumpUntil(find.byKey(const Key('adhkar_main_button')));
      final pageAfter = adhkarPageRatio();
      expect(
        await count('SELECT count(*) FROM adhkar_item_counts'),
        greaterThanOrEqualTo(1),
        reason: 'the count is stored locally',
      );
      expect(
        await count('SELECT count(*) FROM pending_changes'),
        0,
        reason: 'a preview count queues nothing for upload',
      );

      // 4. Device back returns Home, and Home shows the page's new value.
      await deviceBackToHome(find.byKey(const Key('adhkar_header')));
      expect(
        await settledHomeTile(copy.adhkarTabMorning, ratio),
        pageAfter,
        reason: 'Home equals the page after counting',
      );

      // 5. Home -> Qiyam: Yes, then back.
      await activate(qiyamHub);
      await pumpUntil(find.byKey(const Key('qiyam_header')));
      expectNoBackArrow();
      await activate(find.byKey(const Key('qiyam_yes')));
      await pumpUntil(find.byKey(const Key('qiyam_celebration')));
      expect(await count('SELECT count(*) FROM qiyam_nights'), 1);
      await pumpUntil(find.text(copy.qiyamSaved));
      await deviceBackToHome(find.byKey(const Key('qiyam_header')));
      expect(
        await settledHomeTile(qiyamTitle, RegExp('.+')),
        copy.qiyamSegYes,
        reason: 'Home shows the answer saved on the Qiyam page',
      );

      // 6. Track hub: live subtitles equal the pages, and both tiles open
      // the real routes.
      Future<void> openTrack() async {
        await activate(track);
        await pumpUntil(find.byKey(const Key('prayer_track_3')));
        expectNoBackArrow();
      }

      await openTrack();
      final expectedAdhkarPrefix = copy
          .dashboardTrackAdhkarSubtitle(pageAfter, '@@')
          .split('@@')
          .first;
      final adhkarSubtitle = find.byKey(const Key('prayer_track_subtitle_3'));
      await pumpUntil(adhkarSubtitle);
      expect(
        tester.widget<Text>(adhkarSubtitle).data,
        startsWith(expectedAdhkarPrefix),
        reason: 'the Track hub equals the Adhkar page',
      );
      final qiyamSubtitle = find.byKey(const Key('prayer_track_subtitle_4'));
      await pumpUntil(qiyamSubtitle);
      expect(
        tester.widget<Text>(qiyamSubtitle).data,
        copy.dashboardTrackQiyamRecorded,
      );
      // Quran and Focus stay coming soon.
      for (final index in [1, 2]) {
        expect(
          find.descendant(
            of: find.byKey(Key('prayer_track_$index')),
            matching: find.text(copy.dashboardComingSoon),
          ),
          findsOneWidget,
        );
      }

      await activate(find.byKey(const Key('prayer_track_3')));
      await pumpUntil(find.byKey(const Key('adhkar_progress_card')));
      expect(adhkarPageRatio(), pageAfter);
      await deviceBackToHome(find.byKey(const Key('adhkar_header')));

      await openTrack();
      await activate(find.byKey(const Key('prayer_track_4')));
      await pumpUntil(find.byKey(const Key('qiyam_header')));
      // The saved answer is still there.
      await pumpUntil(find.byKey(const Key('qiyam_answer_switch')));
      expect(await count('SELECT count(*) FROM qiyam_nights'), 1);
      await deviceBackToHome(find.byKey(const Key('qiyam_header')));

      // 7. A wide layout also opens both from the sidebar.
      if (variant.wide) {
        await activate(find.byKey(kTodaySidebarAdhkarKey));
        await pumpUntil(find.byKey(const Key('adhkar_progress_card')));
        await deviceBackToHome(find.byKey(const Key('adhkar_header')));
        await activate(find.byKey(kTodaySidebarQiyamKey));
        await pumpUntil(find.byKey(const Key('qiyam_header')));
        await deviceBackToHome(find.byKey(const Key('qiyam_header')));
      }

      // Unmount and let the store's zero-length close timers run.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    });
  }
}

final class _Variant {
  const _Variant(
    this.languageCode, {
    required this.keyboard,
    required this.wide,
  });

  final String languageCode;
  final bool keyboard;
  final bool wide;

  @override
  String toString() =>
      '$languageCode ${keyboard ? 'keyboard' : 'touch'} '
      '${wide ? 'desktop' : 'phone'}';
}
