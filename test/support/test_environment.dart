/// Test-environment constants and non-production Firebase environment
/// selection shared by unit, widget, and integration tests.
///
/// Automated tests MUST never reach a production Firebase project
/// (specs/001-namaa-foundation/contracts/synchronization.md, Environment Rule).
library;

/// Demo project ID for the Firebase Local Emulator Suite.
///
/// Firebase demo projects (IDs prefixed with `demo-`) cannot access live
/// resources, which is the safest default for automated tests.
const String kFirebaseDemoProjectId = 'demo-namaa-foundation';

/// Default Auth emulator endpoint used by automated tests.
const String kAuthEmulatorHost = 'localhost';
const int kAuthEmulatorPort = 9099;

/// Default Firestore emulator endpoint used by automated tests.
const String kFirestoreEmulatorHost = 'localhost';
const int kFirestoreEmulatorPort = 8080;

/// The kinds of Firebase environment the test suite may select.
enum FirebaseEnvironmentKind {
  /// Local Emulator Suite under [kFirebaseDemoProjectId].
  emulator,

  /// Isolated non-production project for device integration only.
  isolatedNonProduction,

  /// Never selectable by automated tests; exists so selection can reject it.
  production,
}

/// Thrown when a test would select a production Firebase environment.
class ProductionEnvironmentRefusedError extends StateError {
  ProductionEnvironmentRefusedError()
      : super(
          'Automated tests must never use production Firebase. '
          'Use the emulator environment (default) or the isolated '
          'non-production project for device integration.',
        );
}

/// Resolves the Firebase environment for automated tests.
///
/// [explicit] overrides the `NAMAA_FIREBASE_ENV` compile-time constant for
/// tests that inject an environment directly. Selecting
/// [FirebaseEnvironmentKind.production] always throws
/// [ProductionEnvironmentRefusedError]; the default is the emulator
/// environment.
FirebaseEnvironmentKind resolveTestFirebaseEnvironment({
  String? explicit,
}) {
  const defaultKind = FirebaseEnvironmentKind.emulator;
  final raw =
      explicit ?? const String.fromEnvironment('NAMAA_FIREBASE_ENV', defaultValue: 'emulator');
  final kind = switch (raw) {
    'emulator' => FirebaseEnvironmentKind.emulator,
    'non-production' => FirebaseEnvironmentKind.isolatedNonProduction,
    'production' => FirebaseEnvironmentKind.production,
    _ => defaultKind,
  };
  return requireNonProduction(kind);
}

/// Guard used by every Firebase-touching test entry point.
///
/// Returns [kind] when it is safe for automated use, otherwise throws
/// [ProductionEnvironmentRefusedError].
FirebaseEnvironmentKind requireNonProduction(FirebaseEnvironmentKind kind) {
  if (kind == FirebaseEnvironmentKind.production) {
    throw ProductionEnvironmentRefusedError();
  }
  return kind;
}
