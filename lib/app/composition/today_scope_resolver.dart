/// Closed Today owner mapping at the application composition boundary.
library;

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';

import 'habits_preview_adapters.dart' show kHabitsPreviewAccountId;
import 'tasks_preview_adapters.dart' show kTasksPreviewAccountId;

final class TodayScopeResolver {
  TodayScopeResolver.preview() : _isPreview = true, _session = null;

  TodayScopeResolver.account(CloudSessionPort session)
    : _isPreview = false,
      _session = session;

  final bool _isPreview;
  final CloudSessionPort? _session;
  int _generation = 0;
  TodayScope? _current;

  TodayScope? get current => _current;

  /// Clears the old binding before any asynchronous identity lookup.
  void invalidate() {
    _generation++;
    _current = null;
  }

  /// Handles initial account lookup, guarded against newer session events.
  Future<TodayScope?> resolveInitial() async {
    invalidate();
    final generation = _generation;
    if (_isPreview) return _bindPreview(generation);
    return _resolveAccount(generation);
  }

  /// Call for each observed session event. Unknown and signed-out mode expose
  /// no previous account; a signed-in event must agree with the session port.
  Future<TodayScope?> resolveSnapshot(CloudSessionSnapshot snapshot) async {
    invalidate();
    final generation = _generation;
    if (_isPreview) return _bindPreview(generation);
    final expectedAccountId = snapshot.accountId;
    if (snapshot.status != CloudSessionStatus.signedIn ||
        !_isValidRealAccount(expectedAccountId)) {
      return null;
    }
    return _resolveAccount(generation, expectedAccountId: expectedAccountId);
  }

  TodayScope? _bindPreview(int generation) {
    if (generation != _generation) return null;
    return _current = TodayScope.preview(
      taskOwnerId: kTasksPreviewAccountId,
      habitOwnerId: kHabitsPreviewAccountId,
      generation: generation,
    );
  }

  Future<TodayScope?> _resolveAccount(
    int generation, {
    String? expectedAccountId,
  }) async {
    String? accountId;
    try {
      accountId = (await _session!.obtainSyncContext()).valueOrNull?.accountId;
    } catch (_) {
      // A failed identity lookup is unresolved; never reuse cached business
      // data. The app's session gate owns localized recovery and retry.
      return null;
    }
    if (generation != _generation ||
        !_isValidRealAccount(accountId) ||
        (expectedAccountId != null && accountId != expectedAccountId)) {
      return null;
    }
    return _current = TodayScope.account(
      accountId: accountId!,
      generation: generation,
    );
  }

  static bool _isValidRealAccount(String? accountId) =>
      accountId != null &&
      accountId.trim().isNotEmpty &&
      accountId != kTasksPreviewAccountId &&
      accountId != kHabitsPreviewAccountId;
}
