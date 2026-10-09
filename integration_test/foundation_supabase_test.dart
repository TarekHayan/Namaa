import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_environment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../test/support/test_environment.dart';

/// Local Supabase stack and isolated non-production boundary coverage
/// (T028).
///
/// Production configuration is rejected before any connection is attempted;
/// the local stack is the only automated-test target.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('production configuration is rejected before connecting', (
    tester,
  ) async {
    // Secret key material is refused at configuration time; no client is
    // constructed and no network call happens.
    expect(
      () => SupabaseEnvironmentConfig.localStack(
        publishableKey: 'sb_secret_never-allowed',
      ),
      throwsA(isA<ConfigurationError>()),
    );
    // A hosted URL is never accepted for the local-stack target.
    expect(
      () => SupabaseEnvironmentConfig.localStack(
        url: Uri.parse('https://prod.example.supabase.co'),
        publishableKey: 'sb_publishable_abc123',
      ),
      throwsA(isA<ConfigurationError>()),
    );
    // Production URLs are strictly rejected for isolated non-production.
    expect(
      () => SupabaseEnvironmentConfig.isolatedNonProduction(
        url: Uri.parse('https://prod.example.supabase.co'),
        publishableKey: 'sb_publishable_abc123',
      ),
      throwsA(isA<ConfigurationError>()),
    );
    // Arbitrary HTTPS URLs are rejected for isolated non-production.
    expect(
      () => SupabaseEnvironmentConfig.isolatedNonProduction(
        url: Uri.parse('https://arbitrary.example.com'),
        publishableKey: 'sb_publishable_abc123',
      ),
      throwsA(isA<ConfigurationError>()),
    );
  });

  testWidgets('automated tests resolve only non-production environments', (
    tester,
  ) async {
    final environment = resolveTestSupabaseEnvironment();
    expect(
      environment,
      isNot(SupabaseEnvironmentKind.production),
      reason: 'Automated tests must never select production',
    );
  });

  testWidgets(
    'local stack is reachable and responds to a minimal safe operation',
    (tester) async {
      final uri = requireLocalStackUrl(kSupabaseLocalUrl);
      expect(uri.host, anyOf('127.0.0.1', 'localhost', '::1'));

      const injectedKey = String.fromEnvironment(
        'NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY',
      );
      if (injectedKey.isEmpty) {
        fail(
          'Missing NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY. '
          'Integration tests require the real local stack publishable key.',
        );
      }

      final config = SupabaseEnvironmentConfig.localStack(
        url: uri,
        publishableKey: injectedKey,
      );
      final client = createSupabaseClient(config);

      // Minimal safe operation against the real local stack:
      // Queries the foundation_probe table with the publishable key.
      // Verifies that the local stack is running, reachable, and enforcing
      // least-privilege grants (anon is denied access with 42501).
      try {
        await client.from('foundation_probe').select().limit(0);
        fail('Expected PostgrestException for anon access on foundation_probe');
      } on PostgrestException catch (e) {
        expect(e.code, '42501');
      } finally {
        await client.dispose();
      }
    },
  );
}
