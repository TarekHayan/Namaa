/// OS-protected Credential Vault adapter.
///
/// Only keys, credentials, and database key material pass through this
/// adapter; they are never logged, persisted to preferences, or serialized
/// into failure records
/// (specs/001-namaa-foundation/contracts/application-boundaries.md).
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

/// Localized message keys for vault outcomes (Arabic and English resources
/// are provided by the Foundation localization set).
const String kVaultRecoverableMessageKey = 'foundation.vault.recoverable';
const String kVaultBlockingMessageKey = 'foundation.vault.blocking';

/// The minimal OS-protected storage surface the vault needs.
///
/// Dependency inversion keeps the vault testable and lets the OS binding be
/// swapped without touching the port contract.
abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Credential Vault implementation over OS-protected storage.
///
/// Failure summaries are fixed, secret-free messages: the raw exception text
/// of an OS storage failure may itself contain secret material, so it is
/// never propagated.
class SecureCredentialVault implements CredentialVaultPort {
  SecureCredentialVault({required SecureKeyValueStore store}) : _store = store;

  final SecureKeyValueStore _store;

  @override
  Future<AppResult<String?>> readSecret(String key) async {
    try {
      return AppResult<String?>.success(await _store.read(key));
    } catch (_) {
      return AppResult<String?>.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: kVaultRecoverableMessageKey,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> writeSecret(String key, String secret) async {
    try {
      await _store.write(key, secret);
      return AppResult<void>.success(null);
    } catch (_) {
      return AppResult<void>.failure(
        AppFailure.blocking(
          category: AppFailureCategory.persistence,
          messageKey: kVaultBlockingMessageKey,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> deleteSecret(String key) async {
    try {
      await _store.delete(key);
      return AppResult<void>.success(null);
    } catch (_) {
      return AppResult<void>.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: kVaultRecoverableMessageKey,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    }
  }
}

/// OS-protected storage binding backed by `flutter_secure_storage`
/// (Android Keystore, iOS Keychain, Windows DPAPI, macOS Keychain,
/// Linux libsecret — declared for all five targets).
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Non-persistent secure store for the test environment composition and
/// deterministic tests. Never used for production configurations.
class InMemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
