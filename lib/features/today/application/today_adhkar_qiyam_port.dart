import '../domain/today_adhkar_qiyam_reference.dart';

/// The Adhkar/Qiyam boundary Today renders from (contracts/
/// adhkar-qiyam-application.md, TodayAdhkarQiyamPort): read-only values
/// through the application APIs only. Home's cubit and the Track hub watch it.
abstract interface class TodayAdhkarQiyamPort {
  /// [ownerId] owns the Adhkar counts; [qiyamOwnerId] owns the Qiyam nights
  /// and defaults to [ownerId] (they differ only in a debug preview, where
  /// each domain has its own closed preview owner).
  Stream<TodayAdhkarQiyamReference> watch(
    String ownerId, {
    String? qiyamOwnerId,
  });
}
