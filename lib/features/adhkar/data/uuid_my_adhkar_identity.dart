import 'package:namma_project/core/data/sync/adhkar_qiyam_identity_namespace.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_identity_port.dart';
import 'package:uuid/uuid.dart';

/// My Adhkar identities under the fixed 009 namespace (data-model.md):
/// random UUIDv4 item IDs and deterministic
/// `UUIDv5(NS009, 'my-adhkar/' + itemId + '/' + day)` count record IDs.
/// The SQL side of migration 0017 recomputes the same count UUIDs; the
/// vectors in test/fixtures/adhkar_qiyam/identity_vectors.json cross-check
/// both with an independent RFC 4122 implementation.
final class UuidMyAdhkarIdentity implements MyAdhkarIdentityPort {
  const UuidMyAdhkarIdentity();

  static const Uuid _uuid = Uuid();

  @override
  String newItemId() => _uuid.v4();

  @override
  String countRecordId(String itemId, String adhkarDay) =>
      adhkarQiyamUuidV5('my-adhkar/$itemId/$adhkarDay');
}
