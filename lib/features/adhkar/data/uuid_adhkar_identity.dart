import 'package:namma_project/core/data/sync/adhkar_qiyam_identity_namespace.dart';
import 'package:namma_project/features/adhkar/application/adhkar_identity_port.dart';

/// Deterministic Adhkar identities under the fixed 009 namespace
/// (data-model.md). The SQL side of migration 0016 recomputes the same UUIDs.
final class UuidAdhkarIdentity implements AdhkarIdentityPort {
  const UuidAdhkarIdentity();

  /// The per-owner record ID for one item count on one Adhkar day.
  @override
  String itemRecordId(String adhkarDay, String itemId) =>
      adhkarQiyamUuidV5('adhkar-item/$adhkarDay/$itemId');

  /// The set-completion award `source_id` for one day and list.
  @override
  String setAwardSourceId(String adhkarDay, String list) =>
      adhkarQiyamUuidV5('adhkar/$adhkarDay/$list');

  /// The stable conflict ID for a divergent item-count version pair; stable
  /// whatever the arrival order was.
  String conflictId(String recordId, String descriptorA, String descriptorB) =>
      adhkarQiyamConflictId(recordId, descriptorA, descriptorB);
}
