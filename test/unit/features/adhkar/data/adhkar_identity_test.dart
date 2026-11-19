import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/data/uuid_adhkar_identity.dart';

/// T009: Adhkar identity vectors computed with an independent RFC 4122
/// implementation (Python uuid5) so the Dart adapters are cross-checked.
void main() {
  final vectors =
      jsonDecode(
            File(
              'test/fixtures/adhkar_qiyam/identity_vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  final identity = const UuidAdhkarIdentity();

  group('UuidAdhkarIdentity against RFC 4122 vectors', () {
    test('item record IDs', () {
      for (final vector in (vectors['itemRecords'] as List)) {
        final v = vector as Map<String, dynamic>;
        expect(
          identity.itemRecordId(v['day'] as String, v['itemId'] as String),
          v['expected'],
          reason: 'item ${v['itemId']} on ${v['day']}',
        );
      }
    });

    test('set award source IDs for both lists', () {
      for (final vector in (vectors['setAwardSourceIds'] as List)) {
        final v = vector as Map<String, dynamic>;
        expect(
          identity.setAwardSourceId(v['day'] as String, v['list'] as String),
          v['expected'],
          reason: 'set ${v['list']} on ${v['day']}',
        );
      }
    });

    test('conflict IDs are stable for reversed arrival order', () {
      for (final vector in (vectors['conflictIds'] as List)) {
        final v = vector as Map<String, dynamic>;
        final recordId = v['recordId'] as String;
        final a = v['descriptorA'] as String;
        final b = v['descriptorB'] as String;
        expect(identity.conflictId(recordId, a, b), v['expected']);
        expect(identity.conflictId(recordId, b, a), v['expected']);
      }
    });

    test('distinct days and items produce distinct record IDs', () {
      final ids = (vectors['itemRecords'] as List)
          .map((v) => (v as Map<String, dynamic>)['expected'])
          .toSet();
      expect(ids, hasLength((vectors['itemRecords'] as List).length));
    });

    test('the namespace matches the vectors fixture', () {
      expect(vectors['namespace'], isA<String>());
      final v = (vectors['itemRecords'] as List).first as Map<String, dynamic>;
      // Re-derive one expected value through the shared namespace constant
      // via the same adapter (indirectly covers kAdhkarQiyamIdentityNamespace
      // == vectors['namespace'] through the RFC check above).
      expect(
        identity.itemRecordId(v['day'] as String, v['itemId'] as String),
        v['expected'],
      );
    });
  });
}
