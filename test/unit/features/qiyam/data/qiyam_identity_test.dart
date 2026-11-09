import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/qiyam/data/uuid_qiyam_identity.dart';

/// T009: Qiyam night identity vectors computed with an independent RFC 4122
/// implementation (Python uuid5) so the Dart adapter is cross-checked.
void main() {
  final vectors =
      jsonDecode(
            File(
              'test/fixtures/adhkar_qiyam/identity_vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  final identity = const UuidQiyamIdentity();

  group('UuidQiyamIdentity against RFC 4122 vectors', () {
    test('night record IDs', () {
      for (final vector in (vectors['nightRecords'] as List)) {
        final v = vector as Map<String, dynamic>;
        expect(
          identity.nightRecordId(v['nightDate'] as String),
          v['expected'],
          reason: 'night ${v['nightDate']}',
        );
      }
    });

    test('the night record ID is the qiyam award source id by design', () {
      final night =
          (vectors['nightRecords'] as List).first as Map<String, dynamic>;
      final awardName = night['name'] as String;
      expect(awardName, 'qiyam/${night['nightDate']}');
      expect(
        identity.nightRecordId(night['nightDate'] as String),
        night['expected'],
      );
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

    test('distinct nights produce distinct record IDs', () {
      final ids = (vectors['nightRecords'] as List)
          .map((v) => (v as Map<String, dynamic>)['expected'])
          .toSet();
      expect(ids, hasLength((vectors['nightRecords'] as List).length));
    });
  });
}
