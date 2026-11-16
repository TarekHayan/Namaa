import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/data/uuid_my_adhkar_identity.dart';

/// T100: the reshaped My Adhkar identity (data-model.md, reshaped
/// 2026-11-16): group and entry IDs are random UUIDv4 values; there is no
/// deterministic count record identity any more, so no UUIDv5 vectors.
void main() {
  const identity = UuidMyAdhkarIdentity();

  final uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('new entry IDs are random UUIDv4 values', () {
    final seen = <String>{};
    for (var i = 0; i < 50; i++) {
      final id = identity.newItemId();
      expect(uuidPattern.hasMatch(id), isTrue, reason: 'id $id is UUIDv4');
      seen.add(id);
    }
    expect(seen, hasLength(50), reason: 'v4 IDs never repeat here');
  });

  test('new group IDs are random UUIDv4 values, independent of entry IDs', () {
    final seen = <String>{};
    for (var i = 0; i < 50; i++) {
      final id = identity.newGroupId();
      expect(uuidPattern.hasMatch(id), isTrue, reason: 'id $id is UUIDv4');
      seen.add(id);
    }
    expect(seen, hasLength(50));
    expect(identity.newGroupId(), isNot(equals(identity.newGroupId())));
  });
}
