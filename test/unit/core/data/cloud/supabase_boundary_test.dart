import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/cloud/supabase/supabase_client_factory.dart';

void main() {
  group('publishable-key-only configuration', () {
    test('accepts a publishable key for the local stack', () {
      final config = SupabaseEnvironmentConfig.localStack(
        publishableKey: 'sb_publishable_abc123',
      );
      expect(config.url, Uri.parse('http://127.0.0.1:54321'));
      expect(config.target, SupabaseTargetEnvironment.localStack);
    });

    test('rejects a modern secret key', () {
      expect(
        () => SupabaseEnvironmentConfig.localStack(
          publishableKey: 'sb_secret_abc123',
        ),
        throwsA(isA<ConfigurationError>()),
      );
    });

    test('rejects service-role key material', () {
      expect(
        () => SupabaseEnvironmentConfig.localStack(
          publishableKey: 'service_role-key-material',
        ),
        throwsA(isA<ConfigurationError>()),
      );
    });

    test('rejects a legacy JWT whose role claim is service_role', () {
      // payload segment decodes to {"role":"service_role"}.
      const payload = 'eyJyb2xlIjoic2VydmljZV9yb2xlIn0';
      expect(
        () => SupabaseEnvironmentConfig.localStack(
          publishableKey: 'eyJhbGciOiJIUzI1NiJ9.$payload.c2ln',
        ),
        throwsA(isA<ConfigurationError>()),
      );
    });

    test('rejects an empty key', () {
      expect(
        () => SupabaseEnvironmentConfig.localStack(publishableKey: ''),
        throwsA(isA<ConfigurationError>()),
      );
    });
  });

  group('environment boundaries', () {
    test('the local stack target requires a loopback host', () {
      expect(
        () => SupabaseEnvironmentConfig.localStack(
          url: Uri.parse('https://nonlocal.example.com'),
          publishableKey: 'sb_publishable_abc123',
        ),
        throwsA(isA<ConfigurationError>()),
      );
    });

    test('the isolated non-production target requires an injected URL', () {
      expect(
        () => SupabaseEnvironmentConfig.isolatedNonProduction(),
        throwsA(isA<ConfigurationError>()),
      );
      final config = SupabaseEnvironmentConfig.isolatedNonProduction(
        url: Uri.parse('https://sbd1.namaa.example.com'),
        publishableKey: 'sb_publishable_abc123',
        approvedHosts: {'sbd1.namaa.example.com'},
      );
      expect(config.target, SupabaseTargetEnvironment.isolatedNonProduction);
    });

    test('isolated non-production rejects production URLs', () {
      final productionUrls = [
        'https://prod.example.supabase.co',
        'https://production.supabase.co',
        'https://namaa-prod.supabase.co',
        'https://supabase.co',
      ];
      for (final url in productionUrls) {
        expect(
          () => SupabaseEnvironmentConfig.isolatedNonProduction(
            url: Uri.parse(url),
            publishableKey: 'sb_publishable_abc123',
            approvedHosts: {'sbd1.namaa.example.com'},
          ),
          throwsA(isA<ConfigurationError>()),
          reason: 'Production URL $url must be rejected',
        );
      }
    });

    test('isolated non-production rejects arbitrary HTTPS endpoints', () {
      final arbitraryUrls = [
        'https://arbitrary.example.com',
        'https://google.com',
        'https://unapproved.host.org',
      ];
      for (final url in arbitraryUrls) {
        expect(
          () => SupabaseEnvironmentConfig.isolatedNonProduction(
            url: Uri.parse(url),
            publishableKey: 'sb_publishable_abc123',
            approvedHosts: {'sbd1.namaa.example.com'},
          ),
          throwsA(isA<ConfigurationError>()),
          reason: 'Arbitrary HTTPS URL $url must be rejected',
        );
      }
    });

    test('isolated non-production accepts explicit allow-list', () {
      final approvedConfig = SupabaseEnvironmentConfig.isolatedNonProduction(
        url: Uri.parse('https://sbd1.namaa.example.com'),
        publishableKey: 'sb_publishable_abc123',
        approvedHosts: {'sbd1.namaa.example.com'},
      );
      expect(
        approvedConfig.target,
        SupabaseTargetEnvironment.isolatedNonProduction,
      );

      final customAllowListed = SupabaseEnvironmentConfig.isolatedNonProduction(
        url: Uri.parse('https://device-test.local-network.example.org'),
        publishableKey: 'sb_publishable_abc123',
        approvedHosts: {'device-test.local-network.example.org'},
      );
      expect(
        customAllowListed.url.host,
        'device-test.local-network.example.org',
      );
    });

    test('no target accepts production', () {
      // Production is never a selectable value; the enum has no member.
      expect(SupabaseTargetEnvironment.values, hasLength(2));
    });
  });

  group('client factory', () {
    test('refuses to build a client with secret key material', () {
      expect(
        () => createSupabaseClient(
          SupabaseEnvironmentConfig.isolatedNonProduction(
            url: Uri.parse('https://sbd1.namaa.example.com'),
            publishableKey: 'sb_secret_abc123',
            approvedHosts: {'sbd1.namaa.example.com'},
          ),
        ),
        throwsA(isA<ConfigurationError>()),
      );
    });

    test('refuses to build a client for production endpoint', () {
      expect(
        () => createSupabaseClient(
          SupabaseEnvironmentConfig.localStack(
            url: Uri.parse('https://prod.example.supabase.co'),
            publishableKey: 'sb_publishable_abc123',
          ),
        ),
        throwsA(isA<ConfigurationError>()),
      );
    });

    test('builds a client from a validated local-stack config', () {
      final client = createSupabaseClient(
        SupabaseEnvironmentConfig.localStack(
          publishableKey: 'sb_publishable_abc123',
        ),
      );
      expect(client.rest.url, 'http://127.0.0.1:54321/rest/v1');
      client.dispose();
    });
  });

  group('domain boundary', () {
    test('Domain files import no Supabase package', () {
      final domainDirs = [
        Directory('lib/core/domain'),
        Directory('lib/features/foundation/domain'),
      ];
      final violations = <String>[];
      for (final dir in domainDirs) {
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) {
            continue;
          }
          final source = entity.readAsStringSync();
          if (source.contains('package:supabase')) {
            violations.add(entity.path);
          }
        }
      }
      expect(violations, isEmpty);
    });
  });
}
