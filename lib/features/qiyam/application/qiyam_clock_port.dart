/// The Qiyam clock: the single `now` sample every command stamps its
/// version with (the server rejects an `updated_at` outside the record's
/// `[night - 1 day, night + 2 days)` window, so the real time is required).
abstract interface class QiyamClockPort {
  DateTime nowUtc();
}
