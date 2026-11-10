/// The deterministic 009 identities for Adhkar records and set awards
/// (data-model.md). Application owns the port; the data adapter owns the
/// uuid implementation and the shared NS009 namespace.
abstract interface class AdhkarIdentityPort {
  String itemRecordId(String adhkarDay, String itemId);

  String setAwardSourceId(String adhkarDay, String list);
}
