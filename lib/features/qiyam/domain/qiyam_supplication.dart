/// One authentic Witr/Sujood supplication shown on the Qiyam screen
/// (contracts/adhkar-qiyam-ui.md). The reference content is Qiyam's own
/// domain type: the composition adapter maps it from the shared reviewed
/// catalog so Adhkar and Qiyam never import each other. The texts come
/// from the approved catalog asset, never from code.
final class QiyamSupplication {
  const QiyamSupplication({
    required this.id,
    required this.textAr,
    required this.sourceAr,
    required this.sourceEn,
  });

  final String id;
  final String textAr;
  final String sourceAr;
  final String sourceEn;

  @override
  bool operator ==(Object other) =>
      other is QiyamSupplication && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
