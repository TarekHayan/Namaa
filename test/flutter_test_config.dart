import 'dart:async';

import 'package:namma_project/app/theme/app_digits.dart';

/// Every widget and unit test runs with the app's digit setting: Latin
/// digits in every language (owner decision, 2026-11-18), as
/// `configureDependencies` sets it at startup.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  useLatinDigits();
  await testMain();
}
