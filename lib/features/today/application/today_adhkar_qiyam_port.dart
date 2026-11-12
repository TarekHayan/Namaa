import '../domain/today_adhkar_qiyam_reference.dart';

/// The Adhkar/Qiyam boundary Today renders from (contracts/
/// adhkar-qiyam-application.md, TodayAdhkarQiyamPort): read-only values
/// through the application APIs only. T057/T058 wire it into the widgets.
abstract interface class TodayAdhkarQiyamPort {
  Stream<TodayAdhkarQiyamReference> watch(String ownerId);
}
