/// Supabase Auth session adapter behind the Cloud Session port.
///
/// Lives only in the data/cloud boundary; Supabase SDK types never cross the
/// port. This contract defines no authentication UI or account workflow
/// (contracts/application-boundaries.md).
library;

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Message key for cloud session failures (Arabic and English resources exist).
const String kCloudSessionRecoverableMessageKey =
    'foundation.cloud.recoverable';

/// The narrow Supabase surface the session adapter needs.
///
/// Dependency inversion keeps adapter logic testable without the SDK.
abstract interface class SupabaseAuthGateway {
  Session? get currentSession;

  Stream<AuthState> get authStateChanges;
}

/// Gateway over a real [SupabaseClient].
class SupabaseAuthGatewayImpl implements SupabaseAuthGateway {
  SupabaseAuthGatewayImpl(this._client);

  final SupabaseClient _client;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}

/// Cloud Session implementation over Supabase Auth.
class SupabaseSessionAdapter implements CloudSessionPort {
  SupabaseSessionAdapter({required SupabaseAuthGateway gateway})
    : _gateway = gateway;

  final SupabaseAuthGateway _gateway;

  @override
  Future<AppResult<void>> initialize() async {
    try {
      // Restores any persisted session; no network call is required here.
      _gateway.currentSession;
      return AppResult<void>.success(null);
    } catch (_) {
      return AppResult<void>.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.cloud,
          messageKey: kCloudSessionRecoverableMessageKey,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  @override
  Stream<CloudSessionSnapshot> observeSession() =>
      _gateway.authStateChanges.map(_snapshotFrom);

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async {
    final session = _gateway.currentSession;
    final accountId = session?.user.id;
    if (accountId == null || accountId.isEmpty) {
      return AppResult<CloudSyncContext>.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.cloud,
          messageKey: kCloudSessionRecoverableMessageKey,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    }
    return AppResult<CloudSyncContext>.success(
      CloudSyncContext(accountId: accountId),
    );
  }

  CloudSessionSnapshot _snapshotFrom(AuthState state) {
    final event = state.event;
    final session = state.session;
    if (event == AuthChangeEvent.signedOut) {
      return const CloudSessionSnapshot(status: CloudSessionStatus.signedOut);
    }
    if (session?.user.id != null) {
      return CloudSessionSnapshot(
        status: CloudSessionStatus.signedIn,
        accountId: session!.user.id,
      );
    }
    return const CloudSessionSnapshot(status: CloudSessionStatus.unknown);
  }
}
