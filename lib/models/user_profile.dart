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

// EXP thresholds per relationship level
const relationshipLevels = [
  '陌生人',     // 0 – 99
  '普通朋友',   // 100 – 299
  '熟悉',       // 300 – 599
  '好友',       // 600 – 999
  '曖昧',       // 1000 – 1499
  '親密',       // 1500+
];

const relationshipExpThresholds = [0, 100, 300, 600, 1000, 1500];

String expToRelationship(int exp) {
  for (int i = relationshipExpThresholds.length - 1; i >= 0; i--) {
    if (exp >= relationshipExpThresholds[i]) return relationshipLevels[i];
  }
  return '陌生人';
}

int nextRelationshipExp(int exp) {
  for (int i = 0; i < relationshipExpThresholds.length; i++) {
    if (exp < relationshipExpThresholds[i]) return relationshipExpThresholds[i];
  }
  return -1; // maxed out
}

// ── Personal growth level (repurposed from task EXP) ──────────────
// 完成目標 / 打卡累積的 EXP，反映使用者自己的成長，不再是「角色關係」。
const growthLevelTitles = [
  '初心者', '習慣養成', '穩定前進', '漸入佳境', '自律達人', '卓越者', '時光大師',
];
const growthExpThresholds = [0, 100, 300, 600, 1000, 1500, 2200];

int growthLevel(int exp) {
  int lv = 1;
  for (int i = 0; i < growthExpThresholds.length; i++) {
    if (exp >= growthExpThresholds[i]) lv = i + 1;
  }
  return lv;
}

String growthTitle(int exp) =>
    growthLevelTitles[(growthLevel(exp) - 1).clamp(0, growthLevelTitles.length - 1)];

/// EXP floor of the current level.
int growthLevelBase(int exp) {
  int base = 0;
  for (final t in growthExpThresholds) {
    if (exp >= t) base = t;
  }
  return base;
}

/// EXP needed to reach next level, or -1 if maxed out.
int growthNextExp(int exp) {
  for (final t in growthExpThresholds) {
    if (exp < t) return t;
  }
  return -1;
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
  String? characterName;
  DateTime createdAt;

  // New fields v4
  int loginStreak;
  int reviveCards;
  int characterExp;
  DateTime? lastProactiveDate;
  String? morningIntent;
  String? lastMorningIntentDate;

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
    this.characterName,
    DateTime? createdAt,
    this.loginStreak = 0,
    this.reviveCards = 1,
    this.characterExp = 0,
    this.lastProactiveDate,
    this.morningIntent,
    this.lastMorningIntentDate,
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

  String get relationshipLevel => expToRelationship(characterExp);
  int get nextRelationshipExpTarget => nextRelationshipExp(characterExp);
  int get currentLevelExp {
    for (int i = relationshipExpThresholds.length - 1; i >= 0; i--) {
      if (characterExp >= relationshipExpThresholds[i]) return relationshipExpThresholds[i];
    }
    return 0;
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
    'characterName': characterName,
    'createdAt': createdAt.toIso8601String(),
    'loginStreak': loginStreak,
    'reviveCards': reviveCards,
    'characterExp': characterExp,
    'lastProactiveDate': lastProactiveDate?.toIso8601String(),
    'morningIntent': morningIntent,
    'lastMorningIntentDate': lastMorningIntentDate,
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
    characterName: m['characterName'] as String?,
    createdAt: DateTime.parse(m['createdAt'] as String),
    loginStreak: m['loginStreak'] as int? ?? 0,
    reviveCards: m['reviveCards'] as int? ?? 1,
    characterExp: m['characterExp'] as int? ?? 0,
    lastProactiveDate: m['lastProactiveDate'] != null
        ? DateTime.tryParse(m['lastProactiveDate'] as String)
        : null,
    morningIntent: m['morningIntent'] as String?,
    lastMorningIntentDate: m['lastMorningIntentDate'] as String?,
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
    Object? characterName = _sentinel,
    int? loginStreak,
    int? reviveCards,
    int? characterExp,
    Object? lastProactiveDate = _sentinel,
    Object? morningIntent = _sentinel,
    Object? lastMorningIntentDate = _sentinel,
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
    characterName: characterName == _sentinel ? this.characterName : characterName as String?,
    createdAt: createdAt,
    loginStreak: loginStreak ?? this.loginStreak,
    reviveCards: reviveCards ?? this.reviveCards,
    characterExp: characterExp ?? this.characterExp,
    lastProactiveDate: lastProactiveDate == _sentinel ? this.lastProactiveDate : lastProactiveDate as DateTime?,
    morningIntent: morningIntent == _sentinel ? this.morningIntent : morningIntent as String?,
    lastMorningIntentDate: lastMorningIntentDate == _sentinel ? this.lastMorningIntentDate : lastMorningIntentDate as String?,
  );
}

const _sentinel = Object();
