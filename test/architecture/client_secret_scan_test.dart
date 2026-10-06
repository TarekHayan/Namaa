import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _modernSecretKey = RegExp(r'\bsb_secret_[A-Za-z0-9_-]{16,}\b');
final RegExp _credentialAssignment = RegExp(
  r'''^\s*(?:export\s+)?(?:(?:static|late|const|final|var|String)\s+)*(?![\w.-]*(?:fake|dummy|mock|example|sample))[\w.-]*(?:service[_-]?role|secret)\w*\s*[:=]\s*['"]?(?![$<{])[^\s#'";]{12,}''',
  caseSensitive: false,
  multiLine: true,
);
final RegExp _jwt = RegExp(
  r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
);
final RegExp _serviceRoleClaim = RegExp(
  r'''["']role["']\s*:\s*["']service_role["']''',
);

List<String> _secretFindings(String source) {
  final findings = <String>[];
  if (_modernSecretKey.hasMatch(source)) {
    findings.add('modern Supabase secret key');
  }
  if (_credentialAssignment.hasMatch(source)) {
    findings.add('secret or service-role credential assignment');
  }
  for (final match in _jwt.allMatches(source)) {
    final parts = match.group(0)!.split('.');
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
        allowMalformed: true,
      );
      if (_serviceRoleClaim.hasMatch(payload)) {
        findings.add('legacy JWT with service_role claim');
      }
    } on FormatException {
      // An invalid JWT-shaped string cannot be a usable client credential.
    } on ArgumentError {
      // Base64 normalization rejected this non-credential value.
    }
  }
  return findings;
}

/// This file embeds deliberate fake credentials as scanner controls.
const String _selfPath = 'test/architecture/client_secret_scan_test.dart';

/// Every tracked file is scanned unless it is a known binary type. A denylist
/// (rather than an allowlist of folders/extensions) means new locations such as
/// web/, .github/, supabase/, .env, .xcconfig and .arb files are covered by
/// default.
bool _isScannedFile(String path) {
  const binaryExtensions = <String>{
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
    '.ico',
    '.icns',
    '.ttf',
    '.otf',
    '.woff',
    '.woff2',
    '.pdf',
    '.zip',
    '.jar',
    '.keystore',
    '.jks',
    '.so',
    '.dll',
    '.dylib',
    '.a',
    '.mp3',
    '.mp4',
    '.wav',
    '.db',
    '.sqlite',
  };
  if (path == _selfPath) {
    return false;
  }
  final fileName = path.split('/').last.toLowerCase();
  return !binaryExtensions.any(fileName.endsWith);
}

void main() {
  test(
    'scanner detects Supabase secret credentials (failure-mode control)',
    () {
      const modernSecret = 'sb_secret_abcdefghijklmnopqrstuvwxyz012345';
      const legacyJwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.signature';
      final findings = _secretFindings('''
SUPABASE_SERVICE_ROLE=$modernSecret
const legacy = '$legacyJwt';
''');

      expect(findings, hasLength(3));
    },
  );

  test('scanner detects common credential variable names (control)', () {
    const value = 'abcdefghijklmnop0123';
    for (final line in <String>[
      'SUPABASE_SERVICE_ROLE_KEY=$value',
      'export SUPABASE_SERVICE_ROLE_KEY="$value"',
      "const serviceRoleKey = '$value';",
      "static const String clientSecret = '$value';",
      'service_role_key: $value',
    ]) {
      expect(_secretFindings(line), isNotEmpty, reason: 'must flag: $line');
    }
  });

  test('scanner ignores placeholders and CI secret references (control)', () {
    for (final line in <String>[
      r'SUPABASE_SERVICE_ROLE_KEY=${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}',
      'SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>',
      'SUPABASE_SERVICE_ROLE_KEY=',
    ]) {
      expect(_secretFindings(line), isEmpty, reason: 'must not flag: $line');
    }
  });

  test(
    'tracked Flutter client artifacts contain no Supabase secret credentials',
    () {
      final result = Process.runSync('git', <String>['ls-files']);
      expect(result.exitCode, 0, reason: result.stderr.toString());

      final violations = <String>[];
      for (final path in const LineSplitter().convert(
        result.stdout.toString(),
      )) {
        if (!_isScannedFile(path)) {
          continue;
        }
        final file = File(path);
        if (!file.existsSync()) {
          continue;
        }
        final findings = _secretFindings(
          utf8.decode(file.readAsBytesSync(), allowMalformed: true),
        );
        if (findings.isNotEmpty) {
          violations.add('$path: ${findings.join(', ')}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Flutter client artifacts must contain publishable keys only',
      );
    },
  );
}
