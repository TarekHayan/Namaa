import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives the open Material time picker in dial mode (24-hour form): taps the
/// hour on its ring (the outer ring holds 00-11, the inner ring 12-23), then
/// the minute (exact to the minute), and leaves the dialog open so a test can press OK or Cancel.
Future<void> dialTime(WidgetTester tester, int hour, int minute) async {
  final dial = find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_Dial',
  );
  expect(dial, findsOneWidget, reason: 'the picker is open in dial mode');
  final rect = tester.getRect(dial);
  Offset at(double turn, double ring) {
    final angle = turn * 2 * math.pi;
    final radius = rect.width / 2 * ring;
    return rect.center +
        Offset(math.sin(angle) * radius, -math.cos(angle) * radius);
  }

  await tester.tapAt(at((hour % 12) / 12, hour >= 12 ? 0.45 : 0.8));
  await tester.pump(const Duration(milliseconds: 400));
  // A tap snaps to a multiple of five minutes; a drag reaches every minute,
  // so the minute is dragged onto its place from the next one over.
  final gesture = await tester.startGesture(at(((minute + 3) % 60) / 60, 0.8));
  await gesture.moveTo(at(((minute + 1) % 60) / 60, 0.8));
  await tester.pump();
  await gesture.moveTo(at(minute / 60, 0.8));
  await tester.pump();
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Picks [hour]:[minute] on the open dial and confirms with OK.
Future<void> pickDialTime(WidgetTester tester, int hour, int minute) async {
  await dialTime(tester, hour, minute);
  await confirmDial(tester);
}

/// Presses the dialog's OK button (the last of its two text buttons, so it
/// works in any locale).
Future<void> confirmDial(WidgetTester tester) async {
  await tester.tap(
    find
        .descendant(
          of: find.byType(TimePickerDialog),
          matching: find.byType(TextButton),
        )
        .last,
  );
  await tester.pumpAndSettle();
}

/// Presses the dialog's Cancel button (the first of its two text buttons).
Future<void> cancelDial(WidgetTester tester) async {
  await tester.tap(
    find
        .descendant(
          of: find.byType(TimePickerDialog),
          matching: find.byType(TextButton),
        )
        .first,
  );
  await tester.pumpAndSettle();
}
