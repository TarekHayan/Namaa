import '../domain/prayer_conflict_evidence.dart';

abstract interface class PrayerConflictReader {
  Stream<List<PrayerConflictEvidence>> watchConflicts(String accountId);
}
