/// The My Adhkar identities (data-model.md "My Adhkar", Identity): item IDs
/// are random UUIDv4 values created on the adding device, and count record
/// IDs are deterministic under the fixed 009 namespace. Application owns
/// the port; the data adapter owns the uuid implementation.
abstract interface class MyAdhkarIdentityPort {
  /// A fresh random UUIDv4 item ID; it never changes and is never reused.
  String newItemId();

  /// The per-owner count record ID for one item on one Adhkar day:
  /// `UUIDv5(NS009, 'my-adhkar/' + itemId + '/' + day)`.
  String countRecordId(String itemId, String adhkarDay);
}
