/// Actual award ledger read boundary. No writer or inferred reward surface.
library;

import '../domain/today_models.dart';

abstract interface class TodayXpPort {
  /// Emits all canonical award records for this XP owner, including awards
  /// whose Tasks were reopened or deleted. Errors and unexpected closure are
  /// section failures; a quiet live stream after first emission remains valid.
  /// Consumers retain the confirmed rows and reproject them when the device
  /// calendar changes, without writing or requesting another award.
  Stream<List<TodayAwardReference>> watchAwards(String ownerId);
}
