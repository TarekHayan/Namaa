import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture boundaries (specs/001-namaa-foundation/contracts/
/// application-boundaries.md; Constitution: shared business rules with no
/// infrastructure coupling).
///
/// Layer rules, checked for every Dart file under `lib/`:
///  * domain       -> domain only
///  * application  -> domain, application
///  * data/platform-> domain, application, data/platform
///  * presentation -> domain, application, presentation
///  * app          -> anything
///
/// Both `package:namma_project/...` and relative imports are resolved to a
/// `lib/` path before being classified, so relative imports cannot bypass the
/// rules.
const String _packageName = 'namma_project';

enum _Layer { domain, application, infrastructure, presentation, app, other }

const Map<_Layer, Set<_Layer>> _allowedDependencies = {
  _Layer.domain: {_Layer.domain},
  _Layer.application: {_Layer.domain, _Layer.application},
  _Layer.infrastructure: {
    _Layer.domain,
    _Layer.application,
    _Layer.infrastructure,
  },
  _Layer.presentation: {_Layer.domain, _Layer.application, _Layer.presentation},
  _Layer.app: {
    _Layer.domain,
    _Layer.application,
    _Layer.infrastructure,
    _Layer.presentation,
    _Layer.app,
  },
};

/// External libraries Domain may use (everything else is rejected).
const List<String> _domainExternalAllowlist = <String>[
  'dart:core',
  'dart:async',
  'dart:collection',
  'dart:convert',
  'dart:math',
  'package:meta/',
];

/// Libraries forbidden in any layer that must stay infrastructure-free.
const List<String> _forbiddenInfrastructurePrefixes = <String>[
  'dart:ui',
  'package:flutter/',
  'package:supabase',
  'package:drift',
  'package:go_router',
  'package:flutter_local_notifications',
  'package:firebase_messaging',
  'package:flutter_secure_storage',
  'package:shared_preferences',
  'package:path_provider',
];

final RegExp _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

List<String> _directivesIn(String source) =>
    _directive.allMatches(source).map((m) => m.group(1)!).toList();

/// Resolves [target] to a normalized `lib/`-relative path, or null when it is
/// an external (non-project) library.
String? _resolveProjectPath(String fromFile, String target) {
  const prefix = 'package:$_packageName/';
  if (target.startsWith(prefix)) {
    return target.substring(prefix.length);
  }
  if (target.contains(':')) {
    return null;
  }
  final fromDir = fromFile.replaceAll('\\', '/').split('/')
    ..removeLast(); // path under lib/
  final segments = <String>[...fromDir];
  for (final part in target.split('/')) {
    if (part == '..') {
      if (segments.isNotEmpty) {
        segments.removeLast();
      }
    } else if (part != '.' && part.isNotEmpty) {
      segments.add(part);
    }
  }
  return segments.join('/');
}

/// Classifies a `lib/`-relative path into a layer.
_Layer _layerOf(String libPath) {
  final p = libPath.replaceAll('\\', '/');
  if (p.startsWith('app/')) {
    return _Layer.app;
  }
  if (p.startsWith('core/domain/') ||
      RegExp(r'^features/[^/]+/domain/').hasMatch(p)) {
    return _Layer.domain;
  }
  if (p.startsWith('core/application/') ||
      RegExp(r'^features/[^/]+/application/').hasMatch(p)) {
    return _Layer.application;
  }
  if (p.startsWith('core/data/') ||
      p.startsWith('core/platform/') ||
      RegExp(r'^features/[^/]+/(data|platform)/').hasMatch(p)) {
    return _Layer.infrastructure;
  }
  if (RegExp(r'^features/[^/]+/presentation/').hasMatch(p)) {
    return _Layer.presentation;
  }
  return _Layer.other;
}

/// Returns violation descriptions for [source], a file at [libPath].
List<String> _violationsIn(String libPath, String source) {
  final layer = _layerOf(libPath);
  final allowed = _allowedDependencies[layer];
  if (allowed == null) {
    return const [];
  }
  final violations = <String>[];
  for (final target in _directivesIn(source)) {
    final projectPath = _resolveProjectPath(libPath, target);
    if (projectPath != null) {
      final targetLayer = _layerOf(projectPath);
      if (targetLayer != _Layer.other && !allowed.contains(targetLayer)) {
        violations.add(
          '${layer.name} must not depend on ${targetLayer.name}: $target',
        );
      }
      continue;
    }
    if (layer == _Layer.domain) {
      if (!_domainExternalAllowlist.any(target.startsWith)) {
        violations.add('domain imports non-allowlisted library: $target');
      }
    } else if (layer == _Layer.application &&
        _forbiddenInfrastructurePrefixes.any(target.startsWith)) {
      violations.add('application imports infrastructure library: $target');
    }
  }
  return violations;
}

/// Presentation must call application use cases, never adapters or
/// infrastructure packages directly.
List<String> _presentationViolationsIn(String libPath, String source) {
  final violations = _violationsIn(libPath, source);
  for (final target in _directivesIn(source)) {
    if (target.startsWith('package:drift') ||
        target.startsWith('package:supabase') ||
        target.startsWith('package:flutter_secure_storage')) {
      violations.add('presentation imports infrastructure package: $target');
    }
  }
  return violations;
}

Iterable<File> _dartFiles(String root) {
  final dir = Directory(root);
  expect(dir.existsSync(), isTrue, reason: '$root must exist');
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.replaceAll('\\', '/').contains('/generated/'));
}

String _libRelative(File file) {
  final normalized = file.path.replaceAll('\\', '/');
  final index = normalized.indexOf('lib/');
  return normalized.substring(index + 'lib/'.length);
}

void main() {
  group('scanner failure-mode controls', () {
    test('rejects infrastructure and non-allowlisted imports in Domain', () {
      const sample = '''
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
''';
      final violations = _violationsIn('core/domain/x.dart', sample);
      expect(violations, hasLength(2));
    });

    test('rejects absolute in-project imports of upper layers from Domain', () {
      const sample = '''
import 'package:namma_project/core/data/cloud/supabase/supabase_sync_adapter.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:namma_project/app/theme/app_theme.dart';
''';
      expect(_violationsIn('core/domain/x.dart', sample), hasLength(3));
    });

    test('rejects relative imports that reach an upper layer', () {
      const sample = '''
import '../../data/cloud/supabase/supabase_sync_adapter.dart';
import '../../../core/data/local/db.dart';
''';
      expect(_violationsIn('core/domain/values/x.dart', sample), hasLength(2));
    });

    test('rejects presentation depending on infrastructure', () {
      const sample = '''
import 'package:namma_project/core/data/local/db.dart';
import 'package:namma_project/core/platform/secure_credential_vault.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
''';
      expect(
        _presentationViolationsIn(
          'features/foundation/presentation/widgets/x.dart',
          sample,
        ),
        isNotEmpty,
      );
    });

    test('accepts a permitted dependency direction', () {
      const sample = '''
import 'package:namma_project/core/domain/failures/app_failure.dart';
import '../ports/foundation_ports.dart';
''';
      expect(_violationsIn('core/application/x.dart', sample), isEmpty);
    });
  });

  test('every layer under lib/ respects its dependency rules', () {
    final violations = <String>[];
    for (final file in _dartFiles('lib')) {
      final libPath = _libRelative(file);
      final source = file.readAsStringSync();
      final layer = _layerOf(libPath);
      final found = layer == _Layer.presentation
          ? _presentationViolationsIn(libPath, source)
          : _violationsIn(libPath, source);
      for (final violation in found) {
        violations.add('lib/$libPath: $violation');
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'Layers must only depend inward '
          '(domain <- application <- data/presentation <- app)',
    );
  });
}
