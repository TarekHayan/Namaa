import '../domain/adhkar_conflict_evidence.dart';

abstract interface class AdhkarConflictReader {
  Stream<List<AdhkarConflictEvidence>> watchConflicts(String accountId);
}
