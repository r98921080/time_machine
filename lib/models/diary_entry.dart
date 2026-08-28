import 'package:uuid/uuid.dart';

class DiaryEntry {
  final String id;
  final String profileId;
  String content;
  String? aiCompletion;
  String? mood;
  List<String> extractedTodos;
  DateTime date;
  DateTime updatedAt;

  DiaryEntry({
    String? id,
    required this.profileId,
    required this.content,
    this.aiCompletion,
    this.mood,
    List<String>? extractedTodos,
    required this.date,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       extractedTodos = extractedTodos ?? [],
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'profileId': profileId,
    'content': content,
    'aiCompletion': aiCompletion,
    'mood': mood,
    'extractedTodos': extractedTodos,
    'date': date.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DiaryEntry.fromMap(Map<String, dynamic> m) => DiaryEntry(
    id: m['id'] as String?,
    profileId: m['profileId'] as String,
    content: m['content'] as String,
    aiCompletion: m['aiCompletion'] as String?,
    mood: m['mood'] as String?,
    extractedTodos: List<String>.from(m['extractedTodos'] as List? ?? []),
    date: DateTime.parse(m['date'] as String),
    updatedAt: DateTime.parse(m['updatedAt'] as String),
  );
}

class VlogEntry {
  final String id;
  final String profileId;
  final String narrative;
  final String style;
  final String performanceTag;
  final Map<String, dynamic> stats;
  final DateTime date;

  const VlogEntry({
    required this.id,
    required this.profileId,
    required this.narrative,
    required this.style,
    required this.performanceTag,
    required this.stats,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'profileId': profileId,
    'narrative': narrative,
    'style': style,
    'performanceTag': performanceTag,
    'stats': stats,
    'date': date.toIso8601String(),
  };

  factory VlogEntry.fromMap(Map<String, dynamic> m) => VlogEntry(
    id: m['id'] as String,
    profileId: m['profileId'] as String,
    narrative: m['narrative'] as String,
    style: m['style'] as String,
    performanceTag: m['performanceTag'] as String,
    stats: Map<String, dynamic>.from(m['stats'] as Map),
    date: DateTime.parse(m['date'] as String),
  );
}

class KnowledgeQuestion {
  final String id;
  final String question;
  final String correctAnswer;
  final String wrongAnswer1;
  final String wrongAnswer2;
  final String explanation;
  final String category;
  final DateTime date;

  const KnowledgeQuestion({
    required this.id,
    required this.question,
    required this.correctAnswer,
    required this.wrongAnswer1,
    required this.wrongAnswer2,
    required this.explanation,
    required this.category,
    required this.date,
  });

  factory KnowledgeQuestion.fromMap(Map<String, dynamic> m) => KnowledgeQuestion(
    id: m['id'] as String,
    question: m['question'] as String,
    correctAnswer: m['correctAnswer'] as String,
    wrongAnswer1: m['wrongAnswer1'] as String,
    wrongAnswer2: m['wrongAnswer2'] as String,
    explanation: m['explanation'] as String,
    category: m['category'] as String,
    date: DateTime.parse(m['date'] as String),
  );
}
