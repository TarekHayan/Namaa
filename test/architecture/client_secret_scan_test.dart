import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _modernSecretKey = RegExp(r'\bsb_secret_[A-Za-z0-9_-]{16,}\b');
final RegExp _credentialAssignment = RegExp(
  r'''^\s*(?:SUPABASE_)?(?:SERVICE[_-]?ROLE|SECRET(?:_KEY)?)\s*[:=]\s*['"]?[^\s#'";]{12,}''',
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

bool _isTrackedFlutterClientFile(String path) {
  const clientRoots = <String>[
    'lib/',
    'android/',
    'ios/',
    'windows/',
    'macos/',
    'linux/',
    'assets/',
  ];
  const rootFiles = <String>{'pubspec.yaml', 'pubspec.lock', 'l10n.yaml'};
  const textExtensions = <String>{
    '.dart',
    '.gradle',
    '.java',
    '.json',
    '.kt',
    '.m',
    '.mm',
    '.plist',
    '.properties',
    '.swift',
    '.toml',
    '.xml',
    '.yaml',
    '.yml',
    '.h',
    '.hpp',
    '.c',
    '.cc',
    '.cpp',
  };
  if (rootFiles.contains(path)) {
    return true;
  }
  if (!clientRoots.any(path.startsWith)) {
    return false;
  }
  final fileName = path.split('/').last.toLowerCase();
  return textExtensions.any(fileName.endsWith);
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

  test(
    'tracked Flutter client artifacts contain no Supabase secret credentials',
    () {
      final result = Process.runSync('git', <String>['ls-files']);
      expect(result.exitCode, 0, reason: result.stderr.toString());

      final violations = <String>[];
      for (final path in const LineSplitter().convert(
        result.stdout.toString(),
      )) {
        if (!_isTrackedFlutterClientFile(path)) {
          continue;
        }
        final file = File(path);
        if (!file.existsSync()) {
          continue;
        }
        final findings = _secretFindings(file.readAsStringSync());
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
