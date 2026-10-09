/// Supabase environment configuration and client factory.
///
/// Boundary rules (contracts/supabase-security.md): the client contains a
/// publishable key only — never a secret or service-role key; automated
/// tests use only the local stack; device integration uses an isolated
/// non-production project; production is not a selectable value.
library;

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Base URL of the local Supabase stack (supabase/config.toml).
const String kSupabaseLocalStackUrl = 'http://127.0.0.1:54321';

/// Placeholder publishable key for local-stack runs before the real key is
/// injected from `supabase start` output (NAMAA_LOCAL_SUPABASE_PUBLISHABLE_
/// KEY). It is not a production credential; cloud operations against the
/// real stack fail recoverably until the operator injects the actual key.
const String kLocalStackFallbackKey = 'sb_publishable_local-demo-not-a-secret';

/// The Supabase targets the client may be configured for. Production is
/// deliberately absent: no code path can select it.
enum SupabaseTargetEnvironment { localStack, isolatedNonProduction }

/// Thrown when a Supabase configuration violates the boundary contract.
class ConfigurationError extends Error {
  ConfigurationError(this.message);

  final String message;

  @override
  String toString() => 'ConfigurationError: $message';
}

/// Checks whether a host string indicates a production Supabase project or environment.
bool isProductionHost(String host) {
  final lower = host.toLowerCase().trim();
  if (lower == 'supabase.co' ||
      lower.startsWith('prod.') ||
      lower.contains('.prod.') ||
      lower.endsWith('.prod') ||
      lower.contains('-prod.') ||
      lower.contains('production')) {
    return true;
  }
  return false;
}

/// Checks whether an HTTPS host is an approved non-production Supabase target.
///
/// An arbitrary HTTPS URL is never accepted. The host must either:
/// 1. Be in [approvedHosts] (if provided), or
/// 2. Match the operator allow-list injected via `NAMAA_APPROVED_NON_PRODUCTION_HOSTS`.
bool isApprovedNonProductionHost(String host, {Set<String>? approvedHosts}) {
  final lower = host.toLowerCase().trim();
  if (isProductionHost(lower)) {
    return false;
  }

  // 1. Explicit allow-list passed by caller
  if (approvedHosts != null &&
      approvedHosts.map((h) => h.toLowerCase()).contains(lower)) {
    return true;
  }

  // 2. Operator-injected allow-list
  const operatorAllowList = String.fromEnvironment(
    'NAMAA_APPROVED_NON_PRODUCTION_HOSTS',
  );
  if (operatorAllowList.isNotEmpty) {
    final allowed = operatorAllowList
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty);
    if (allowed.contains(lower)) {
      return true;
    }
  }

  return false;
}

/// Validated Supabase environment configuration.
class SupabaseEnvironmentConfig {
  SupabaseEnvironmentConfig._({
    required this.url,
    required this.publishableKey,
    required this.target,
  });

  /// Local-stack configuration; the URL must be loopback so automated tests
  /// can never reach a hosted project.
  factory SupabaseEnvironmentConfig.localStack({
    Uri? url,
    required String publishableKey,
  }) {
    final resolved = url ?? Uri.parse(kSupabaseLocalStackUrl);
    final host = resolved.host.toLowerCase();
    final isLoopback =
        host == 'localhost' || host == '127.0.0.1' || host == '::1';
    if (!isLoopback) {
      throw ConfigurationError(
        'localStack requires a loopback host, got "$host"',
      );
    }
    _requirePublishableKey(publishableKey);
    return SupabaseEnvironmentConfig._(
      url: resolved,
      publishableKey: publishableKey,
      target: SupabaseTargetEnvironment.localStack,
    );
  }

  /// Isolated non-production configuration for device integration; the URL
  /// and publishable key are injected by the operator, never committed.
  ///
  /// Rejects production URLs and arbitrary HTTPS endpoints. Requires an approved
  /// non-production host or explicit [approvedHosts] allow-list.
  factory SupabaseEnvironmentConfig.isolatedNonProduction({
    Uri? url,
    String? publishableKey,
    Set<String>? approvedHosts,
  }) {
    final String? operatorUrl = _operatorUrl.isEmpty ? null : _operatorUrl;
    final resolved =
        url ?? (operatorUrl == null ? null : Uri.tryParse(operatorUrl));
    final String? operatorKey = _operatorKey.isEmpty ? null : _operatorKey;
    final key = publishableKey ?? operatorKey;
    if (resolved == null ||
        resolved.host.isEmpty ||
        !resolved.isScheme('https')) {
      throw ConfigurationError(
        'isolatedNonProduction requires an injected https URL '
        '(NAMAA_SUPABASE_URL)',
      );
    }
    if (isProductionHost(resolved.host)) {
      throw ConfigurationError(
        'production Supabase URLs are strictly rejected: ${resolved.host}',
      );
    }
    if (!isApprovedNonProductionHost(
      resolved.host,
      approvedHosts: approvedHosts,
    )) {
      throw ConfigurationError(
        'URL "${resolved.toString()}" is not an approved non-production endpoint',
      );
    }
    if (key == null || key.isEmpty) {
      throw ConfigurationError(
        'isolatedNonProduction requires an injected publishable key '
        '(NAMAA_SUPABASE_PUBLISHABLE_KEY)',
      );
    }
    _requirePublishableKey(key);
    return SupabaseEnvironmentConfig._(
      url: resolved,
      publishableKey: key,
      target: SupabaseTargetEnvironment.isolatedNonProduction,
    );
  }

  static const String _operatorUrl = String.fromEnvironment(
    'NAMAA_SUPABASE_URL',
  );
  static const String _operatorKey = String.fromEnvironment(
    'NAMAA_SUPABASE_PUBLISHABLE_KEY',
  );

  final Uri url;
  final String publishableKey;
  final SupabaseTargetEnvironment target;
}

/// Rejects anything that is not publishable-key material.
void _requirePublishableKey(String key) {
  if (key.isEmpty) {
    throw ConfigurationError('the publishable key must not be empty');
  }
  if (key.startsWith('sb_secret_')) {
    throw ConfigurationError('secret keys are server-side only');
  }
  if (key.contains('service_role')) {
    throw ConfigurationError('service-role key material is forbidden');
  }
  // Legacy JWT-shaped keys carry a role claim; a service_role claim is
  // forbidden even when the literal string is base64-encoded.
  for (final segment in key.split('.')) {
    final decoded = _tryBase64Json(segment);
    if (decoded != null && decoded.contains('service_role')) {
      throw ConfigurationError('service-role key material is forbidden');
    }
  }
}

String? _tryBase64Json(String segment) {
  try {
    final normalized = base64Url.normalize(segment);
    return utf8.decode(base64Url.decode(normalized), allowMalformed: true);
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}

/// Creates a stateless Supabase client from a validated configuration.
///
/// This is for isolated boundary tests only. Application composition uses the
/// persistent factory below so credentials never fall back to preferences.
SupabaseClient createSupabaseClient(SupabaseEnvironmentConfig config) {
  _validateClientConfiguration(config);
  // This deliberately stateless client is reserved for isolated boundary
  // tests. Device application composition must use
  // [createPersistentSupabaseClient] below.
  return SupabaseClient(config.url.toString(), config.publishableKey);
}

/// Creates the application client with session and PKCE storage supplied by
/// the composition root. The caller must provide OS-protected stores; no
/// SharedPreferences fallback is permitted for credential material.
Future<SupabaseClient> createPersistentSupabaseClient(
  SupabaseEnvironmentConfig config, {
  required LocalStorage sessionStorage,
  required GotrueAsyncStorage pkceStorage,
}) async {
  _validateClientConfiguration(config);
  final supabase = await Supabase.initialize(
    url: config.url.toString(),
    publishableKey: config.publishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: sessionStorage,
      pkceAsyncStorage: pkceStorage,
      // Foundation defines no authentication deep-link flow yet. Session
      // restoration remains enabled, while URI detection is deferred to the
      // future Auth feature that owns that product behavior.
      detectSessionInUri: false,
    ),
  );
  return supabase.client;
}

void _validateClientConfiguration(SupabaseEnvironmentConfig config) {
  _requirePublishableKey(config.publishableKey);
  if (isProductionHost(config.url.host)) {
    throw ConfigurationError(
      'refusing to create Supabase client for production endpoint: ${config.url}',
    );
  }
  if (config.target == SupabaseTargetEnvironment.localStack) {
    final host = config.url.host.toLowerCase();
    final isLoopback =
        host == 'localhost' || host == '127.0.0.1' || host == '::1';
    if (!isLoopback) {
      throw ConfigurationError(
        'localStack requires a loopback host, got "$host"',
      );
    }
  }
}
