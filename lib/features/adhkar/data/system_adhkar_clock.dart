import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';

/// The device clock behind [AdhkarClockPort]: the one `now` sample each
/// Adhkar and My Adhkar command stamps its version with.
final class SystemAdhkarClock implements AdhkarClockPort {
  const SystemAdhkarClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
