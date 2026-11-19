/// The My Adhkar identities (data-model.md "My Adhkar", Identity, reshaped
/// 2026-11-16): group and entry IDs are random UUIDv4 values created on the
/// device that creates them; there is no deterministic count record any
/// more (no counter). Application owns the port; the data adapter owns the
/// uuid implementation.
abstract interface class MyAdhkarIdentityPort {
  /// A fresh random UUIDv4 entry ID; it never changes and is never reused.
  String newItemId();

  /// A fresh random UUIDv4 group ID; it never changes and is never reused.
  String newGroupId();
}
