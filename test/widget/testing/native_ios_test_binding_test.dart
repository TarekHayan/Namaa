import 'package:flutter_test/flutter_test.dart';

import '../../support/native_ios_test_binding.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  stabilizeNativeIosSemantics(binding);

  testWidgets('native accessibility callback keeps the test handle baseline', (
    tester,
  ) async {
    final baseline = binding.debugOutstandingSemanticsHandles;
    binding.platformDispatcher.onSemanticsEnabledChanged?.call();
    expect(binding.debugOutstandingSemanticsHandles, baseline);
    expect(binding.semanticsEnabled, isTrue);

    final handle = tester.ensureSemantics();
    expect(binding.debugOutstandingSemanticsHandles, baseline + 1);
    handle.dispose();
    expect(binding.debugOutstandingSemanticsHandles, baseline);
  });
}
