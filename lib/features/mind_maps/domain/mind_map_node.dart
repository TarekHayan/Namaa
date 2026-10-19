import 'mind_map.dart';

enum MindMapNodeKind { central, mainIdea, branch, task, note }

enum MindMapNodeStatus { notStarted, inProgress, completed }

enum MindMapNodePriority { low, medium, high }

/// A node's content and position version independently of its relationships.
final class MindMapNode {
  MindMapNode({
    required this.ownerId,
    required this.mapId,
    required this.id,
    required this.kind,
    required String title,
    required this.x,
    required this.y,
    required this.revisionId,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.status = MindMapNodeStatus.notStarted,
    this.statusChangedAt,
    this.priority = MindMapNodePriority.medium,
    this.appearance = const MapNodeAppearance(),
    this.taskId,
    this.deletedAt,
  }) : title = requireMapTitle(title, 'title') {
    for (final (value, field) in [
      (ownerId, 'ownerId'),
      (mapId, 'mapId'),
      (id, 'id'),
      (revisionId, 'revisionId'),
    ]) {
      requireMapIdentity(value, field);
    }
    if (!x.isFinite || !y.isFinite) {
      throw ArgumentError('Node coordinates must be finite');
    }
    if (taskId != null) requireMapIdentity(taskId!, 'taskId');
    requireMapUtc(createdAt, 'createdAt');
    requireMapUtc(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(updatedAt, 'updatedAt');
    }
    if (statusChangedAt != null) {
      requireMapUtc(statusChangedAt!, 'statusChangedAt');
    }
    if (deletedAt != null) {
      if (kind == MindMapNodeKind.central) {
        throw ArgumentError('The central node cannot be deleted');
      }
      requireMapUtc(deletedAt!, 'deletedAt');
      if (deletedAt != updatedAt) {
        throw ArgumentError.value(deletedAt, 'deletedAt', 'must match version');
      }
    }
    appearance.validate();
  }

  final String ownerId;
  final String mapId;
  final String id;
  final MindMapNodeKind kind;
  final String title;
  final String? description;
  final double x;
  final double y;
  final MindMapNodeStatus status;
  final DateTime? statusChangedAt;
  final MindMapNodePriority priority;
  final MapNodeAppearance appearance;
  final String? taskId;
  final String revisionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
}
