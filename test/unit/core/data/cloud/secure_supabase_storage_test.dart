import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/cloud/supabase/secure_supabase_storage.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';

void main() {
  test(
    'Supabase session storage persists only through the injected secure store',
    () async {
      final store = InMemorySecureKeyValueStore();
      final storage = SecureSupabaseSessionStorage(
        store: store,
        persistSessionKey: 'test.session',
      );

      await storage.initialize();
      expect(await storage.hasAccessToken(), isFalse);
      await storage.persistSession('serialized-session');
      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), 'serialized-session');
      await storage.removePersistedSession();
      expect(await storage.accessToken(), isNull);
    },
  );

  test(
    'Supabase PKCE verifier storage is namespaced in the secure store',
    () async {
      final store = InMemorySecureKeyValueStore();
      final storage = SecureSupabasePkceStorage(store: store);

      await storage.setItem(key: 'verifier', value: 'pkce-value');
      expect(await storage.getItem(key: 'verifier'), 'pkce-value');
      expect(await store.read('verifier'), isNull);
      await storage.removeItem(key: 'verifier');
      expect(await storage.getItem(key: 'verifier'), isNull);
    },
  );
}
