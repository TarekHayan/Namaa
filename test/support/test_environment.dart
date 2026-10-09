/// Test-environment constants and non-production Supabase environment
/// selection shared by unit, widget, and integration tests.
///
/// Automated tests MUST never reach a production Supabase project
/// (specs/001-namaa-foundation/contracts/supabase-security.md, Environment
/// Rule). Only the local Docker-backed stack (or, for device integration, an
/// isolated non-production project) is selectable.
library;

/// Base URL of the local Supabase stack defined in `supabase/config.toml`.
const String kSupabaseLocalUrl = 'http://127.0.0.1:54321';

/// The kinds of Supabase environment the test suite may select.
enum SupabaseEnvironmentKind {
  /// Local Docker-backed stack from `supabase/config.toml` (default).
  localStack,

  /// Isolated non-production project for device integration only; its URL
  /// and publishable key are injected by the operator, never committed.
  isolatedNonProduction,

  /// Never selectable by automated tests; exists so selection can reject it.
  production,
}

/// Thrown when a test would select or connect to a production environment.
class ProductionEnvironmentRefusedError extends StateError {
  ProductionEnvironmentRefusedError([String? detail])
    : super(
        'Automated tests must never use production Supabase. '
        'Use the local stack environment (default) or the isolated '
        'non-production project for device integration.'
        '${detail == null ? '' : ' $detail'}',
      );
}

/// Resolves the Supabase environment for automated tests.
///
/// [explicit] overrides the `NAMAA_SUPABASE_ENV` compile-time constant for
/// tests that inject an environment directly. Selecting
/// [SupabaseEnvironmentKind.production] always throws
/// [ProductionEnvironmentRefusedError]; the default is the local stack.
SupabaseEnvironmentKind resolveTestSupabaseEnvironment({String? explicit}) {
  const defaultKind = SupabaseEnvironmentKind.localStack;
  final raw =
      explicit ??
      const String.fromEnvironment('NAMAA_SUPABASE_ENV', defaultValue: 'local');
  final kind = switch (raw) {
    'local' => SupabaseEnvironmentKind.localStack,
    'non-production' => SupabaseEnvironmentKind.isolatedNonProduction,
    'production' => SupabaseEnvironmentKind.production,
    _ => defaultKind,
  };
  return requireNonProduction(kind);
}

/// Guard used by every Supabase-touching test entry point.
///
/// Returns [kind] when it is safe for automated use, otherwise throws
/// [ProductionEnvironmentRefusedError].
SupabaseEnvironmentKind requireNonProduction(SupabaseEnvironmentKind kind) {
  if (kind == SupabaseEnvironmentKind.production) {
    throw ProductionEnvironmentRefusedError();
  }
  return kind;
}

/// Validates that [url] is a local-stack endpoint allowed for automated
/// tests.
///
/// Only loopback hosts are accepted; any hosted Supabase domain or unknown
/// remote host throws [ProductionEnvironmentRefusedError].
Uri requireLocalStackUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw ProductionEnvironmentRefusedError('Not a valid URL: $url');
  }
  final host = uri.host.toLowerCase();
  final isLoopback =
      host == 'localhost' || host == '127.0.0.1' || host == '::1';
  if (!isLoopback) {
    throw ProductionEnvironmentRefusedError(
      'Automated tests may only connect to the local stack, got host "$host".',
    );
  }
  return uri;
}
