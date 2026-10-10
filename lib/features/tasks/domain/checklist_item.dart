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
