import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/data/uuid_my_adhkar_identity.dart';

/// T085: My Adhkar identity vectors computed with an independent RFC 4122
/// implementation (Python uuid5) so the Dart adapter is cross-checked:
/// random UUIDv4 item IDs and deterministic
/// `UUIDv5(NS009, 'my-adhkar/' + itemId + '/' + day)` count record IDs.
void main() {
  final vectors =
      jsonDecode(
            File(
              'test/fixtures/adhkar_qiyam/identity_vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  final identity = const UuidMyAdhkarIdentity();

  group('UuidMyAdhkarIdentity against RFC 4122 vectors', () {
    test('count record IDs', () {
      for (final vector in (vectors['myAdhkarCountRecords'] as List)) {
        final v = vector as Map<String, dynamic>;
        expect(
          identity.countRecordId(v['itemId'] as String, v['day'] as String),
          v['expected'],
          reason:
              'item ${v['itemId']} on ${v['day']} '
              '(name ${v['name']})',
        );
      }
    });

    test('count record IDs are distinct across items and days', () {
      final ids = (vectors['myAdhkarCountRecords'] as List)
          .map((v) => (v as Map<String, dynamic>)['expected'])
          .toSet();
      expect(ids, hasLength((vectors['myAdhkarCountRecords'] as List).length));
    });

    test('new item IDs are random UUIDv4 values', () {
      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
        r'[0-9a-f]{12}$',
      );
      final seen = <String>{};
      for (var i = 0; i < 50; i++) {
        final id = identity.newItemId();
        expect(uuidPattern.hasMatch(id), isTrue, reason: 'id $id is UUIDv4');
        seen.add(id);
      }
      expect(seen, hasLength(50), reason: 'v4 IDs never repeat here');
    });

    test('the same item and day always produce the same count record ID', () {
      final first = identity.countRecordId(
        '11111111-2222-4333-8444-555555555555',
        '2026-11-15',
      );
      final second = identity.countRecordId(
        '11111111-2222-4333-8444-555555555555',
        '2026-11-15',
      );
      expect(first, second);
    });
  });
}
