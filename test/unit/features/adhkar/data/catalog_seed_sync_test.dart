import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

/// Phase 2 review finding 1: the server catalog seed must never drift from
/// the owner-approved asset. The seed ships in the SAME change as
/// assets/religious/adhkar_catalog_v1.json (T006, after the owner's content
/// approval T073); until then 0016 must not seed any rows.
void main() {
  final assetFile = File('assets/religious/adhkar_catalog_v1.json');
  final migrationFile = File('supabase/migrations/0016_adhkar_qiyam.sql');

  test('0016 seeds the catalog only together with the approved asset', () {
    final migration = migrationFile.readAsStringSync();
    if (!assetFile.existsSync()) {
      expect(
        migration.toLowerCase().contains(
          'insert into public.adhkar_catalog_items',
        ),
        isFalse,
        reason:
            'the seed ships only in the change that ships the '
            'owner-approved asset (T006); until then the table stays empty',
      );
      return;
    }

    // The asset exists: the migration must seed exactly the approved items.
    final catalog = AdhkarCatalog.fromJson(
      jsonDecode(assetFile.readAsStringSync()) as Map<String, dynamic>,
    );
    final approved = <String, List<Object?>>{
      for (final item in catalog.items)
        item.itemId: [item.list.name, item.position, item.target],
    };

    final lowered = migration.toLowerCase();
    final insertIndex = lowered.indexOf(
      'insert into public.adhkar_catalog_items',
    );
    expect(
      insertIndex,
      greaterThanOrEqualTo(0),
      reason: 'the approved asset must ship with its seed',
    );
    final end = migration.indexOf(';', insertIndex);
    final statement = migration.substring(insertIndex, end);
    final rowPattern = RegExp(
      r"\((\d+),'([a-z0-9]+)','(morning|evening)',(\d+),(\d+)\)",
    );
    final seeded = <String, List<Object?>>{};
    for (final match in rowPattern.allMatches(statement)) {
      seeded[match.group(2)!] = [
        match.group(3),
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
      ];
      expect(
        int.parse(match.group(1)!),
        catalog.version,
        reason: 'every seed row records the asset catalog version',
      );
    }
    expect(
      seeded.keys.toSet(),
      approved.keys.toSet(),
      reason: 'seed item IDs equal the approved asset item IDs',
    );
    for (final entry in seeded.entries) {
      expect(
        entry.value,
        approved[entry.key],
        reason: 'seed ${entry.key} matches the approved asset',
      );
    }
  });
}
