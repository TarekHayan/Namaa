/// The deterministic 009 identities for Qiyam night records
/// (data-model.md). Application owns the port; the data adapter owns the
/// uuid implementation and the shared NS009 namespace. The night record ID
/// doubles as the `qiyam_done` award `source_id`.
abstract interface class QiyamIdentityPort {
  String nightRecordId(String nightDate);
}
