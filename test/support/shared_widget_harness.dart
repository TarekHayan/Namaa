import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The light/dark and LTR/RTL matrix every shared widget test runs over.
const List<(String, Brightness, TextDirection)> kSharedMatrix = [
  ('light ltr', Brightness.light, TextDirection.ltr),
  ('dark ltr', Brightness.dark, TextDirection.ltr),
  ('light rtl', Brightness.light, TextDirection.rtl),
  ('dark rtl', Brightness.dark, TextDirection.rtl),
];

/// Pumps [child] in a plain Material app (the same bare `ThemeData` the
/// feature widget tests use) with the given brightness and text direction.
Future<void> pumpShared(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  Size size = const Size(400, 800),
  double textScale = 1,
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
      key: UniqueKey(),
      theme: ThemeData(brightness: brightness, useMaterial3: true),
      builder: (context, app) =>
          Directionality(textDirection: direction, child: app!),
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
}
