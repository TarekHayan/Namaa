import '../domain/qiyam_conflict_evidence.dart';

abstract interface class QiyamConflictReader {
  Stream<List<QiyamConflictEvidence>> watchConflicts(String accountId);
}
