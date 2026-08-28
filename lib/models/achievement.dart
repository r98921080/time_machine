import 'package:uuid/uuid.dart';

class Achievement {
  final String id;
  final String profileId;
  final String key;
  final DateTime unlockedAt;

  Achievement({
    String? id,
    required this.profileId,
    required this.key,
    required this.unlockedAt,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'profileId': profileId,
    'key': key,
    'unlockedAt': unlockedAt.toIso8601String(),
  };

  factory Achievement.fromMap(Map<String, dynamic> m) => Achievement(
    id: m['id'] as String?,
    profileId: m['profileId'] as String,
    key: m['key'] as String,
    unlockedAt: DateTime.parse(m['unlockedAt'] as String),
  );
}

class AchievementDef {
  final String key;
  final String emoji;
  final String title;
  final String description;
  final String category;

  const AchievementDef({
    required this.key,
    required this.emoji,
    required this.title,
    required this.description,
    required this.category,
  });
}

class Achievements {
  static const List<AchievementDef> all = [
    AchievementDef(key: 'first_record', emoji: '🌱', title: '時光旅程', description: '第一次記錄今日飲食', category: '記錄'),
    AchievementDef(key: 'streak_3', emoji: '🔥', title: '三日燃燒', description: '連續記錄3天', category: '連續'),
    AchievementDef(key: 'streak_7', emoji: '⚡', title: '一週戰士', description: '連續記錄7天', category: '連續'),
    AchievementDef(key: 'streak_30', emoji: '👑', title: '月度傳說', description: '連續記錄30天', category: '連續'),
    AchievementDef(key: 'calorie_goal_5', emoji: '🎯', title: '熱量達標', description: '5次達到每日熱量目標', category: '飲食'),
    AchievementDef(key: 'goal_elite', emoji: '🏆', title: '精英首達', description: '第一次完成精英等級目標', category: '目標'),
    AchievementDef(key: 'goal_10', emoji: '💪', title: '目標十連', description: '累計完成10個目標', category: '目標'),
    AchievementDef(key: 'goal_50', emoji: '🌟', title: '目標達人', description: '累計完成50個目標', category: '目標'),
    AchievementDef(key: 'chat_10', emoji: '💬', title: '聊天達人', description: '與角色聊天10次', category: '角色'),
    AchievementDef(key: 'relationship_up', emoji: '💖', title: '感情升溫', description: '關係等級首次提升', category: '角色'),
    AchievementDef(key: 'relationship_intimate', emoji: '💞', title: '心有靈犀', description: '與角色達到「親密」關係', category: '角色'),
    AchievementDef(key: 'diary_10', emoji: '📖', title: '日記本', description: '寫了10篇日記', category: '日記'),
    AchievementDef(key: 'vlog_30', emoji: '🎬', title: '時光紀錄', description: '累積30天Vlog', category: 'Vlog'),
    AchievementDef(key: 'shop_first', emoji: '🛍️', title: '初次購物', description: '在裝備商店第一次消費', category: '商店'),
    AchievementDef(key: 'shop_outfit', emoji: '👗', title: '時尚達人', description: '擁有3件以上服飾', category: '商店'),
    AchievementDef(key: 'mood_check_7', emoji: '😊', title: '心情觀察家', description: '連續7天記錄情緒', category: '健康'),
    AchievementDef(key: 'energy_high', emoji: '⚡', title: '能量滿格', description: '精力評分達到9分以上', category: '健康'),
    AchievementDef(key: 'morning_intent_7', emoji: '🌅', title: '晨間習慣', description: '連續7天設定晨間意圖', category: '習慣'),
    AchievementDef(key: 'year_memory', emoji: '⏰', title: '時光旅人', description: '看到「一年前的今天」回憶', category: '時光機'),
    AchievementDef(key: 'explore_first', emoji: '🔭', title: '深度探索', description: '第一次使用深度探索分析', category: '探索'),
  ];

  static AchievementDef? get(String key) {
    try {
      return all.firstWhere((a) => a.key == key);
    } catch (_) {
      return null;
    }
  }
}
