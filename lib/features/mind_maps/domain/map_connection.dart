import 'mind_map.dart';

/// Parentage is keyed by child, so reparenting changes one record only.
final class ParentSlot {
  ParentSlot({
    required this.ownerId,
    required this.mapId,
    required this.childNodeId,
    required this.parentNodeId,
    required this.revisionId,
    required this.updatedAt,
    this.appearance = const MapConnectionAppearance(),
    this.deletedAt,
  }) {
    for (final (value, field) in [
      (ownerId, 'ownerId'),
      (mapId, 'mapId'),
      (childNodeId, 'childNodeId'),
      (parentNodeId, 'parentNodeId'),
      (revisionId, 'revisionId'),
    ]) {
      requireMapIdentity(value, field);
    }
    if (childNodeId == parentNodeId) {
      throw ArgumentError('A node cannot parent itself');
    }
    requireMapUtc(updatedAt, 'updatedAt');
    if (deletedAt != null) {
      requireMapUtc(deletedAt!, 'deletedAt');
      if (deletedAt != updatedAt) {
        throw ArgumentError.value(deletedAt, 'deletedAt', 'must match version');
      }
    }
    appearance.validate();
  }

  final String ownerId;
  final String mapId;
  final String childNodeId;
  final String parentNodeId;
  final MapConnectionAppearance appearance;
  final String revisionId;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  String get id => 'parent:$childNodeId';
  bool get isDeleted => deletedAt != null;
}

/// The endpoint order and identity are canonical for an unordered visual pair.
final class SideLink {
  SideLink({
    required this.ownerId,
    required this.mapId,
    required String firstNodeId,
    required String secondNodeId,
    required this.revisionId,
    required this.updatedAt,
    this.appearance = const MapConnectionAppearance(),
    this.deletedAt,
  }) : firstNodeId = firstNodeId.compareTo(secondNodeId) < 0
           ? firstNodeId
           : secondNodeId,
       secondNodeId = firstNodeId.compareTo(secondNodeId) < 0
           ? secondNodeId
           : firstNodeId {
    for (final (value, field) in [
      (ownerId, 'ownerId'),
      (mapId, 'mapId'),
      (this.firstNodeId, 'firstNodeId'),
      (this.secondNodeId, 'secondNodeId'),
      (revisionId, 'revisionId'),
    ]) {
      requireMapIdentity(value, field);
    }
    if (this.firstNodeId == this.secondNodeId) {
      throw ArgumentError('A node cannot link to itself');
    }
    requireMapUtc(updatedAt, 'updatedAt');
    if (deletedAt != null) {
      requireMapUtc(deletedAt!, 'deletedAt');
      if (deletedAt != updatedAt) {
        throw ArgumentError.value(deletedAt, 'deletedAt', 'must match version');
      }
    }
    appearance.validate();
  }

  final String ownerId;
  final String mapId;
  final String firstNodeId;
  final String secondNodeId;
  final MapConnectionAppearance appearance;
  final String revisionId;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  String get id => 'side:$firstNodeId:$secondNodeId';
  bool get isDeleted => deletedAt != null;
}
