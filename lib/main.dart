import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/composition/configure_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debug launches open a local trial without an account or cloud.
  // Release builds always use the real session boundary.
  const previewTasks = bool.fromEnvironment(
    'NAMAA_TASKS_PREVIEW',
    defaultValue: kDebugMode,
  );

  // Initialize the Foundation environment safely. If vault access,
  // encrypted database opening, migration, or configuration fails,
  // configureDependencies handles it safely so the app still reaches a safe
  // blocking/recoverable Foundation state rather than crashing before runApp().
  await configureDependencies(
    environment: previewTasks && !kReleaseMode
        ? FoundationEnvironment.tasksPreview
        : FoundationEnvironment.local,
  );

  final enableDevicePreview =
      !kReleaseMode &&
      const bool.fromEnvironment(
        'NAMAA_DEVICE_PREVIEW',
        defaultValue: kDebugMode,
      );

  runApp(
    DevicePreview(
      enabled: enableDevicePreview,
      builder: (context) => const FoundationApp(),
    ),
  );
}
