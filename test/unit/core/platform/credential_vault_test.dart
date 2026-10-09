import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';

/// A secure store that fails with an error message containing a fake secret;
/// used to prove the vault never echoes secret material into failures.
class LeakingSecureKeyValueStore implements SecureKeyValueStore {
  static const fakeSecret = 'super-secret-db-key';

  @override
  Future<String?> read(String key) async =>
      throw Exception('read failed for $key with $fakeSecret');

  @override
  Future<void> write(String key, String value) async =>
      throw Exception('write failed with $fakeSecret');

  @override
  Future<void> delete(String key) async => throw Exception('delete failed');
}

void main() {
  group('SecureCredentialVault round trip', () {
    test('write then read returns the secret', () async {
      final store = InMemorySecureKeyValueStore();
      final vault = SecureCredentialVault(store: store);

      final write = await vault.writeSecret('db-key', 'k1');
      expect(write.failureOrNull, isNull);
      final read = await vault.readSecret('db-key');
      expect(read.valueOrNull, 'k1');
      // The secret material only ever reached the secure store.
      expect(await store.read('db-key'), 'k1');
    });

    test('absence is a controlled success, not a failure', () async {
      final vault = SecureCredentialVault(store: InMemorySecureKeyValueStore());
      final read = await vault.readSecret('missing-key');
      expect(read.valueOrNull, isNull);
      expect(read.failureOrNull, isNull);
    });

    test('delete removes the secret durably', () async {
      final store = InMemorySecureKeyValueStore();
      final vault = SecureCredentialVault(store: store);
      await vault.writeSecret('db-key', 'k1');
      await vault.deleteSecret('db-key');
      expect((await vault.readSecret('db-key')).valueOrNull, isNull);
    });
  });

  group('secret containment', () {
    test('failures never carry secret material in their cause', () async {
      final vault = SecureCredentialVault(store: LeakingSecureKeyValueStore());
      final read = await vault.readSecret('db-key');
      final failure = read.failureOrNull;
      expect(failure, isNotNull);
      expect(failure!.technicalCause, isNull);
      expect(
        failure.toString(),
        isNot(contains(LeakingSecureKeyValueStore.fakeSecret)),
      );
      // And the write path behaves the same.
      final write = await vault.writeSecret('db-key', 'x');
      expect(
        write.failureOrNull.toString(),
        isNot(contains(LeakingSecureKeyValueStore.fakeSecret)),
      );
    });
  });
}
