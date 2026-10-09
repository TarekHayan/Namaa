/// OS-protected Supabase auth storage bindings.
///
/// Supabase's default Flutter storage uses SharedPreferences. Namaa sessions
/// and PKCE verifiers are credentials, so they are persisted only through the
/// platform secure-storage boundary instead.
library;

import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the serialized Supabase session in OS-protected storage.
class SecureSupabaseSessionStorage extends LocalStorage {
  SecureSupabaseSessionStorage({
    required SecureKeyValueStore store,
    required this.persistSessionKey,
  }) : _store = store;

  final SecureKeyValueStore _store;
  final String persistSessionKey;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      (await _store.read(persistSessionKey)) != null;

  @override
  Future<String?> accessToken() => _store.read(persistSessionKey);

  @override
  Future<void> removePersistedSession() => _store.delete(persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(persistSessionKey, persistSessionString);
}

/// Persists PKCE verifier material alongside the session in the same
/// OS-protected storage boundary.
class SecureSupabasePkceStorage extends GotrueAsyncStorage {
  SecureSupabasePkceStorage({required SecureKeyValueStore store})
    : _store = store;

  final SecureKeyValueStore _store;

  String _key(String key) => 'namaa.supabase.pkce.$key';

  @override
  Future<String?> getItem({required String key}) => _store.read(_key(key));

  @override
  Future<void> removeItem({required String key}) => _store.delete(_key(key));

  @override
  Future<void> setItem({required String key, required String value}) =>
      _store.write(_key(key), value);
}
