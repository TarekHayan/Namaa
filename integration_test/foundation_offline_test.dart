import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/drift_local_store.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';

/// Offline persistence across ten consecutive restarts (T025).
///
/// The test device must run this with `flutter test integration_test`. The
/// database is closed and reopened between every commit to prove durability
/// without any network.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const tenRestarts = 10;

  testWidgets('a Foundation record survives ten offline restarts', (
    tester,
  ) async {
    final vault = SecureCredentialVault(store: InMemorySecureKeyValueStore());
    final key = await resolveDatabaseKey(vault);
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'namaa_foundation_offline_',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final path = [
      temporaryDirectory.path,
      'foundation_offline_probe.db',
    ].join(Platform.pathSeparator);

    Future<DriftLocalStore> openStore() async {
      final db = await FoundationDatabase.openEncrypted(path: path, key: key);
      return DriftLocalStore(db);
    }

    var store = await openStore();
    for (var restart = 1; restart <= tenRestarts; restart++) {
      await store.commitLocalChange(
        LocalRecordChange(
          recordId: 'probe-$restart',
          accountId: 'account-1',
          payload: 'offline payload $restart',
          versionTimestamp: DateTime.now().toUtc(),
        ),
        PendingChangeRequest(
          operationId: 'op-$restart',
          accountId: 'account-1',
          entityType: 'foundation_record',
          entityId: 'probe-$restart',
          kind: ChangeKind.create,
          serializedChange: 'offline payload $restart',
          createdAt: DateTime.now().toUtc(),
          versionTimestamp: DateTime.now().toUtc(),
        ),
      );
      await store.database.close();

      // Restart: reopen and verify every prior record is still present.
      store = await openStore();
      for (var prior = 1; prior <= restart; prior++) {
        final count = await store.database.localRecordCount('probe-$prior');
        expect(count, 1, reason: 'probe-$prior lost at restart $restart');
      }
    }
    await store.database.close();
  });
}
