/// The Adhkar clock: the single `now` sample every command stamps its
/// version with (research.md R3; the server rejects an updated_at outside
/// the record's day window, so the real current time is required).
abstract interface class AdhkarClockPort {
  DateTime nowUtc();
}
