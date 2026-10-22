import 'package:flutter_test/flutter_test.dart';

/// Establishes the native accessibility state before testWidgets records its
/// handle baseline. XCTest can otherwise enable it midway through the first
/// test, which looks like a leaked test handle to Flutter's end checks.
/// Per-test semantics handles still have to be disposed normally.
void stabilizeNativeIosSemantics(TestWidgetsFlutterBinding binding) {
  binding.platformDispatcher.semanticsEnabledTestValue = true;
  tearDownAll(binding.platformDispatcher.clearSemanticsEnabledTestValue);
}
