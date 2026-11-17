import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_commands.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';
import 'package:namma_project/features/adhkar/presentation/my_adhkar_cubit.dart';
import 'package:namma_project/features/adhkar/presentation/widgets/my_adhkar_tab.dart';

import '../../../support/my_adhkar_test_support.dart';

/// T097: the My Adhkar tab (contracts/adhkar-qiyam-ui.md, Story 5): the
/// group list and an opened group, the create/rename form, the in-page group
/// and entry delete confirmations, the entry cards (selectable Amiri text,
/// selectable plain-text source, the other groups, Edit/Copy/Delete), the
/// two-field add/edit form with its group chips, the limits, the device-back
/// order, and the AR/EN light/dark 320 px 200% matrix with no overflow. The
/// store is in memory; the Cubit is the real one.
void main() {
  late MemoryMyAdhkarStore store;
  late MyAdhkarCubit cubit;
  late GoRouter router;

  setUp(() {
    store = MemoryMyAdhkarStore();
  });

  tearDown(() async {
    await cubit.close();
  });

  Future<void> pumpTab(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
    Size size = const Size(500, 1000),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
    cubit = store.cubit();
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('home page'))),
        ),
        GoRoute(
          path: '/adhkar',
          builder: (context, state) => Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: BlocProvider.value(
                  value: cubit,
                  child: const MyAdhkarTab(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: locale,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        theme: ThemeData(brightness: brightness, useMaterial3: true),
        routerConfig: router,
      ),
    );
    unawaited(router.push('/adhkar'));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pickMenu(
    WidgetTester tester,
    String menuKey,
    String label,
  ) async {
    await tapKey(tester, menuKey);
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  MyAdhkarGroup seedGroupWithEntries() {
    final groupA = store.addGroup('group a', id: 'ga');
    final groupB = store.addGroup('group b', id: 'gb');
    store.addItem(
      text: 'entry text 1',
      source: 'source 1',
      groupIds: [groupA.groupId],
      id: 'i1',
    );
    store.addItem(
      text: 'entry text 2',
      groupIds: [groupA.groupId, groupB.groupId],
      id: 'i2',
    );
    return groupA;
  }

  group('group list', () {
    testWidgets('empty state: what the tab is for, examples, and Create a '
        'group (English)', (tester) async {
      await pumpTab(tester);
      expect(find.byKey(const Key('my_adhkar_header')), findsOneWidget);
      expect(find.text('Your own adhkar and duas'), findsOneWidget);
      expect(find.textContaining('does not review it'), findsOneWidget);
      expect(find.byKey(const Key('my_adhkar_empty')), findsOneWidget);
      expect(find.textContaining('“Fajr”'), findsOneWidget);
      expect(find.textContaining('“Duas for distress”'), findsOneWidget);
      expect(find.byKey(const Key('my_adhkar_create_group')), findsOneWidget);
      expect(find.byType(AppBar), findsNothing, reason: 'no app-bar back');
    });

    testWidgets('empty state in Arabic is right-to-left', (tester) async {
      await pumpTab(tester, locale: const Locale('ar'));
      expect(find.text('أذكارك وأدعيتك الخاصة'), findsOneWidget);
      expect(find.text('إنشاء مجموعة'), findsOneWidget);
      expect(find.textContaining('«رمضان»'), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('my_adhkar_tab'))),
        ),
        TextDirection.rtl,
      );
    });

    testWidgets('rows oldest first with name and entry count, and an '
        'overflow menu', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      final first = tester
          .getTopLeft(find.byKey(const Key('my_adhkar_group_ga')))
          .dy;
      final second = tester
          .getTopLeft(find.byKey(const Key('my_adhkar_group_gb')))
          .dy;
      expect(first, lessThan(second));
      expect(find.text('group a'), findsOneWidget);
      expect(find.text('2 adhkar'), findsOneWidget);
      expect(find.text('1 dhikr'), findsOneWidget);
      expect(find.byKey(const Key('my_adhkar_group_menu_ga')), findsOneWidget);
    });

    testWidgets('plural entry counts read naturally in Arabic', (tester) async {
      final group = store.addGroup('مجموعة أ', id: 'ga');
      for (var i = 0; i < 3; i++) {
        store.addItem(text: 'نص تجريبي $i', groupIds: [group.groupId]);
      }
      store.addGroup('مجموعة ب', id: 'gb');
      await pumpTab(tester, locale: const Locale('ar'));
      expect(find.text('3 أذكار'), findsOneWidget);
      expect(find.text('لا أذكار'), findsOneWidget);
    });

    testWidgets('create a group: counter, save, and the new row', (
      tester,
    ) async {
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_create_group');
      expect(find.byKey(const Key('my_adhkar_group_form')), findsOneWidget);
      expect(find.text('0 / 60'), findsOneWidget);
      var save = tester.widget<FilledButton>(
        find.byKey(const Key('my_adhkar_group_save')),
      );
      expect(save.onPressed, isNull, reason: 'a blank name cannot be saved');
      await tester.enterText(
        find.byKey(const Key('my_adhkar_group_name_field')),
        '  group one ',
      );
      await tester.pump();
      expect(find.text('9 / 60'), findsOneWidget, reason: 'trimmed length');
      save = tester.widget<FilledButton>(
        find.byKey(const Key('my_adhkar_group_save')),
      );
      expect(save.onPressed, isNotNull);
      await tapKey(tester, 'my_adhkar_group_save');
      expect(find.byKey(const Key('my_adhkar_group_form')), findsNothing);
      expect(find.text('group one'), findsOneWidget);
      expect(find.text('No adhkar'), findsOneWidget);
      expect(find.byKey(const Key('my_adhkar_empty')), findsNothing);
    });

    testWidgets('a name over 60 shows the inline error and keeps Save '
        'disabled', (tester) async {
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_create_group');
      await tester.enterText(
        find.byKey(const Key('my_adhkar_group_name_field')),
        'x' * 61,
      );
      await tester.pump();
      expect(find.text('61 / 60'), findsOneWidget);
      expect(find.text('Enter a name of 1 to 60 characters.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('my_adhkar_group_save')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('a rejected create shows the typed reason inline and keeps '
        'the form open', (tester) async {
      await pumpTab(tester);
      store.rejectNextWith = const MyAdhkarGroupLimitReached();
      await tapKey(tester, 'my_adhkar_create_group');
      await tester.enterText(
        find.byKey(const Key('my_adhkar_group_name_field')),
        'group one',
      );
      await tester.pump();
      await tapKey(tester, 'my_adhkar_group_save');
      expect(find.byKey(const Key('my_adhkar_group_form')), findsOneWidget);
      expect(
        find.text('You have reached the limit: 100 groups.'),
        findsOneWidget,
      );
    });

    testWidgets('rename keeps the entries', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await pickMenu(tester, 'my_adhkar_group_menu_ga', 'Rename');
      expect(find.text('Rename group'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('my_adhkar_group_name_field')),
      );
      expect(field.controller!.text, 'group a');
      await tester.enterText(
        find.byKey(const Key('my_adhkar_group_name_field')),
        'group renamed',
      );
      await tester.pump();
      await tapKey(tester, 'my_adhkar_group_save');
      expect(find.text('group renamed'), findsOneWidget);
      expect(find.text('2 adhkar'), findsOneWidget);
    });

    testWidgets('group delete asks in the page with the count and the '
        'other-groups note; cancel keeps it', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await pickMenu(tester, 'my_adhkar_group_menu_ga', 'Delete');
      expect(
        find.byKey(const Key('my_adhkar_group_delete_confirmation_ga')),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing, reason: 'in the page');
      expect(find.text('Delete this group?'), findsOneWidget);
      expect(
        find.textContaining('One dhikr will be deleted.'),
        findsOneWidget,
        reason: 'only entry 1 is solely in group a',
      );
      expect(
        find.textContaining('also in other groups stay there'),
        findsOneWidget,
      );
      await tapKey(tester, 'my_adhkar_group_delete_cancel');
      expect(find.byKey(const Key('my_adhkar_group_ga')), findsOneWidget);
      expect(
        find.byKey(const Key('my_adhkar_group_delete_confirmation_ga')),
        findsNothing,
      );
    });

    testWidgets('confirming the group delete removes it and its only '
        'entries; the shared entry stays in the other group', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await pickMenu(tester, 'my_adhkar_group_menu_ga', 'Delete');
      await tapKey(tester, 'my_adhkar_group_delete_confirm');
      expect(find.byKey(const Key('my_adhkar_group_ga')), findsNothing);
      expect(store.items.map((i) => i.itemId), ['i2']);
      expect(find.text('1 dhikr'), findsOneWidget);
    });

    testWidgets('the delete confirmation counts in Arabic', (tester) async {
      final group = store.addGroup('مجموعة أ', id: 'ga');
      store.addItem(text: 'نص تجريبي ١', groupIds: [group.groupId]);
      store.addItem(text: 'نص تجريبي ٢', groupIds: [group.groupId]);
      await pumpTab(tester, locale: const Locale('ar'));
      await pickMenu(tester, 'my_adhkar_group_menu_ga', 'حذف');
      expect(find.textContaining('سيُحذف ذكران.'), findsOneWidget);
      expect(find.textContaining('تبقى فيها'), findsOneWidget);
    });

    testWidgets('100 groups disable Create with the reason', (tester) async {
      for (var i = 0; i < 100; i++) {
        store.addGroup('group $i', id: 'g$i');
      }
      await pumpTab(tester);
      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('my_adhkar_create_group')),
      );
      expect(button.onPressed, isNull);
      expect(
        find.byKey(const Key('my_adhkar_group_limit_reason')),
        findsOneWidget,
      );
      expect(
        find.text('You have reached the limit: 100 groups.'),
        findsOneWidget,
      );
    });
  });

  group('opened group', () {
    testWidgets('a group opens in place with a back-to-groups control and '
        'the entries in order', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      expect(find.byKey(const Key('my_adhkar_group_title')), findsOneWidget);
      expect(find.byKey(const Key('my_adhkar_back_to_groups')), findsOneWidget);
      expect(find.byKey(const Key('my_adhkar_group_gb')), findsNothing);
      final first = tester
          .getTopLeft(find.byKey(const Key('my_adhkar_entry_i1')))
          .dy;
      final second = tester
          .getTopLeft(find.byKey(const Key('my_adhkar_entry_i2')))
          .dy;
      expect(first, lessThan(second));
      expect(find.byType(AppBar), findsNothing);
      await tapKey(tester, 'my_adhkar_back_to_groups');
      expect(find.byKey(const Key('my_adhkar_group_ga')), findsOneWidget);
      expect(find.byKey(const Key('my_adhkar_entry_i1')), findsNothing);
    });

    testWidgets('an empty group shows its empty state', (tester) async {
      store.addGroup('group a', id: 'ga');
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      expect(find.byKey(const Key('my_adhkar_group_empty')), findsOneWidget);
      expect(find.byKey(const Key('my_adhkar_add_entry')), findsOneWidget);
    });

    testWidgets('device back closes the group first, then leaves for Home', (
      tester,
    ) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      expect(find.byKey(const Key('my_adhkar_entry_i1')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('my_adhkar_entry_i1')), findsNothing);
      expect(find.byKey(const Key('my_adhkar_group_ga')), findsOneWidget);
      expect(find.text('home page'), findsNothing, reason: 'still on the tab');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('home page'), findsOneWidget);
    });

    testWidgets('device back closes a sheet, then an in-place confirmation, '
        'then the group, then goes Home', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');

      await tapKey(tester, 'my_adhkar_add_entry');
      expect(find.byKey(const Key('my_adhkar_entry_form')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('my_adhkar_entry_form')), findsNothing);
      expect(
        find.byKey(const Key('my_adhkar_entry_i1')),
        findsOneWidget,
        reason: 'the sheet closed first; the group stays open',
      );

      await pickMenu(tester, 'my_adhkar_entry_menu_i2', 'Delete');
      expect(
        find.byKey(const Key('my_adhkar_entry_delete_confirmation_i2')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('my_adhkar_entry_delete_confirmation_i2')),
        findsNothing,
      );
      expect(find.byKey(const Key('my_adhkar_entry_i2')), findsOneWidget);
      expect(find.byKey(const Key('my_adhkar_entry_i1')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('my_adhkar_entry_i1')), findsNothing);
      expect(find.byKey(const Key('my_adhkar_group_ga')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('home page'), findsOneWidget);
    });

    testWidgets('1000 entries disable Add with the reason', (tester) async {
      seedGroupWithEntries();
      store.phantomEntries = 998;
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('my_adhkar_add_entry')),
      );
      expect(button.onPressed, isNull);
      expect(
        find.byKey(const Key('my_adhkar_add_limit_reason')),
        findsOneWidget,
      );
      expect(
        find.text('You have reached the limit: 1000 adhkar.'),
        findsOneWidget,
      );
    });
  });

  group('entry cards', () {
    testWidgets('the text is selectable Amiri, the source is selectable '
        'plain text below it, and nothing counts', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      final text = tester.widget<SelectableText>(
        find.byKey(const Key('my_adhkar_entry_text_i1')),
      );
      expect(text.style?.fontFamily, 'Amiri');
      final source = tester.widget<SelectableText>(
        find.byKey(const Key('my_adhkar_entry_source_i1')),
      );
      expect(source.data, 'source 1');
      expect(
        tester
            .getTopLeft(find.byKey(const Key('my_adhkar_entry_source_i1')))
            .dy,
        greaterThan(
          tester
              .getTopLeft(find.byKey(const Key('my_adhkar_entry_text_i1')))
              .dy,
        ),
      );
      // No counter, target, reset, badge or completed state of any kind.
      expect(find.byIcon(Icons.restart_alt_outlined), findsNothing);
      expect(find.textContaining('Target'), findsNothing);
      expect(find.textContaining('Tap to count'), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('an entry with no source shows no source line', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      expect(find.byKey(const Key('my_adhkar_entry_source_i2')), findsNothing);
      expect(find.byKey(const Key('my_adhkar_entry_text_i2')), findsOneWidget);
    });

    testWidgets('a link source is plain selectable text; tapping it opens '
        'nothing', (tester) async {
      final group = store.addGroup('group a', id: 'ga');
      store.addItem(
        text: 'entry text 1',
        source: 'https://example.test/a/b?c=d',
        groupIds: [group.groupId],
        id: 'i1',
      );
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      final source = tester.widget<SelectableText>(
        find.byKey(const Key('my_adhkar_entry_source_i1')),
      );
      expect(source.data, 'https://example.test/a/b?c=d');
      expect(source.textDirection, TextDirection.ltr);
      await tester.tap(find.byKey(const Key('my_adhkar_entry_source_i1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('my_adhkar_entry_i1')), findsOneWidget);
      expect(find.text('home page'), findsNothing);
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('url_launcher')));
    });

    testWidgets('the direction comes from the text itself, so mixed '
        'Arabic and Latin text stays readable', (tester) async {
      final group = store.addGroup('group a', id: 'ga');
      store.addItem(
        text: 'نص تجريبي with Latin words',
        source: 'Book Title - كتاب',
        groupIds: [group.groupId],
        id: 'arabicFirst',
      );
      store.addItem(
        text: 'Latin first then نص تجريبي',
        source: 'مصدر تجريبي',
        groupIds: [group.groupId],
        id: 'latinFirst',
      );
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      TextDirection? dir(String key) =>
          tester.widget<SelectableText>(find.byKey(Key(key))).textDirection;
      expect(dir('my_adhkar_entry_text_arabicFirst'), TextDirection.rtl);
      expect(dir('my_adhkar_entry_source_arabicFirst'), TextDirection.ltr);
      expect(dir('my_adhkar_entry_text_latinFirst'), TextDirection.ltr);
      expect(dir('my_adhkar_entry_source_latinFirst'), TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an entry in other groups names them', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      expect(
        find.byKey(const Key('my_adhkar_entry_other_groups_i1')),
        findsNothing,
      );
      expect(find.text('Also in: group b'), findsOneWidget);
    });

    testWidgets('Copy puts the text and the source on the clipboard', (
      tester,
    ) async {
      seedGroupWithEntries();
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      await pickMenu(tester, 'my_adhkar_entry_menu_i1', 'Copy');
      expect(copied, 'entry text 1\nsource 1');
      expect(
        find.byKey(const Key('my_adhkar_copied_toast')),
        findsOneWidget,
        reason: 'the copy toast',
      );
      expect(find.text('Copied'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('my_adhkar_copied_toast')), findsNothing);
      await pickMenu(tester, 'my_adhkar_entry_menu_i2', 'Copy');
      expect(copied, 'entry text 2', reason: 'no source, no second line');
    });

    testWidgets('entry delete asks in the page and says it leaves all its '
        'groups', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      await pickMenu(tester, 'my_adhkar_entry_menu_i2', 'Delete');
      expect(
        find.byKey(const Key('my_adhkar_entry_delete_confirmation_i2')),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('from all its groups'), findsOneWidget);
      expect(
        find.byKey(const Key('my_adhkar_entry_i2')),
        findsNothing,
        reason: 'the card turns into the confirmation, in place',
      );
      await tapKey(tester, 'my_adhkar_entry_delete_cancel');
      expect(find.byKey(const Key('my_adhkar_entry_i2')), findsOneWidget);

      await pickMenu(tester, 'my_adhkar_entry_menu_i2', 'Delete');
      await tapKey(tester, 'my_adhkar_entry_delete_confirm');
      expect(find.byKey(const Key('my_adhkar_entry_i2')), findsNothing);
      expect(store.items.map((i) => i.itemId), ['i1']);
    });
  });

  group('add and edit form', () {
    testWidgets('Save stays disabled until the text is valid; the opened '
        'group is preselected', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      await tapKey(tester, 'my_adhkar_add_entry');
      expect(find.byKey(const Key('my_adhkar_entry_form')), findsOneWidget);
      expect(find.text('A book, a scholar or a link'), findsOneWidget);
      expect(find.text('0 / 2000'), findsOneWidget);
      expect(find.text('0 / 500'), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const Key('my_adhkar_group_chip_ga')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const Key('my_adhkar_group_chip_gb')),
            )
            .selected,
        isFalse,
      );
      FilledButton save() => tester.widget<FilledButton>(
        find.byKey(const Key('my_adhkar_entry_save')),
      );
      expect(save().onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('my_adhkar_text_field')),
        '   ',
      );
      await tester.pump();
      expect(save().onPressed, isNull, reason: 'whitespace is not text');
      expect(find.text('Enter text of 1 to 2000 characters.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('my_adhkar_text_field')),
        'new entry text',
      );
      await tester.pump();
      expect(save().onPressed, isNotNull);
      await tester.enterText(
        find.byKey(const Key('my_adhkar_source_field')),
        'new source',
      );
      await tester.pump();
      await tapKey(tester, 'my_adhkar_entry_save');
      expect(find.byKey(const Key('my_adhkar_entry_form')), findsNothing);
      expect(find.text('new entry text'), findsOneWidget);
      expect(find.text('new source'), findsOneWidget);
      expect(store.items.last.groupIds, ['ga']);
    });

    testWidgets('no group selected disables Save with the inline error', (
      tester,
    ) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      await tapKey(tester, 'my_adhkar_add_entry');
      await tester.enterText(
        find.byKey(const Key('my_adhkar_text_field')),
        'new entry text',
      );
      await tester.pump();
      await tapKey(tester, 'my_adhkar_group_chip_ga');
      expect(
        find.byKey(const Key('my_adhkar_group_set_error')),
        findsOneWidget,
      );
      expect(find.text('Choose at least one group.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('my_adhkar_entry_save')))
            .onPressed,
        isNull,
      );
      await tapKey(tester, 'my_adhkar_group_chip_gb');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('my_adhkar_entry_save')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('text over 2000 and a source over 500 show inline errors; '
        'lengths count code points, not graphemes', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      await tapKey(tester, 'my_adhkar_add_entry');
      // 1001 letters each with a combining mark: 1001 graphemes, 2002 code
      // points. A grapheme-based limit would let this through.
      final marked = List.filled(1001, 'بَ').join();
      await tester.enterText(
        find.byKey(const Key('my_adhkar_text_field')),
        marked,
      );
      await tester.pump();
      expect(find.text('2002 / 2000'), findsOneWidget);
      expect(find.text('Enter text of 1 to 2000 characters.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('my_adhkar_source_field')),
        's' * 501,
      );
      await tester.pump();
      expect(find.text('501 / 500'), findsOneWidget);
      expect(
        find.text('The source can have at most 500 characters.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('my_adhkar_entry_save')))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const Key('my_adhkar_text_field')),
        'short text',
      );
      await tester.enterText(
        find.byKey(const Key('my_adhkar_source_field')),
        '',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('my_adhkar_entry_save')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('editing preselects the entry\'s groups and one entry shows '
        'in both groups after adding a group', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      await pickMenu(tester, 'my_adhkar_entry_menu_i1', 'Edit');
      expect(find.text('Edit dhikr or dua'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('my_adhkar_text_field')))
            .controller!
            .text,
        'entry text 1',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('my_adhkar_source_field')))
            .controller!
            .text,
        'source 1',
      );
      await tester.enterText(
        find.byKey(const Key('my_adhkar_text_field')),
        'entry text 1 edited',
      );
      await tapKey(tester, 'my_adhkar_group_chip_gb');
      await tapKey(tester, 'my_adhkar_entry_save');
      expect(find.text('entry text 1 edited'), findsOneWidget);
      expect(find.text('Also in: group b'), findsNWidgets(2));
      await tapKey(tester, 'my_adhkar_back_to_groups');
      await tapKey(tester, 'my_adhkar_group_gb');
      expect(find.text('entry text 1 edited'), findsOneWidget);
    });

    testWidgets('a rejected save shows the typed reason inline and keeps '
        'the form open', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester);
      await tapKey(tester, 'my_adhkar_group_ga');
      await tapKey(tester, 'my_adhkar_add_entry');
      await tester.enterText(
        find.byKey(const Key('my_adhkar_text_field')),
        'new entry text',
      );
      await tester.pump();
      store.rejectNextWith = const MyAdhkarGroupDeleted(cascadedEntries: 0);
      await tapKey(tester, 'my_adhkar_entry_save');
      expect(find.byKey(const Key('my_adhkar_entry_form')), findsOneWidget);
      expect(find.text('That group was deleted.'), findsOneWidget);
    });

    testWidgets('the forms open as a bottom sheet on a phone', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester, size: const Size(400, 900));
      await tapKey(tester, 'my_adhkar_create_group');
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('the forms open as a dialog on a wide window', (tester) async {
      seedGroupWithEntries();
      await pumpTab(tester, size: const Size(1100, 900));
      await tapKey(tester, 'my_adhkar_create_group');
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('layout matrix: AR/EN, light/dark, 320 px, 200% text', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      for (final brightness in Brightness.values) {
        for (final narrow in [true, false]) {
          testWidgets('${locale.languageCode} ${brightness.name} '
              '${narrow ? '320 px at 200%' : '900 px at 100%'}: no overflow', (
            tester,
          ) async {
            final group = store.addGroup(
              'مجموعة بعنوان طويل جدا يلتف على أكثر من سطر في الشاشة',
              id: 'ga',
            );
            final other = store.addGroup(
              'a long group name in English that wraps on a narrow screen',
              id: 'gb',
            );
            store.addItem(
              text: 'نص تجريبي طويل ${'يتكرر ' * 40}with some Latin words',
              source: 'https://example.test/a/very/long/link/${'a' * 120}',
              groupIds: [group.groupId, other.groupId],
              id: 'i1',
            );
            store.addItem(
              text: 'entry without a source',
              groupIds: [group.groupId],
              id: 'i2',
            );
            await pumpTab(
              tester,
              locale: locale,
              brightness: brightness,
              size: narrow ? const Size(320, 640) : const Size(900, 900),
              textScale: narrow ? 2.0 : 1.0,
            );
            expect(tester.takeException(), isNull, reason: 'group list');

            // The group delete confirmation.
            await pickMenu(
              tester,
              'my_adhkar_group_menu_ga',
              locale.languageCode == 'ar' ? 'حذف' : 'Delete',
            );
            expect(tester.takeException(), isNull, reason: 'confirmation');
            await tapKey(tester, 'my_adhkar_group_delete_cancel');

            // The create / rename form.
            await tapKey(tester, 'my_adhkar_create_group');
            expect(tester.takeException(), isNull, reason: 'group form');
            await tapKey(tester, 'my_adhkar_group_cancel');

            // The opened group with its entries.
            await tapKey(tester, 'my_adhkar_group_ga');
            expect(tester.takeException(), isNull, reason: 'opened group');
            expect(find.byKey(const Key('my_adhkar_entry_i1')), findsOneWidget);

            // The entry delete confirmation, then the add and edit forms.
            await pickMenu(
              tester,
              'my_adhkar_entry_menu_i1',
              locale.languageCode == 'ar' ? 'حذف' : 'Delete',
            );
            expect(tester.takeException(), isNull, reason: 'entry confirm');
            await tapKey(tester, 'my_adhkar_entry_delete_cancel');
            await tapKey(tester, 'my_adhkar_add_entry');
            expect(tester.takeException(), isNull, reason: 'add form');
            await tapKey(tester, 'my_adhkar_entry_cancel');
            await pickMenu(
              tester,
              'my_adhkar_entry_menu_i1',
              locale.languageCode == 'ar' ? 'تعديل' : 'Edit',
            );
            expect(tester.takeException(), isNull, reason: 'edit form');
            await tapKey(tester, 'my_adhkar_entry_cancel');
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}
