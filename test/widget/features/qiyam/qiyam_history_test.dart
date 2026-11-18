import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/app/theme/app_theme.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_state.dart';
import 'package:namma_project/features/qiyam/presentation/widgets/qiyam_history_section.dart';

import '../../../support/qiyam_test_support.dart';

/// T054/T107: the history section on its own (the screen tests cover it in
/// place): newest first and read-only, the four night forms and never
/// "missed", "Load more" and the failure with its retry, a tap opening the
/// night, and the AR/EN, light/dark, 320 px at 200% matrix.
void main() {
  List<QiyamHistoryEntry> page() => [
    QiyamHistoryEntry(
      nightDate: '2026-11-10',
      record: qiyamRecord('2026-11-10'),
    ),
    QiyamHistoryEntry(
      nightDate: '2026-11-09',
      record: qiyamRecord('2026-11-09', rakahs: 2, witr: false),
    ),
    QiyamHistoryEntry(
      nightDate: '2026-11-08',
      record: qiyamRecord('2026-11-08', performed: false),
    ),
    const QiyamHistoryEntry(nightDate: '2026-11-07'),
  ];

  Future<void> pumpSection(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
    Size size = const Size(390, 1200),
    double textScale = 1,
    List<QiyamHistoryEntry>? entries,
    bool loading = false,
    bool failed = false,
    bool complete = false,
    VoidCallback? onLoadMore,
    ValueChanged<QiyamHistoryEntry>? onOpenNight,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: QiyamHistorySection(
                copy: QiyamStrings(FoundationLocalizations.of(context)),
                locale: locale.languageCode,
                entries: entries ?? page(),
                loading: loading,
                failed: failed,
                complete: complete,
                onLoadMore: onLoadMore ?? () {},
                onOpenNight: onOpenNight ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder key(String value) => find.byKey(Key(value));

  testWidgets('entries render newest first with their four forms', (
    tester,
  ) async {
    await pumpSection(tester);
    expect(find.text('Previous nights'), findsOneWidget);
    final prayed = tester.getTopLeft(
      find.text('Prayed · 4 rak’ahs · with Witr'),
    );
    final two = tester.getTopLeft(find.text('Prayed · 2 rak’ahs'));
    final no = tester.getTopLeft(find.text('Did not pray'));
    final none = tester.getTopLeft(find.text('Not recorded'));
    expect(prayed.dy, lessThan(two.dy), reason: 'newest first');
    expect(two.dy, lessThan(no.dy));
    expect(no.dy, lessThan(none.dy));
  });

  testWidgets('the word "missed" never appears, in English or Arabic', (
    tester,
  ) async {
    await pumpSection(tester);
    expect(find.textContaining('issed'), findsNothing);
    await pumpSection(tester, locale: const Locale('ar'));
    expect(find.textContaining('فات'), findsNothing);
    expect(find.text('لم يصلِّ'), findsOneWidget);
    expect(find.text('غير مسجَّل'), findsOneWidget);
  });

  testWidgets('the history is read-only: no field or edit control', (
    tester,
  ) async {
    await pumpSection(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('a tap opens that night', (tester) async {
    final opened = <String>[];
    await pumpSection(
      tester,
      onOpenNight: (entry) => opened.add(entry.nightDate),
    );
    await tester.tap(key('qiyam_history_row_2026-11-09'));
    await tester.tap(key('qiyam_history_row_2026-11-07'));
    expect(opened, ['2026-11-09', '2026-11-07']);
  });

  testWidgets('each row is a button announced with its date and state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpSection(tester);
    expect(
      find.bySemanticsLabel(RegExp(r'Tuesday, November 10, .*Prayed')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('"Load more" asks for the next page and goes away at the '
      'end', (tester) async {
    var calls = 0;
    await pumpSection(tester, onLoadMore: () => calls++);
    expect(key('qiyam_load_more'), findsOneWidget);
    await tester.tap(key('qiyam_load_more'));
    expect(calls, 1);
    await pumpSection(tester, complete: true, onLoadMore: () => calls++);
    expect(key('qiyam_load_more'), findsNothing);
  });

  testWidgets('loading shows a spinner instead of the button', (tester) async {
    await pumpSection(tester, loading: true);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(key('qiyam_load_more'), findsNothing);
  });

  testWidgets('a failed page shows the message and Try again, keeping the '
      'rows already loaded', (tester) async {
    var retries = 0;
    await pumpSection(tester, failed: true, onLoadMore: () => retries++);
    expect(find.text('Could not load previous nights.'), findsOneWidget);
    expect(find.text('Did not pray'), findsOneWidget);
    await tester.tap(key('qiyam_history_retry'));
    expect(retries, 1);
  });

  testWidgets('a failed first page shows only the failure', (tester) async {
    await pumpSection(tester, entries: const [], failed: true);
    expect(key('qiyam_history_failed'), findsOneWidget);
    expect(find.text('Previous nights'), findsOneWidget);
  });

  testWidgets('nothing recorded yet renders nothing', (tester) async {
    await pumpSection(tester, entries: const [], complete: true);
    expect(find.text('Previous nights'), findsNothing);
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final brightness in Brightness.values) {
      testWidgets('no overflow at 320 px and 200% - $locale $brightness', (
        tester,
      ) async {
        await pumpSection(
          tester,
          locale: locale,
          brightness: brightness,
          size: const Size(320, 900),
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        await pumpSection(
          tester,
          locale: locale,
          brightness: brightness,
          size: const Size(320, 900),
          textScale: 2,
          failed: true,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
