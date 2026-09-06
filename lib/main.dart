import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/composition/configure_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Unconfigured until US1 wires environment-specific adapters; every port
  // resolves to a safe-fail double, so bootstrap failures surface as safe
  // startup states instead of uncaught exceptions.
  await configureDependencies();

  runApp(const FoundationApp());
}
