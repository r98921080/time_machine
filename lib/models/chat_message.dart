import 'package:uuid/uuid.dart';

class CharacterChatMessage {
  final String id;
  final String profileId;
  final String role; // 'user' | 'character'
  final String content;
  final DateTime timestamp;

  CharacterChatMessage({
    String? id,
    required this.profileId,
    required this.role,
    required this.content,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();
}
