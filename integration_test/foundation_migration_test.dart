import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';

/// Encrypted migration/recovery integration coverage (T027).
///
/// The test device must run this with `flutter test integration_test`.
/// Proves: a schema upgrade preserves encrypted data, an injected migration
/// failure retains prior data and records a visible journal outcome, and a
/// subsequent clean upgrade marks the attempt recovered.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('upgrade preserves data; failure retains and recovers', (
    tester,
  ) async {
    final vault = SecureCredentialVault(store: InMemorySecureKeyValueStore());
    final key = await resolveDatabaseKey(vault);
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'namaa_foundation_migration_',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final path = [
      temporaryDirectory.path,
      'foundation_migration_probe.db',
    ].join(Platform.pathSeparator);

    // v1: store a record.
    final v1 = await FoundationDatabase.openEncrypted(
      path: path,
      key: key,
      schemaVersion: 1,
    );
    await v1.rawExecute(
      '''INSERT INTO foundation_preferences ("key", value, updated_at)
VALUES ('locale', 'ar', '2026-09-06T00:00:00.000Z')''',
    );
    await v1.close();

    // Injected failure: prior data must be retained.
    await expectLater(
      FoundationDatabase.openEncrypted(
        path: path,
        key: key,
        testMigrationHook: (migrator, from, to) async =>
            throw Exception('injected'),
      ),
      throwsA(
        isA<AppFailure>()
            .having((f) => f.category, 'category', AppFailureCategory.migration)
            .having((f) => f.recoverable, 'recoverable', isTrue),
      ),
    );

    // Failure outcome is visible in the journal; data is intact.
    final reopened = await FoundationDatabase.openEncrypted(
      path: path,
      key: key,
      schemaVersion: 1,
    );
    expect(
      await reopened.rawScalar('SELECT value FROM foundation_preferences'),
      'ar',
    );
    expect(
      await reopened.rawScalar(
        "SELECT count(*) FROM migration_journal WHERE status = 'failed'",
      ),
      1,
    );
    await reopened.close();

    // Clean upgrade: data preserved and the failed attempt recovered.
    final current = await FoundationDatabase.openEncrypted(
      path: path,
      key: key,
    );
    expect(
      await current.rawScalar('SELECT value FROM foundation_preferences'),
      'ar',
    );
    expect(
      await current.journalStatusFor(kFoundationSchemaVersion),
      'recovered',
    );
    await current.close();
  });
}
