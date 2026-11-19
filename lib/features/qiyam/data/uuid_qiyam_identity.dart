import 'package:namma_project/core/data/sync/adhkar_qiyam_identity_namespace.dart';
import 'package:namma_project/features/qiyam/application/qiyam_identity_port.dart';

/// Deterministic Qiyam identities under the fixed 009 namespace
/// (data-model.md). The night record ID doubles as the `qiyam_done` award
/// `source_id`.
final class UuidQiyamIdentity implements QiyamIdentityPort {
  const UuidQiyamIdentity();

  /// The per-owner record ID for one night's record; also the award source.
  @override
  String nightRecordId(String nightDate) =>
      adhkarQiyamUuidV5('qiyam/$nightDate');

  /// The stable conflict ID for a divergent night version pair; stable
  /// whatever the arrival order was.
  String conflictId(String recordId, String descriptorA, String descriptorB) =>
      adhkarQiyamConflictId(recordId, descriptorA, descriptorB);
}
