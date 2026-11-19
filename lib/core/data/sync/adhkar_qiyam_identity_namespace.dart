import 'package:uuid/uuid.dart';

/// The fixed UUIDv5 namespace for all 009 Adhkar/Qiyam record identities
/// (research.md R6, chosen once at T010).
///
/// Shared verbatim by the Dart adapters, migration 0016 SQL and the test
/// vectors in test/fixtures/adhkar_qiyam/identity_vectors.json. It is never
/// reused for another feature.
const String kAdhkarQiyamIdentityNamespace =
    '70ca78e3-a267-4a2f-883f-1e0dea2df0c3';

const Uuid _uuid = Uuid();

/// Computes a v5 UUID under the 009 namespace for [name].
String adhkarQiyamUuidV5(String name) =>
    _uuid.v5(kAdhkarQiyamIdentityNamespace, name);

/// The stable conflict ID for a losing version pair, identical whatever the
/// arrival order was: the two version descriptors are ordered byte-wise
/// (their payloads are ASCII) before hashing, as in 008.
String adhkarQiyamConflictId(
  String recordId,
  String descriptorA,
  String descriptorB,
) {
  final String low;
  final String high;
  if (descriptorA.compareTo(descriptorB) <= 0) {
    low = descriptorA;
    high = descriptorB;
  } else {
    low = descriptorB;
    high = descriptorA;
  }
  return adhkarQiyamUuidV5('conflict/$recordId/$low/$high');
}
