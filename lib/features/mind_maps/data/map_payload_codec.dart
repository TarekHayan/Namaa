import 'dart:convert';

import '../domain/map_connection.dart';
import '../domain/mind_map.dart';
import '../domain/mind_map_node.dart';

/// Stable, independently addressable payloads for the four graph record types.
final class MapPayloadCodec {
  const MapPayloadCodec();

  String encodeMap(MindMap map) => jsonEncode({
    'ownerId': map.ownerId,
    'id': map.id,
    'title': map.title,
    'description': map.description,
    'centralNodeId': map.centralNodeId,
    'settings': _settings(map.settings),
    'revisionId': map.revisionId,
    'createdAt': _date(map.createdAt),
    'updatedAt': _date(map.updatedAt),
    'deletedAt': _dateOrNull(map.deletedAt),
  });

  MindMap decodeMap(String payload) => _decode('map', () {
    final value = _object(payload);
    return MindMap(
      ownerId: value['ownerId'] as String,
      id: value['id'] as String,
      title: value['title'] as String,
      description: value['description'] as String?,
      centralNodeId: value['centralNodeId'] as String,
      settings: _readSettings(value['settings'] as Map<String, dynamic>),
      revisionId: value['revisionId'] as String,
      createdAt: _readDate(value['createdAt']),
      updatedAt: _readDate(value['updatedAt']),
      deletedAt: _readOptionalDate(value['deletedAt']),
    );
  });

  String encodeNode(MindMapNode node) => jsonEncode({
    'ownerId': node.ownerId,
    'mapId': node.mapId,
    'id': node.id,
    'kind': node.kind.name,
    'title': node.title,
    'description': node.description,
    'x': node.x,
    'y': node.y,
    'status': node.status.name,
    'statusChangedAt': _dateOrNull(node.statusChangedAt),
    'priority': node.priority.name,
    'appearance': _nodeAppearance(node.appearance),
    'taskId': node.taskId,
    'revisionId': node.revisionId,
    'createdAt': _date(node.createdAt),
    'updatedAt': _date(node.updatedAt),
    'deletedAt': _dateOrNull(node.deletedAt),
  });

  MindMapNode decodeNode(String payload) => _decode('node', () {
    final value = _object(payload);
    return MindMapNode(
      ownerId: value['ownerId'] as String,
      mapId: value['mapId'] as String,
      id: value['id'] as String,
      kind: MindMapNodeKind.values.byName(value['kind'] as String),
      title: value['title'] as String,
      description: value['description'] as String?,
      x: (value['x'] as num).toDouble(),
      y: (value['y'] as num).toDouble(),
      status: MindMapNodeStatus.values.byName(value['status'] as String),
      statusChangedAt: _readOptionalDate(value['statusChangedAt']),
      priority: MindMapNodePriority.values.byName(value['priority'] as String),
      appearance: _readNodeAppearance(
        value['appearance'] as Map<String, dynamic>,
      ),
      taskId: value['taskId'] as String?,
      revisionId: value['revisionId'] as String,
      createdAt: _readDate(value['createdAt']),
      updatedAt: _readDate(value['updatedAt']),
      deletedAt: _readOptionalDate(value['deletedAt']),
    );
  });

  String encodeParentSlot(ParentSlot slot) => jsonEncode({
    'ownerId': slot.ownerId,
    'mapId': slot.mapId,
    'childNodeId': slot.childNodeId,
    'parentNodeId': slot.parentNodeId,
    'appearance': _connectionAppearance(slot.appearance),
    'revisionId': slot.revisionId,
    'updatedAt': _date(slot.updatedAt),
    'deletedAt': _dateOrNull(slot.deletedAt),
  });

  ParentSlot decodeParentSlot(String payload) => _decode('parent slot', () {
    final value = _object(payload);
    return ParentSlot(
      ownerId: value['ownerId'] as String,
      mapId: value['mapId'] as String,
      childNodeId: value['childNodeId'] as String,
      parentNodeId: value['parentNodeId'] as String,
      appearance: _readConnectionAppearance(
        value['appearance'] as Map<String, dynamic>,
      ),
      revisionId: value['revisionId'] as String,
      updatedAt: _readDate(value['updatedAt']),
      deletedAt: _readOptionalDate(value['deletedAt']),
    );
  });

  String encodeSideLink(SideLink link) => jsonEncode({
    'ownerId': link.ownerId,
    'mapId': link.mapId,
    'firstNodeId': link.firstNodeId,
    'secondNodeId': link.secondNodeId,
    'appearance': _connectionAppearance(link.appearance),
    'revisionId': link.revisionId,
    'updatedAt': _date(link.updatedAt),
    'deletedAt': _dateOrNull(link.deletedAt),
  });

  SideLink decodeSideLink(String payload) => _decode('side link', () {
    final value = _object(payload);
    return SideLink(
      ownerId: value['ownerId'] as String,
      mapId: value['mapId'] as String,
      firstNodeId: value['firstNodeId'] as String,
      secondNodeId: value['secondNodeId'] as String,
      appearance: _readConnectionAppearance(
        value['appearance'] as Map<String, dynamic>,
      ),
      revisionId: value['revisionId'] as String,
      updatedAt: _readDate(value['updatedAt']),
      deletedAt: _readOptionalDate(value['deletedAt']),
    );
  });

  T _decode<T>(String kind, T Function() read) {
    try {
      return read();
    } on Object catch (error) {
      throw FormatException('Invalid Mind Maps $kind payload', error);
    }
  }

  Map<String, dynamic> _object(String payload) =>
      jsonDecode(payload) as Map<String, dynamic>;

  String _date(DateTime date) => date.toUtc().toIso8601String();
  String? _dateOrNull(DateTime? date) => date == null ? null : _date(date);
  DateTime _readDate(Object? value) => DateTime.parse(value as String).toUtc();
  DateTime? _readOptionalDate(Object? value) =>
      value == null ? null : _readDate(value);

  Map<String, dynamic> _settings(MindMapSettings value) => {
    'layout': value.layout.name,
    'backgroundArgb': value.backgroundArgb,
    'defaultNode': _nodeAppearance(value.defaultNode),
    'defaultConnection': _connectionAppearance(value.defaultConnection),
    'spacing': value.spacing,
  };

  MindMapSettings _readSettings(Map<String, dynamic> value) => MindMapSettings(
    layout: MapLayout.values.byName(value['layout'] as String),
    backgroundArgb: value['backgroundArgb'] as int,
    defaultNode: _readNodeAppearance(
      value['defaultNode'] as Map<String, dynamic>,
    ),
    defaultConnection: _readConnectionAppearance(
      value['defaultConnection'] as Map<String, dynamic>,
    ),
    spacing: (value['spacing'] as num).toDouble(),
  );

  Map<String, dynamic> _nodeAppearance(MapNodeAppearance value) => {
    'argb': value.argb,
    'icon': value.icon,
    'shape': value.shape.name,
    'nodeSize': value.nodeSize.name,
    'textSize': value.textSize.name,
  };

  MapNodeAppearance _readNodeAppearance(Map<String, dynamic> value) =>
      MapNodeAppearance(
        argb: value['argb'] as int,
        icon: value['icon'] as String,
        shape: MapNodeShape.values.byName(value['shape'] as String),
        nodeSize: MapSize.values.byName(value['nodeSize'] as String),
        textSize: MapSize.values.byName(value['textSize'] as String),
      );

  Map<String, dynamic> _connectionAppearance(MapConnectionAppearance value) => {
    'argb': value.argb,
    'width': value.width,
  };

  MapConnectionAppearance _readConnectionAppearance(
    Map<String, dynamic> value,
  ) => MapConnectionAppearance(
    argb: value['argb'] as int,
    width: (value['width'] as num).toDouble(),
  );
}
