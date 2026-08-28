import 'package:uuid/uuid.dart';

enum GoalLevel { mini, advanced, elite }

extension GoalLevelExt on GoalLevel {
  String get label {
    switch (this) {
      case GoalLevel.mini: return '入門';
      case GoalLevel.advanced: return '進階';
      case GoalLevel.elite: return '精英';
    }
  }
  int get points {
    switch (this) {
      case GoalLevel.mini: return 1;
      case GoalLevel.advanced: return 2;
      case GoalLevel.elite: return 3;
    }
  }
}

class GoalSubItem {
  final String id;
  String name;
  String miniTarget;
  String advancedTarget;
  String eliteTarget;

  GoalSubItem({
    String? id,
    required this.name,
    required this.miniTarget,
    required this.advancedTarget,
    required this.eliteTarget,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'miniTarget': miniTarget,
    'advancedTarget': advancedTarget,
    'eliteTarget': eliteTarget,
  };

  factory GoalSubItem.fromMap(Map<String, dynamic> m) => GoalSubItem(
    id: m['id'] as String?,
    name: m['name'] as String,
    miniTarget: m['miniTarget'] as String,
    advancedTarget: m['advancedTarget'] as String,
    eliteTarget: m['eliteTarget'] as String,
  );
}

class GoalCategory {
  final String id;
  String title;
  List<GoalSubItem> subItems;
  bool isExpanded;

  GoalCategory({
    String? id,
    required this.title,
    List<GoalSubItem>? subItems,
    this.isExpanded = false,
  }) : id = id ?? const Uuid().v4(),
       subItems = subItems ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'subItems': subItems.map((s) => s.toMap()).toList(),
  };

  factory GoalCategory.fromMap(Map<String, dynamic> m) => GoalCategory(
    id: m['id'] as String?,
    title: m['title'] as String,
    subItems: (m['subItems'] as List<dynamic>)
        .map((s) => GoalSubItem.fromMap(s as Map<String, dynamic>))
        .toList(),
  );
}

class DailyGoalLog {
  final String id;
  final String profileId;
  final String subItemId;
  final GoalLevel achieved;
  final int score;
  final String? note;
  final DateTime date;

  DailyGoalLog({
    String? id,
    required this.profileId,
    required this.subItemId,
    required this.achieved,
    required this.score,
    this.note,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'profileId': profileId,
    'subItemId': subItemId,
    'achieved': achieved.name,
    'score': score,
    'note': note,
    'date': date.toIso8601String(),
  };

  factory DailyGoalLog.fromMap(Map<String, dynamic> m) => DailyGoalLog(
    id: m['id'] as String?,
    profileId: m['profileId'] as String,
    subItemId: m['subItemId'] as String,
    achieved: GoalLevel.values.firstWhere((e) => e.name == m['achieved']),
    score: m['score'] as int,
    note: m['note'] as String?,
    date: DateTime.parse(m['date'] as String),
  );
}
