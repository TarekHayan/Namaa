/// One lightweight step inside a Task aggregate.
///
/// Checklist items are value data owned by their parent Task. They do not
/// carry independent scheduling, category, reward, or synchronization state.
final class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.text,
    required this.completed,
    required this.order,
  });

  final String id;
  final String text;
  final bool completed;
  final int order;

  /// Creates a new Task-owned step with normalized user text.
  factory ChecklistItem.create({
    required String id,
    required String text,
    required int order,
  }) {
    final normalizedId = id.trim();
    final normalizedText = text.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be blank');
    }
    if (normalizedText.isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be blank');
    }
    if (order < 0) {
      throw ArgumentError.value(order, 'order', 'must not be negative');
    }
    return ChecklistItem(
      id: normalizedId,
      text: normalizedText,
      completed: false,
      order: order,
    );
  }

  ChecklistItem editText(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, 'text', 'must not be blank');
    }
    return copyWith(text: normalized);
  }

  ChecklistItem setCompleted(bool value) => copyWith(completed: value);

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? completed,
    int? order,
  }) => ChecklistItem(
    id: id ?? this.id,
    text: text ?? this.text,
    completed: completed ?? this.completed,
    order: order ?? this.order,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItem &&
          id == other.id &&
          text == other.text &&
          completed == other.completed &&
          order == other.order;

  @override
  int get hashCode => Object.hash(id, text, completed, order);
}
