import 'package:uuid/uuid.dart';

class DiaryEntry {
  final String id;
  final String profileId;
  String content;
  String? aiCompletion;
  String? aiTitle;
  String? mood;
  List<String> extractedTodos;
  DateTime date;
  DateTime updatedAt;

  DiaryEntry({
    String? id,
    required this.profileId,
    required this.content,
    this.aiCompletion,
    this.aiTitle,
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
    'aiTitle': aiTitle,
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
    aiTitle: m['aiTitle'] as String?,
    mood: m['mood'] as String?,
    extractedTodos: List<String>.from(m['extractedTodos'] as List? ?? []),
    date: DateTime.parse(m['date'] as String),
    updatedAt: DateTime.parse(m['updatedAt'] as String),
  );

  DiaryEntry copyWith({
    String? content,
    String? aiCompletion,
    String? aiTitle,
    String? mood,
    List<String>? extractedTodos,
  }) => DiaryEntry(
    id: id,
    profileId: profileId,
    content: content ?? this.content,
    aiCompletion: aiCompletion ?? this.aiCompletion,
    aiTitle: aiTitle ?? this.aiTitle,
    mood: mood ?? this.mood,
    extractedTodos: extractedTodos ?? this.extractedTodos,
    date: date,
    updatedAt: DateTime.now(),
  );
}

class VlogEntry {
  final String id;
  final String profileId;
  String narrative;
  String? editedNarrative;
  String? aiTitle;
  final String style;
  final String performanceTag;
  final Map<String, dynamic> stats;
  final DateTime date;
  List<String> photoPaths;

  VlogEntry({
    required this.id,
    required this.profileId,
    required this.narrative,
    this.editedNarrative,
    this.aiTitle,
    required this.style,
    required this.performanceTag,
    required this.stats,
    required this.date,
    List<String>? photoPaths,
  }) : photoPaths = photoPaths ?? [];

  String get displayNarrative => editedNarrative?.isNotEmpty == true ? editedNarrative! : narrative;
  String get displayTitle => aiTitle?.isNotEmpty == true ? aiTitle! : '今日記錄';

  Map<String, dynamic> toMap() => {
    'id': id,
    'profileId': profileId,
    'narrative': narrative,
    'editedNarrative': editedNarrative,
    'aiTitle': aiTitle,
    'style': style,
    'performanceTag': performanceTag,
    'stats': stats,
    'date': date.toIso8601String(),
    'photoPaths': photoPaths,
  };

  factory VlogEntry.fromMap(Map<String, dynamic> m) => VlogEntry(
    id: m['id'] as String,
    profileId: m['profileId'] as String,
    narrative: m['narrative'] as String,
    editedNarrative: m['editedNarrative'] as String?,
    aiTitle: m['aiTitle'] as String?,
    style: m['style'] as String,
    performanceTag: m['performanceTag'] as String,
    stats: Map<String, dynamic>.from(m['stats'] as Map),
    date: DateTime.parse(m['date'] as String),
    photoPaths: List<String>.from(m['photoPaths'] as List? ?? []),
  );

  VlogEntry copyWith({
    String? editedNarrative,
    List<String>? photoPaths,
    String? aiTitle,
  }) => VlogEntry(
    id: id,
    profileId: profileId,
    narrative: narrative,
    editedNarrative: editedNarrative ?? this.editedNarrative,
    aiTitle: aiTitle ?? this.aiTitle,
    style: style,
    performanceTag: performanceTag,
    stats: stats,
    date: date,
    photoPaths: photoPaths ?? this.photoPaths,
  );
}

class MoodEntry {
  final String id;
  final String profileId;
  final DateTime date;
  final int score; // 1-5
  final String emoji;
  final String? note;

  MoodEntry({
    String? id,
    required this.profileId,
    required this.date,
    required this.score,
    required this.emoji,
    this.note,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'profileId': profileId,
    'date': date.toIso8601String(),
    'score': score,
    'emoji': emoji,
    'note': note,
  };

  factory MoodEntry.fromMap(Map<String, dynamic> m) => MoodEntry(
    id: m['id'] as String?,
    profileId: m['profileId'] as String,
    date: DateTime.parse(m['date'] as String),
    score: m['score'] as int,
    emoji: m['emoji'] as String,
    note: m['note'] as String?,
  );
}

class EnergyEntry {
  final String id;
  final String profileId;
  final DateTime date;
  final int score; // 1-10

  EnergyEntry({
    String? id,
    required this.profileId,
    required this.date,
    required this.score,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'profileId': profileId,
    'date': date.toIso8601String(),
    'score': score,
  };

  factory EnergyEntry.fromMap(Map<String, dynamic> m) => EnergyEntry(
    id: m['id'] as String?,
    profileId: m['profileId'] as String,
    date: DateTime.parse(m['date'] as String),
    score: m['score'] as int,
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
