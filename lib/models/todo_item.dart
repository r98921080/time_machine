import 'package:uuid/uuid.dart';

class TodoItem {
  final String id;
  final String profileId;
  final String content;
  bool done;
  final DateTime createdAt;
  DateTime? doneAt;

  TodoItem({
    String? id,
    required this.profileId,
    required this.content,
    this.done = false,
    DateTime? createdAt,
    this.doneAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'profileId': profileId,
        'content': content,
        'done': done ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'doneAt': doneAt?.toIso8601String(),
      };

  factory TodoItem.fromMap(Map<String, dynamic> m) => TodoItem(
        id: m['id'] as String,
        profileId: m['profileId'] as String,
        content: m['content'] as String,
        done: (m['done'] as int) == 1,
        createdAt: DateTime.parse(m['createdAt'] as String),
        doneAt: m['doneAt'] != null
            ? DateTime.tryParse(m['doneAt'] as String)
            : null,
      );
}
