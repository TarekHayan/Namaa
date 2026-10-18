/// Deterministic, non-production fixtures for Mind Maps 005 tests.
///
/// No wall clock, database, network, real account, or production secret is used.
/// Graph seeds describe future domain records without introducing production
/// models before the foundational phase.
library;

import 'dart:async';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

const String kMindMapsTestAccountA = '11111111-1111-1111-1111-111111111111';
const String kMindMapsTestAccountB = '22222222-2222-2222-2222-222222222222';
const String kMindMapsTestMapId = '00000000-0000-4000-8101-000000000001';
const String kMindMapsTestNodeId = '00000000-0000-4000-8102-000000000001';
const String kMindMapsTestEdgeId = '00000000-0000-4000-8103-000000000001';
const String kMindMapsTestTaskId = '00000000-0000-4000-8104-000000000001';

/// Repeatable identities for map-owned records, Tasks, and outbox operations.
///
/// A new source always starts at sequence one. Real graph relationships use
/// [parentSlotId] and [sideLinkId]; [nextEdgeId] is for test fakes that need a
/// separate edge UUID, not a replacement for those stable record identities.
final class MindMapsTestIds {
  int _map = 0;
  int _node = 0;
  int _edge = 0;
  int _task = 0;
  int _operation = 0;
  int _conflict = 0;

  String nextMapId() => _uuid(0x8101, ++_map);
  String nextNodeId() => _uuid(0x8102, ++_node);
  String nextEdgeId() => _uuid(0x8103, ++_edge);
  String nextTaskId() => _uuid(0x8104, ++_task);
  String nextOperationId() =>
      'mind-maps-test-operation-${(++_operation).toString().padLeft(4, '0')}';
  String nextConflictId() => _uuid(0x8105, ++_conflict);

  static String parentSlotId(String childNodeId) {
    if (childNodeId.trim().isEmpty) {
      throw ArgumentError.value(
        childNodeId,
        'childNodeId',
        'must not be blank',
      );
    }
    return 'parent:$childNodeId';
  }

  static String sideLinkId(String firstNodeId, String secondNodeId) {
    if (firstNodeId.trim().isEmpty || secondNodeId.trim().isEmpty) {
      throw ArgumentError('side-link endpoints must not be blank');
    }
    if (firstNodeId == secondNodeId) {
      throw ArgumentError.value(firstNodeId, 'firstNodeId', 'self-link');
    }
    final ordered = [firstNodeId, secondNodeId]..sort();
    return 'side:${ordered[0]}:${ordered[1]}';
  }

  static String _uuid(int variant, int sequence) {
    final group = variant.toRadixString(16).padLeft(4, '0');
    final suffix = sequence.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-4000-$group-$suffix';
  }
}

/// Explicit UTC clock for version ordering and account-switch races.
final class MindMapsTestClock {
  MindMapsTestClock({DateTime? initialUtc})
    : _now = initialUtc ?? DateTime.utc(2026, 10, 18, 9) {
    _requireUtc(_now);
  }

  DateTime _now;

  DateTime utcNow() => _now;

  /// Returns the current version then advances one microsecond.
  DateTime nextVersion() {
    final version = _now;
    _now = _now.add(const Duration(microseconds: 1));
    return version;
  }

  void advance(Duration duration) => _now = _now.add(duration);

  void setUtc(DateTime instant) {
    _requireUtc(instant);
    _now = instant;
  }

  static void _requireUtc(DateTime instant) {
    if (!instant.isUtc) {
      throw ArgumentError.value(instant, 'instant', 'must be UTC');
    }
  }
}

enum MindMapsTestNodeKind { central, mainIdea, branch, task, note }

/// Test-only node descriptor; [parentNodeId] models an active parent slot.
final class MindMapsTestNodeSeed {
  const MindMapsTestNodeSeed({
    required this.id,
    required this.title,
    required this.kind,
    this.parentNodeId,
    this.taskId,
  });

  final String id;
  final String title;
  final MindMapsTestNodeKind kind;
  final String? parentNodeId;
  final String? taskId;
}

/// Test-only visual link; endpoint order is canonical and layout-neutral.
final class MindMapsTestSideLinkSeed {
  MindMapsTestSideLinkSeed(String a, String b)
    : firstNodeId = a.compareTo(b) < 0 ? a : b,
      secondNodeId = a.compareTo(b) < 0 ? b : a {
    MindMapsTestIds.sideLinkId(a, b);
  }

  final String firstNodeId;
  final String secondNodeId;

  String get id => MindMapsTestIds.sideLinkId(firstNodeId, secondNodeId);
}

/// A known forest/tree and side-link set for restart and viewport scenarios.
final class MindMapsTestGraph {
  MindMapsTestGraph({
    required this.accountId,
    required this.mapId,
    required List<MindMapsTestNodeSeed> nodes,
    required List<MindMapsTestSideLinkSeed> sideLinks,
  }) : nodes = List.unmodifiable(nodes),
       sideLinks = List.unmodifiable(sideLinks);

  final String accountId;
  final String mapId;
  final List<MindMapsTestNodeSeed> nodes;
  final List<MindMapsTestSideLinkSeed> sideLinks;

  int get parentLinkCount =>
      nodes.where((node) => node.parentNodeId != null).length;
  int get connectionCount => parentLinkCount + sideLinks.length;

  /// Exactly 50 nodes, 49 acyclic parent links, and 11 distinct side links.
  /// Node 3 is task-kind and may reference a real test Task or remain unlinked.
  static MindMapsTestGraph fiftyNodesSixtyLinks({
    String accountId = kMindMapsTestAccountA,
    MindMapsTestIds? ids,
    String? linkedTaskId = kMindMapsTestTaskId,
  }) {
    final source = ids ?? MindMapsTestIds();
    final nodes = <MindMapsTestNodeSeed>[];
    for (var index = 0; index < 50; index++) {
      final kind = switch (index) {
        0 => MindMapsTestNodeKind.central,
        1 => MindMapsTestNodeKind.mainIdea,
        2 => MindMapsTestNodeKind.note,
        3 => MindMapsTestNodeKind.task,
        _ => MindMapsTestNodeKind.branch,
      };
      nodes.add(
        MindMapsTestNodeSeed(
          id: source.nextNodeId(),
          title: index == 0 ? 'Central idea' : 'Idea $index',
          kind: kind,
          parentNodeId: index == 0 ? null : nodes[(index - 1) ~/ 2].id,
          taskId: index == 3 ? linkedTaskId : null,
        ),
      );
    }
    final sideLinks = [
      for (var index = 0; index < 11; index++)
        MindMapsTestSideLinkSeed(nodes[index].id, nodes[index + 20].id),
    ];
    return MindMapsTestGraph(
      accountId: accountId,
      mapId: source.nextMapId(),
      nodes: nodes,
      sideLinks: sideLinks,
    );
  }
}

/// Failure checkpoint after any chosen fake row write, before its outbox write.
final class MindMapsTestFailingStore {
  int? _failAt;
  int _checkpointCount = 0;

  int get checkpointCount => _checkpointCount;

  void failAtCheckpoint(int number) {
    if (number < 1) {
      throw ArgumentError.value(number, 'number', 'must be positive');
    }
    _checkpointCount = 0;
    _failAt = number;
  }

  void checkpoint() {
    _checkpointCount++;
    if (_checkpointCount == _failAt) {
      _failAt = null;
      throw StateError('injected Mind Maps test store failure');
    }
  }

  void reset() {
    _checkpointCount = 0;
    _failAt = null;
  }
}

/// Mutable Foundation session for tests that switch owner during an await.
///
/// A paused lookup captures its starting owner. After release, a service must
/// read the session again before applying work from that old owner.
final class MindMapsTestSession implements CloudSessionPort {
  MindMapsTestSession({
    String? initialAccountId = kMindMapsTestAccountA,
    MindMapsTestClock? clock,
  }) : _accountId = initialAccountId,
       _status = initialAccountId == null
           ? CloudSessionStatus.signedOut
           : CloudSessionStatus.signedIn,
       _clock = clock ?? MindMapsTestClock();

  final MindMapsTestClock _clock;
  final StreamController<CloudSessionSnapshot> _changes =
      StreamController<CloudSessionSnapshot>.broadcast(sync: true);
  String? _accountId;
  CloudSessionStatus _status;
  Completer<void>? _nextLookupGate;

  CloudSessionSnapshot get snapshot =>
      CloudSessionSnapshot(status: _status, accountId: _accountId);

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => Stream.multi((controller) {
    // Subscribe before the initial value so an immediate switch cannot fall
    // between the snapshot and the change subscription.
    final subscription = _changes.stream.listen(
      controller.add,
      onDone: controller.close,
    );
    controller.add(snapshot);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async {
    final startingOwner = _status == CloudSessionStatus.signedIn
        ? _accountId
        : null;
    final gate = _nextLookupGate;
    _nextLookupGate = null;
    if (gate != null) await gate.future;
    if (startingOwner == null) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.authorization,
          messageKey: 'tasks.auth.sign_in_required',
          occurredAt: _clock.utcNow(),
        ),
      );
    }
    return AppResult.success(CloudSyncContext(accountId: startingOwner));
  }

  /// Pause the next lookup; complete the returned gate after switching owner.
  Completer<void> pauseNextLookup() {
    if (_nextLookupGate != null) {
      throw StateError('next session lookup is already paused');
    }
    return _nextLookupGate = Completer<void>();
  }

  void switchTo(String accountId) {
    if (accountId.trim().isEmpty) {
      throw ArgumentError.value(accountId, 'accountId', 'must not be blank');
    }
    _accountId = accountId;
    _status = CloudSessionStatus.signedIn;
    _changes.add(snapshot);
  }

  void signOut() {
    _accountId = null;
    _status = CloudSessionStatus.signedOut;
    _changes.add(snapshot);
  }

  void setUnknown() {
    _accountId = null;
    _status = CloudSessionStatus.unknown;
    _changes.add(snapshot);
  }

  Future<void> dispose() async {
    final gate = _nextLookupGate;
    if (gate != null && !gate.isCompleted) gate.complete();
    await _changes.close();
  }
}
