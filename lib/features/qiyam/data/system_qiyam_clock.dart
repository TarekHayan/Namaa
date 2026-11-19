import 'package:namma_project/features/qiyam/application/qiyam_clock_port.dart';

/// The device clock behind [QiyamClockPort]: the one `now` sample each
/// Qiyam command stamps its version with.
final class SystemQiyamClock implements QiyamClockPort {
  const SystemQiyamClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
