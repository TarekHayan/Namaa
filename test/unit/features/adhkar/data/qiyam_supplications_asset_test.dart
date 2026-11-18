import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

/// T049: the Qiyam supplications in the shipped catalog are the owner-approved
/// texts of specs/009-adhkar-qiyam/content-sources.md, character for
/// character. The test reads both files and compares them, so the religious
/// text itself lives only in the reviewed sources, never in code.
void main() {
  final assetFile = File('assets/religious/adhkar_catalog_v1.json');
  final sourcesFile = File('specs/009-adhkar-qiyam/content-sources.md');

  late AdhkarCatalog catalog;
  late String sources;

  setUpAll(() {
    catalog = AdhkarCatalog.fromJson(
      jsonDecode(assetFile.readAsStringSync()) as Map<String, dynamic>,
    );
    sources = sourcesFile.readAsStringSync().replaceAll('\r\n', '\n');
  });

  test('ships exactly the approved Witr supplication and Qunut', () {
    expect(catalog.qiyamSupplications.map((s) => s.id), ['s1', 's2']);
  });

  test('s1 matches the approved text and source line', () {
    final s1 = catalog.qiyamSupplications.firstWhere((s) => s.id == 's1');
    final section = sources.substring(
      sources.indexOf('### s1 — '),
      sources.indexOf('### s2 — '),
    );
    expect(
      s1.textAr,
      RegExp(
        r'^- Arabic text \(prototype\): «([^»]*)»$',
        multiLine: true,
      ).firstMatch(section)!.group(1),
    );
    expect(
      s1.sourceAr,
      RegExp(
        r'^- Source shown \(prototype\): (.*)$',
        multiLine: true,
      ).firstMatch(section)!.group(1)!.trim(),
    );
  });

  test('s2 is the full approved Qunut, not the truncated prototype text', () {
    final s2 = catalog.qiyamSupplications.firstWhere((s) => s.id == 's2');
    final approved = sources.substring(
      sources.indexOf('### s2: full Qunut, approved'),
      sources.indexOf('### Skipped from Hisn al-Muslim'),
    );
    expect(
      s2.textAr,
      RegExp(r'^«([^»]*)»$', multiLine: true).firstMatch(approved)!.group(1),
    );
    expect(s2.textAr.contains('…'), isFalse);
    expect(s2.textAr.contains('...'), isFalse);
    final old = sources.substring(
      sources.indexOf('### s2 — '),
      sources.indexOf('## Translation license summary'),
    );
    expect(
      s2.sourceAr,
      RegExp(
        r'^- Source shown \(prototype\): (.*)$',
        multiLine: true,
      ).firstMatch(old)!.group(1)!.trim(),
    );
  });

  test('every supplication has a text and a source', () {
    for (final supplication in catalog.qiyamSupplications) {
      expect(supplication.textAr.trim(), isNotEmpty);
      expect(supplication.sourceAr.trim(), isNotEmpty);
    }
  });
}
