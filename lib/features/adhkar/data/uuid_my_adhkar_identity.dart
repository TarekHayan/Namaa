import 'package:namma_project/features/adhkar/application/my_adhkar_identity_port.dart';
import 'package:uuid/uuid.dart';

/// My Adhkar identities (data-model.md, reshaped 2026-11-16): random UUIDv4
/// group and entry IDs created on the device that creates them. There is no
/// deterministic count record identity any more (no counter).
final class UuidMyAdhkarIdentity implements MyAdhkarIdentityPort {
  const UuidMyAdhkarIdentity();

  static const Uuid _uuid = Uuid();

  @override
  String newItemId() => _uuid.v4();

  @override
  String newGroupId() => _uuid.v4();
}
