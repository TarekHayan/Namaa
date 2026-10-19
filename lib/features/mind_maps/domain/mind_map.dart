/// Owner-qualified map identity and defaults. Values are immutable and local-first.
library;

enum MapLayout { radial, tree, horizontal, vertical, freeform }

// The last three values retain already persisted Phase 2 payloads.
enum MapNodeShape {
  rectangle,
  roundedRectangle,
  circle,
  pill,
  glass,
  ellipse,
  diamond,
  hexagon,
}

enum MapSize { small, medium, large }

void requireMapIdentity(String value, String field) {
  if (value.trim().isEmpty) throw ArgumentError.value(value, field);
}

void requireMapUtc(DateTime value, String field) {
  if (!value.isUtc) throw ArgumentError.value(value, field, 'must be UTC');
}

String requireMapTitle(String value, String field) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) throw ArgumentError.value(value, field);
  return trimmed;
}

/// A color is a saved ARGB value; visual redesign may change defaults later.
final class MapNodeAppearance {
  const MapNodeAppearance({
    this.argb = 0xffd9e8ff,
    this.icon = 'idea',
    this.shape = MapNodeShape.roundedRectangle,
    this.nodeSize = MapSize.medium,
    this.textSize = MapSize.medium,
  });

  final int argb;
  final String icon;
  final MapNodeShape shape;
  final MapSize nodeSize;
  final MapSize textSize;

  void validate() {
    if (argb < 0 || argb > 0xffffffff) {
      throw ArgumentError.value(argb, 'argb');
    }
    requireMapIdentity(icon, 'icon');
  }
}

final class MapConnectionAppearance {
  const MapConnectionAppearance({this.argb = 0xff64748b, this.width = 2});

  final int argb;
  final double width;

  void validate() {
    if (argb < 0 || argb > 0xffffffff) {
      throw ArgumentError.value(argb, 'argb');
    }
    if (!width.isFinite || width <= 0 || width > 24) {
      throw ArgumentError.value(width, 'width');
    }
  }
}

final class MindMapSettings {
  const MindMapSettings({
    this.layout = MapLayout.radial,
    this.backgroundArgb = 0xffffffff,
    this.defaultNode = const MapNodeAppearance(),
    this.defaultConnection = const MapConnectionAppearance(),
    this.spacing = 120,
  });

  final MapLayout layout;
  final int backgroundArgb;
  final MapNodeAppearance defaultNode;
  final MapConnectionAppearance defaultConnection;
  final double spacing;

  void validate() {
    if (backgroundArgb < 0 || backgroundArgb > 0xffffffff) {
      throw ArgumentError.value(backgroundArgb, 'backgroundArgb');
    }
    if (!spacing.isFinite || spacing < 20 || spacing > 1000) {
      throw ArgumentError.value(spacing, 'spacing');
    }
    defaultNode.validate();
    defaultConnection.validate();
  }
}

final class MindMap {
  MindMap({
    required this.ownerId,
    required this.id,
    required String title,
    required this.centralNodeId,
    required this.revisionId,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.settings = const MindMapSettings(),
    this.deletedAt,
  }) : title = requireMapTitle(title, 'title') {
    requireMapIdentity(ownerId, 'ownerId');
    requireMapIdentity(id, 'id');
    requireMapIdentity(centralNodeId, 'centralNodeId');
    requireMapIdentity(revisionId, 'revisionId');
    requireMapUtc(createdAt, 'createdAt');
    requireMapUtc(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(updatedAt, 'updatedAt');
    }
    if (deletedAt != null) {
      requireMapUtc(deletedAt!, 'deletedAt');
      if (deletedAt != updatedAt) {
        throw ArgumentError.value(deletedAt, 'deletedAt', 'must match version');
      }
    }
    settings.validate();
  }

  final String ownerId;
  final String id;
  final String title;
  final String? description;
  final String centralNodeId;
  final MindMapSettings settings;
  final String revisionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
}
