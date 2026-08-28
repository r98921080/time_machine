import 'package:uuid/uuid.dart';

class BonusChallenge {
  final String id;
  final String profileId;
  final String title;
  final String type; // physical / dietary / emotional
  final String date; // YYYY-MM-DD
  bool done;
  final int points;
  DateTime? doneAt;

  BonusChallenge({
    String? id,
    required this.profileId,
    required this.title,
    required this.type,
    required this.date,
    this.done = false,
    this.points = 10,
    this.doneAt,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'profileId': profileId,
        'title': title,
        'type': type,
        'date': date,
        'done': done ? 1 : 0,
        'points': points,
        'doneAt': doneAt?.toIso8601String(),
      };

  factory BonusChallenge.fromMap(Map<String, dynamic> m) => BonusChallenge(
        id: m['id'] as String,
        profileId: m['profileId'] as String,
        title: m['title'] as String,
        type: m['type'] as String,
        date: m['date'] as String,
        done: (m['done'] as int) == 1,
        points: m['points'] as int? ?? 10,
        doneAt: m['doneAt'] != null
            ? DateTime.tryParse(m['doneAt'] as String)
            : null,
      );
}
