import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('device preview supplies a phone-sized MediaQuery', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      DevicePreview(
        storage: DevicePreviewStorage.none(),
        builder: (_) => const _PreviewApp(),
      ),
    );
    // DevicePreview keeps an animation active, so settling never completes.
    await tester.pump();

    final previewContext = tester.element(
      find.byKey(const Key('preview_content')),
    );
    final size = MediaQuery.sizeOf(previewContext);
    expect(size.width, lessThan(600));
    expect(size.height, greaterThan(600));
    expect(tester.takeException(), isNull);
  });
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    builder: DevicePreview.appBuilder,
    home: const Scaffold(body: SizedBox(key: Key('preview_content'))),
  );
}
