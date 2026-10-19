import 'package:namma_project/core/domain/results/app_result.dart';

/// A privacy-safe view of a Task owned by the active account.
final class MapLinkedTask {
  const MapLinkedTask.available({
    required this.id,
    required this.title,
    required this.completed,
    required this.completionChangedAt,
  }) : available = true;

  const MapLinkedTask.unavailable(this.id)
    : available = false,
      title = null,
      completed = false,
      completionChangedAt = null;

  final String id;
  final bool available;
  final String? title;
  final bool completed;
  final DateTime? completionChangedAt;
}

abstract interface class MapTaskLinkPort {
  /// An authenticated chooser is complete only after initial Task sync.
  Future<AppResult<void>> ensurePickerReady(String expectedOwner);
  Stream<List<MapLinkedTask>> watchAccessibleTasks(String expectedOwner);
  Future<AppResult<MapLinkedTask>> readLinkedTask(
    String expectedOwner,
    String taskId,
  );
  Future<AppResult<void>> complete(String expectedOwner, String taskId);
  Future<AppResult<void>> reopen(String expectedOwner, String taskId);
}
