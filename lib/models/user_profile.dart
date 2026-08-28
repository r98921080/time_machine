import 'package:uuid/uuid.dart';

enum BodyGoal { loseFat, gainMuscle, maintain }

enum CharacterMode { self, mirror }

extension BodyGoalExt on BodyGoal {
  String get label {
    switch (this) {
      case BodyGoal.loseFat: return '減脂';
      case BodyGoal.gainMuscle: return '增肌';
      case BodyGoal.maintain: return '維持';
    }
  }
  static BodyGoal fromString(String s) {
    switch (s) {
      case '增肌': return BodyGoal.gainMuscle;
      case '維持': return BodyGoal.maintain;
      default: return BodyGoal.loseFat;
    }
  }
}

class UserProfile {
  final String id;
  String nickname;
  BodyGoal goal;
  double dailyCalorieTarget;
  double? height;
  double? weight;
  int? age;
  String sex;
  int growthPoints;
  int streak;
  DateTime? lastLogDate;
  CharacterMode characterMode;
  String? mirrorGender;
  DateTime createdAt;

  UserProfile({
    String? id,
    required this.nickname,
    required this.goal,
    required this.dailyCalorieTarget,
    this.height,
    this.weight,
    this.age,
    this.sex = '男',
    this.growthPoints = 0,
    this.streak = 0,
    this.lastLogDate,
    this.characterMode = CharacterMode.self,
    this.mirrorGender,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  double get calculatedCalorieTarget {
    if (height != null && weight != null && age != null) {
      double bmr = sex == '女'
          ? 10 * weight! + 6.25 * height! - 5 * age! - 161
          : 10 * weight! + 6.25 * height! - 5 * age! + 5;
      double tdee = bmr * 1.375;
      switch (goal) {
        case BodyGoal.loseFat: return (tdee - 500).clamp(1200, 9999);
        case BodyGoal.gainMuscle: return tdee + 300;
        case BodyGoal.maintain: return tdee;
      }
    }
    return dailyCalorieTarget;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nickname': nickname,
    'goal': goal.label,
    'dailyCalorieTarget': dailyCalorieTarget,
    'height': height,
    'weight': weight,
    'age': age,
    'sex': sex,
    'growthPoints': growthPoints,
    'streak': streak,
    'lastLogDate': lastLogDate?.toIso8601String(),
    'characterMode': characterMode.name,
    'mirrorGender': mirrorGender,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    id: m['id'] as String?,
    nickname: m['nickname'] as String,
    goal: BodyGoalExt.fromString(m['goal'] as String),
    dailyCalorieTarget: (m['dailyCalorieTarget'] as num).toDouble(),
    height: (m['height'] as num?)?.toDouble(),
    weight: (m['weight'] as num?)?.toDouble(),
    age: m['age'] as int?,
    sex: m['sex'] as String? ?? '男',
    growthPoints: m['growthPoints'] as int? ?? 0,
    streak: m['streak'] as int? ?? 0,
    lastLogDate: m['lastLogDate'] != null
        ? DateTime.tryParse(m['lastLogDate'] as String)
        : null,
    characterMode: CharacterMode.values.firstWhere(
      (e) => e.name == m['characterMode'],
      orElse: () => CharacterMode.self,
    ),
    mirrorGender: m['mirrorGender'] as String?,
    createdAt: DateTime.parse(m['createdAt'] as String),
  );

  UserProfile copyWith({
    String? nickname,
    BodyGoal? goal,
    double? dailyCalorieTarget,
    double? height,
    double? weight,
    int? age,
    String? sex,
    int? growthPoints,
    int? streak,
    DateTime? lastLogDate,
    CharacterMode? characterMode,
    String? mirrorGender,
  }) => UserProfile(
    id: id,
    nickname: nickname ?? this.nickname,
    goal: goal ?? this.goal,
    dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
    height: height ?? this.height,
    weight: weight ?? this.weight,
    age: age ?? this.age,
    sex: sex ?? this.sex,
    growthPoints: growthPoints ?? this.growthPoints,
    streak: streak ?? this.streak,
    lastLogDate: lastLogDate ?? this.lastLogDate,
    characterMode: characterMode ?? this.characterMode,
    mirrorGender: mirrorGender ?? this.mirrorGender,
    createdAt: createdAt,
  );
}
