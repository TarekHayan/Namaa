import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_card.dart';
import 'package:namma_project/app/widgets/app_confirmation.dart';
import 'package:namma_project/app/widgets/app_sheets.dart';
import 'package:namma_project/app/widgets/app_toast.dart';

import '../../../support/shared_widget_harness.dart';

AppColors _colors(Brightness brightness) =>
    brightness == Brightness.dark ? AppColors.dark : AppColors.light;

/// A page with one button that runs [open] under the page's own context.
Widget _opener(Future<void> Function(BuildContext context) open) => Builder(
  builder: (context) => TextButton(
    key: const Key('open'),
    onPressed: () => open(context),
    child: const Text('open'),
  ),
);

Widget _formSheet({String title = 'Create group', Widget? footer}) =>
    AppFormSheet(
      panelKey: const Key('panel'),
      title: title,
      fields: const [
        TextField(key: Key('field_a')),
        TextField(key: Key('field_b')),
      ],
      footer: footer ?? const Text('footer'),
    );

void main() {
  group('showAppAdaptiveSheet', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('a phone opens a bottom sheet with a drag handle ($name)', (
        tester,
      ) async {
        final colors = _colors(brightness);
        await pumpShared(
          tester,
          _opener(
            (context) =>
                showAppAdaptiveSheet<void>(context, (_) => _formSheet()),
          ),
          brightness: brightness,
          direction: direction,
        );
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(AppSheetHandle), findsOneWidget);
        expect(find.text('Create group'), findsOneWidget);
        expect(find.text('footer'), findsOneWidget);
        final panel = tester.widget<Container>(
          find
              .descendant(
                of: find.byKey(const Key('panel')),
                matching: find.byType(Container),
              )
              .first,
        );
        final box = panel.decoration! as BoxDecoration;
        expect(box.color, colors.surface);
        expect(
          box.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(28)),
        );
        expect(box.boxShadow, colors.cardShadow);
        final barrier = tester.widget<ModalBarrier>(
          find.byType(ModalBarrier).last,
        );
        expect(barrier.color, colors.scrim);
      });

      testWidgets('a wide window opens a dialog with all corners rounded '
          '($name)', (tester) async {
        await pumpShared(
          tester,
          _opener(
            (context) =>
                showAppAdaptiveSheet<void>(context, (_) => _formSheet()),
          ),
          brightness: brightness,
          direction: direction,
          size: const Size(1100, 800),
        );
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(AppSheetHandle), findsNothing);
        expect(
          tester.getSize(find.byKey(const Key('panel'))).width,
          lessThanOrEqualTo(520),
        );
        final panel = tester.widget<Container>(
          find
              .descendant(
                of: find.byKey(const Key('panel')),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (panel.decoration! as BoxDecoration).borderRadius,
          BorderRadius.circular(28),
        );
      });
    }

    testWidgets('the sheet lifts above the keyboard and scrolls its fields', (
      tester,
    ) async {
      await pumpShared(
        tester,
        _opener(
          (context) => showAppAdaptiveSheet<void>(context, (_) => _formSheet()),
        ),
        size: const Size(400, 500),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getBottomLeft(find.byKey(const Key('panel'))).dy,
        lessThanOrEqualTo(300),
      );
    });
  });

  group('showAppBottomSheet and showAppDialog', () {
    testWidgets('use the scrim and a transparent route background', (
      tester,
    ) async {
      await pumpShared(
        tester,
        Column(
          children: [
            _opener(
              (context) => showAppBottomSheet<void>(
                context: context,
                builder: (_) => const AppSheetPanel(
                  key: Key('sheet'),
                  height: 200,
                  child: Text('sheet body'),
                ),
              ),
            ),
          ],
        ),
        brightness: Brightness.dark,
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      expect(find.text('sheet body'), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('sheet'))).height, 200);
      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.color, AppColors.dark.scrim);
    });

    testWidgets('a dialog is capped at its max width', (tester) async {
      await pumpShared(
        tester,
        _opener(
          (context) => showAppDialog<void>(
            context: context,
            maxWidth: 300,
            builder: (_) => const AppCard(key: Key('card'), child: Text('hi')),
          ),
        ),
        size: const Size(1000, 800),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('card'))).width,
        lessThanOrEqualTo(300),
      );
    });
  });

  group('showAppConfirmDialog', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('confirm resolves true, cancel resolves false ($name)', (
        tester,
      ) async {
        final colors = _colors(brightness);
        bool? result;
        await pumpShared(
          tester,
          _opener((context) async {
            result = await showAppConfirmDialog(
              context: context,
              title: 'Reset this count?',
              body: 'It returns to zero.',
              cancelLabel: 'Cancel',
              confirmLabel: 'Reset',
              panelKey: const Key('panel'),
              cancelKey: const Key('cancel'),
              confirmKey: const Key('confirm'),
            );
          }),
          brightness: brightness,
          direction: direction,
        );
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();
        expect(find.text('Reset this count?'), findsOneWidget);
        expect(find.text('It returns to zero.'), findsOneWidget);
        final panel = tester.widget<Container>(
          find
              .descendant(
                of: find.byKey(const Key('panel')),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (panel.decoration! as BoxDecoration).boxShadow,
          colors.cardShadow,
        );
        final confirm = tester.widget<FilledButton>(
          find.descendant(
            of: find.byKey(const Key('confirm')),
            matching: find.byType(FilledButton),
          ),
        );
        expect(confirm.style!.backgroundColor!.resolve({}), colors.error);
        // Cancel comes first side by side, in the reading direction.
        final cancelX = tester.getTopLeft(find.byKey(const Key('cancel'))).dx;
        final confirmX = tester.getTopLeft(find.byKey(const Key('confirm'))).dx;
        expect(
          cancelX < confirmX,
          direction == TextDirection.ltr,
          reason: 'cancel leads the row',
        );
        await tester.tap(find.byKey(const Key('cancel')));
        await tester.pumpAndSettle();
        expect(result, isFalse);
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm')));
        await tester.pumpAndSettle();
        expect(result, isTrue);
      });
    }

    testWidgets('buttons stack, confirm first, on a narrow dialog', (
      tester,
    ) async {
      await pumpShared(
        tester,
        _opener(
          (context) => showAppConfirmDialog(
            context: context,
            title: 'Title',
            body: 'Body',
            cancelLabel: 'Cancel',
            confirmLabel: 'Reset',
            cancelKey: const Key('cancel'),
            confirmKey: const Key('confirm'),
          ),
        ),
        size: const Size(280, 600),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const Key('confirm'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('cancel'))).dy),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AppButtonPair', () {
    testWidgets('side by side from the threshold, stacked below it', (
      tester,
    ) async {
      Widget pair(double width) => SizedBox(
        width: width,
        child: const AppButtonPair(
          minInlineWidth: 290,
          primary: SizedBox(key: Key('first'), height: 40),
          secondary: SizedBox(key: Key('second'), height: 40),
        ),
      );
      await pumpShared(
        tester,
        Align(alignment: Alignment.topLeft, child: pair(300)),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('first'))).dy,
        tester.getTopLeft(find.byKey(const Key('second'))).dy,
      );
      expect(tester.getSize(find.byKey(const Key('first'))).width, 145);
      await pumpShared(
        tester,
        Align(alignment: Alignment.topLeft, child: pair(280)),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('second'))).dy,
        greaterThan(tester.getTopLeft(find.byKey(const Key('first'))).dy),
      );
      expect(tester.getSize(find.byKey(const Key('first'))).width, 280);
    });
  });

  group('AppInlineConfirmation', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets('tinted card, texts and both actions ($name)', (
        tester,
      ) async {
        final colors = _colors(brightness);
        var confirmed = 0;
        var cancelled = 0;
        await pumpShared(
          tester,
          AppInlineConfirmation(
            key: const Key('confirmation'),
            title: 'Delete this group?',
            subtitle: 'Ramadan',
            body: '2 entries will be removed.',
            confirmLabel: 'Delete',
            cancelLabel: 'Cancel',
            onConfirm: () => confirmed++,
            onCancel: () => cancelled++,
            confirmKey: const Key('confirm'),
            cancelKey: const Key('cancel'),
          ),
          brightness: brightness,
          direction: direction,
        );
        final box =
            tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: find.byKey(const Key('confirmation')),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration;
        expect(box.color, colors.errorSoft);
        expect((box.border! as Border).top.color, colors.error);
        expect(find.text('Ramadan'), findsOneWidget);
        // Delete first, in the reading direction.
        final confirmX = tester.getTopLeft(find.byKey(const Key('confirm'))).dx;
        final cancelX = tester.getTopLeft(find.byKey(const Key('cancel'))).dx;
        expect(confirmX < cancelX, direction == TextDirection.ltr);
        await tester.tap(find.byKey(const Key('confirm')));
        await tester.tap(find.byKey(const Key('cancel')));
        expect(confirmed, 1);
        expect(cancelled, 1);
      });
    }

    testWidgets('busy disables both actions; the subtitle follows its text', (
      tester,
    ) async {
      await pumpShared(
        tester,
        AppInlineConfirmation(
          title: 'Delete?',
          subtitle: 'مجموعة',
          body: 'Body',
          confirmLabel: 'Delete',
          cancelLabel: 'Cancel',
          onConfirm: () {},
          onCancel: () {},
          busy: true,
          confirmKey: const Key('confirm'),
          cancelKey: const Key('cancel'),
        ),
      );
      expect(
        tester.widget<AppButton>(find.byKey(const Key('confirm'))).onPressed,
        isNull,
      );
      expect(
        tester.widget<AppButton>(find.byKey(const Key('cancel'))).onPressed,
        isNull,
      );
      expect(
        tester.widget<Text>(find.text('مجموعة')).textDirection,
        TextDirection.rtl,
      );
    });
  });

  group('AppToast', () {
    for (final (name, brightness, direction) in kSharedMatrix) {
      testWidgets(
        'shows a pill, replaces the previous one, then goes ($name)',
        (tester) async {
          final colors = _colors(brightness);
          await pumpShared(
            tester,
            Builder(
              builder: (context) => TextButton(
                key: const Key('toast'),
                onPressed: () => AppToast.of(
                  context,
                ).show('Copied', key: const Key('toast_bar')),
                child: const Text('go'),
              ),
            ),
            brightness: brightness,
            direction: direction,
          );
          await tester.tap(find.byKey(const Key('toast')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byKey(const Key('toast_bar')), findsOneWidget);
          expect(find.text('Copied'), findsOneWidget);
          final pill = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(const Key('toast_bar')),
                  matching: find.byType(Container),
                )
                .first,
          );
          final box = pill.decoration! as BoxDecoration;
          expect(box.color, colors.textPrimary);
          expect(box.borderRadius, BorderRadius.circular(999));
          expect(
            tester.widget<Icon>(find.byIcon(Icons.check_rounded)).color,
            colors.background,
          );
          await tester.tap(find.byKey(const Key('toast')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byKey(const Key('toast_bar')), findsOneWidget);
          // The entrance animation, then the two seconds, then the exit.
          await tester.pump(const Duration(seconds: 3));
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('toast_bar')), findsNothing);
        },
      );
    }

    testWidgets('outside a Scaffold messenger it does nothing', (tester) async {
      late AppToast toast;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            toast = AppToast.of(context);
            return const SizedBox();
          },
        ),
      );
      toast.show('ignored');
      expect(tester.takeException(), isNull);
    });
  });
}
