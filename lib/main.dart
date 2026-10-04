import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/composition/configure_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the real Foundation local environment safely. If vault access,
  // encrypted database opening, migration, or configuration fails,
  // configureDependencies handles it safely so the app still reaches a safe
  // blocking/recoverable Foundation state rather than crashing before runApp().
  await configureDependencies();

  runApp(const FoundationApp());
}
