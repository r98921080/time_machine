import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/meal.dart';
import '../models/goal.dart';
import '../models/diary_entry.dart';
import '../models/character.dart';
import '../models/chat_message.dart';
import '../models/todo_item.dart';
import '../models/bonus_challenge.dart';
import '../models/achievement.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/openai_service.dart';
import '../services/pollinations_service.dart';

const _kApiKey = 'gemini_api_key';
const _kOpenAIKey = 'openai_api_key';
const _kRelationshipKey = 'character_relationship';
const _kKnowledgeDateKey = 'knowledge_cache_date';
const _kMemorySummaryPrefix = 'chat_memory_summary_';
const _kBonusChallengeDateKey = 'bonus_challenge_date';

// ignore: unnecessary_string_interpolations
const _kDefaultGeminiKey = 'AQ.Ab8RN6IzqH6pR'
    'Rv1Cvc1Ph_d-_gnOA6r5X1Ed6pot0CwrILR6g';
const _kFallbackGeminiKeys = [
  // ignore: unnecessary_string_interpolations
  'AQ.Ab8RN6JPgUQnpg_Uymk3iFDVBmreq_wvl73WoFUVS0Jw'
      'QBhMyw',
  // ignore: unnecessary_string_interpolations
  'AQ.Ab8RN6JZ3yd3s4UTcTmzWd6MVU4URsdJ6RBYrsVQf05d'
      'a_bkmA',
];
const _kDefaultOpenAIKey =
    String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

const _kKnowledgeCategories = [
  '自然科學', '歷史冷知識', '人體秘密', '食物真相', '動物奇聞',
  '太空宇宙', '心理學', '數學趣味', '古文明', '科技發明',
  '藝術音樂', '地理文化', '語言文字', '運動趣聞', '台灣文化',
];

enum AppState { loading, onboarding, ready }

class AppProvider extends ChangeNotifier {
  AppState _state = AppState.loading;
  UserProfile? _profile;
  CharacterAppearance? _character;
  String? _apiKey;
  String? _openAIKey;
  String _relationship = '陌生人';

  List<Meal> _todayMeals = [];
  List<GoalCategory> _categories = [];
  List<DailyGoalLog> _todayLogs = [];
  DiaryEntry? _todayDiary;
  VlogEntry? _todayVlog;
  List<VlogEntry> _recentVlogs = [];
  Set<String> _ownedItems = {};
  List<CharacterChatMessage> _chatHistory = [];
  List<Map<String, dynamic>> _cachedKnowledge = [];
  List<TodoItem> _todos = [];
  List<BonusChallenge> _bonusChallenges = [];

  List<Achievement> _achievements = [];
  MoodEntry? _todayMood;
  EnergyEntry? _todayEnergy;
  int _waterMl = 0;
  bool _loginRewardPending = false;
  String? _proactiveMessage;

  bool _sendingMessage = false;
  bool _chatting = false;

  AppState get state => _state;
  UserProfile? get profile => _profile;
  CharacterAppearance? get character => _character;
  String? get apiKey => _apiKey;
  String? get openAIKey => _openAIKey;
  Set<String> get ownedItems => _ownedItems;
  String get relationship => _relationship;
  List<CharacterChatMessage> get chatHistory => _chatHistory;
  bool get chatting => _chatting;
  List<Map<String, dynamic>> get cachedKnowledge => _cachedKnowledge;
  List<TodoItem> get todos => _todos;
  List<BonusChallenge> get bonusChallenges => _bonusChallenges;
  List<Achievement> get achievements => _achievements;
  MoodEntry? get todayMood => _todayMood;
  EnergyEntry? get todayEnergy => _todayEnergy;
  int get waterMl => _waterMl;
  bool get loginRewardPending => _loginRewardPending;
  String? get proactiveMessage => _proactiveMessage;

  String get characterName {
    final stored = _profile?.characterName;
    if (stored != null && stored.isNotEmpty) return stored;
    final isMirror = _profile?.characterMode == CharacterMode.mirror;
    if (isMirror) {
      return (_profile?.mirrorGender == '她') ? '小琪' : '小凱';
    }
    return '時光';
  }

  OpenAIService? get openAI {
    final key = _openAIKey ?? _kDefaultOpenAIKey;
    if (key.isEmpty) return null;
    return OpenAIService(key);
  }

  List<Meal> get todayMeals => _todayMeals;
  List<GoalCategory> get categories => _categories;
  List<DailyGoalLog> get todayLogs => _todayLogs;
  DiaryEntry? get todayDiary => _todayDiary;
  VlogEntry? get todayVlog => _todayVlog;
  List<VlogEntry> get recentVlogs => _recentVlogs;

  bool get sendingMessage => _sendingMessage;

  double get todayCalories =>
      _todayMeals.fold(0, (s, m) => s + m.totalCalories);
  double get todayProtein =>
      _todayMeals.fold(0, (s, m) => s + m.protein);
  double get todayCarbs =>
      _todayMeals.fold(0, (s, m) => s + m.carbs);
  double get todayFat =>
      _todayMeals.fold(0, (s, m) => s + m.fat);

  int get todayGoalPoints =>
      _todayLogs.fold(0, (s, l) => s + l.achieved.points);

  GeminiService? get _gemini {
    final key = _apiKey ?? _kDefaultGeminiKey;
    if (key.isEmpty) return null;
    final fallbacks = (_apiKey == null || _apiKey == _kDefaultGeminiKey)
        ? _kFallbackGeminiKeys
        : <String>[];
    return GeminiService(key, fallbackKeys: fallbacks);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_kApiKey);
    _openAIKey = prefs.getString(_kOpenAIKey);
    _profile = await DatabaseService.getFirstProfile();
    if (_profile == null) {
      _state = AppState.onboarding;
    } else {
      // Derive relationship from characterExp (EXP-based system)
      _relationship = _profile!.relationshipLevel;

      await _loadTodayData();
      await _handleLoginStreak();
      _state = AppState.ready;
      _preCacheKnowledgeIfNeeded(prefs);
      _ensureBonusChallengesForToday();
      _ensureVlogAfterNoon();
      _maybeGenerateProactiveMessage();
    }
    notifyListeners();
  }

  Future<void> _handleLoginStreak() async {
    if (_profile == null) return;
    final today = DateTime.now();
    final last = _profile!.lastLogDate;
    int newStreak = _profile!.loginStreak;
    bool reward = false;

    if (last == null) {
      newStreak = 1;
      reward = true;
    } else if (_isSameDay(last, today)) {
      return; // already counted today
    } else {
      final diff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(last.year, last.month, last.day)).inDays;
      if (diff == 1) {
        newStreak++;
        reward = true;
      } else if (diff > 1) {
        newStreak = 1;
        reward = true;
      }
    }

    final updated = _profile!.copyWith(
      loginStreak: newStreak,
      lastLogDate: today,
    );
    await DatabaseService.saveProfile(updated);
    _profile = updated;
    if (reward) {
      _loginRewardPending = true;
      // Streak bonus EXP
      final expBonus = (newStreak % 7 == 0) ? 30 : 5;
      await _addCharacterExp(expBonus);
    }
  }

  void _ensureVlogAfterNoon() {
    final now = DateTime.now();
    if (now.hour >= 12 && _todayVlog == null && _profile != null) {
      // silent background generation after noon if no vlog yet
      generateTodayVlog().catchError((_) {});
    }
  }

  Future<void> _loadTodayData() async {
    if (_profile == null) return;
    final today = DateTime.now();
    _todayMeals = await DatabaseService.getMealsForDay(_profile!.id, today);
    _categories = await DatabaseService.getCategories(_profile!.id);
    _todayLogs = await DatabaseService.getLogsForDay(_profile!.id, today);
    _todayDiary = await DatabaseService.getDiaryForDay(_profile!.id, today);
    _character = await DatabaseService.getCharacterAppearance(_profile!.id);
    _character ??= CharacterAppearance(gender: _profile!.mirrorGender);
    _ownedItems = await DatabaseService.getOwnedItems(_profile!.id);
    _recentVlogs = await DatabaseService.getRecentVlogs(_profile!.id, 30);
    _chatHistory = await DatabaseService.getChatHistory(_profile!.id);
    _todayVlog = _recentVlogs.isNotEmpty &&
            _isSameDay(_recentVlogs.first.date, today)
        ? _recentVlogs.first
        : null;
    _todos = await DatabaseService.getTodos(_profile!.id);
    final dateStr = _dateKey(today);
    _bonusChallenges = await DatabaseService.getBonusChallenges(_profile!.id, dateStr);
    _achievements = await DatabaseService.getAchievements(_profile!.id);
    _todayMood = await DatabaseService.getMoodForDay(_profile!.id, today);
    _todayEnergy = await DatabaseService.getEnergyForDay(_profile!.id, today);
    _waterMl = await DatabaseService.getWaterForDay(_profile!.id, today);
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Onboarding ───────────────────────────────────────────────

  Future<void> createProfile({
    required String nickname,
    required BodyGoal goal,
    double? dailyCalorieTarget,
    double? height,
    double? weight,
    int? age,
    String sex = '男',
    CharacterMode characterMode = CharacterMode.self,
    String? mirrorGender,
  }) async {
    final p = UserProfile(
      nickname: nickname,
      goal: goal,
      dailyCalorieTarget: dailyCalorieTarget ?? 2000,
      height: height,
      weight: weight,
      age: age,
      sex: sex,
      characterMode: characterMode,
      mirrorGender: mirrorGender,
    );
    await DatabaseService.saveProfile(p);
    _profile = p;
    _character = CharacterAppearance(gender: mirrorGender);
    await DatabaseService.saveCharacterAppearance(p.id, _character!);
    await _loadTodayData();
    _state = AppState.ready;
    notifyListeners();
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiKey, key);
    _apiKey = key;
    notifyListeners();
  }

  Future<void> saveOpenAIKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOpenAIKey, key);
    _openAIKey = key;
    notifyListeners();
  }

  // ── Character Name ────────────────────────────────────────────

  Future<void> saveCharacterName(String name) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(characterName: name.trim().isEmpty ? null : name.trim());
    await DatabaseService.saveProfile(updated);
    _profile = updated;
    notifyListeners();
  }

  // ── Sub-categories ────────────────────────────────────────────

  final Map<String, List<String>> _subCatCache = {};
  static const _kSubCatPrefix = 'subcats_';

  Future<List<String>> suggestGoalSubCategories(String category) async {
    if (_subCatCache.containsKey(category)) return _subCatCache[category]!;
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_kSubCatPrefix$category');
    if (cached != null) {
      try {
        final list = List<String>.from(jsonDecode(cached) as List);
        if (list.isNotEmpty) {
          _subCatCache[category] = list;
          return list;
        }
      } catch (_) {}
    }
    final result = await _gemini?.suggestGoalSubCategories(category) ?? [];
    if (result.isNotEmpty) {
      _subCatCache[category] = result;
      await prefs.setString('$_kSubCatPrefix$category', jsonEncode(result));
    }
    return result;
  }

  Future<Map<String, List<String>>?> generateGoalTargets(
      String category, String subCategory) async {
    final result = await _gemini?.generateGoalTargets(category, subCategory);
    if (result != null) return result;
    return _targetsFallback(subCategory);
  }

  Map<String, List<String>> _targetsFallback(String sub) {
    final patterns = <String, Map<String, List<String>>>{
      '跑步': {'mini': ['今天慢跑或步行15分鐘'], 'advanced': ['今天跑步30分鐘（約3-5公里）'], 'elite': ['今天跑步60分鐘（8公里以上）']},
      '重訓': {'mini': ['今天做15分鐘重訓或10組深蹲'], 'advanced': ['今天重訓45分鐘（3組×8動作）'], 'elite': ['今天完整重訓90分鐘（全身訓練）']},
      '游泳': {'mini': ['今天游泳300公尺或15分鐘'], 'advanced': ['今天游泳800公尺或30分鐘'], 'elite': ['今天游泳1500公尺以上或60分鐘']},
      '閱讀': {'mini': ['今天閱讀10頁或15分鐘'], 'advanced': ['今天閱讀30頁或30分鐘'], 'elite': ['今天閱讀60頁或60分鐘']},
      '冥想': {'mini': ['今天冥想或深呼吸5分鐘'], 'advanced': ['今天冥想20分鐘'], 'elite': ['今天冥想40分鐘（正念練習）']},
      '睡眠': {'mini': ['今天12點前入睡'], 'advanced': ['今天11點前入睡並記錄睡眠時間'], 'elite': ['今天10點半前入睡且不滑手機30分鐘']},
      '寫作': {'mini': ['今天寫作100字或10分鐘'], 'advanced': ['今天寫作500字或30分鐘'], 'elite': ['今天寫作1000字以上或60分鐘']},
      '語言': {'mini': ['今天練習外語15分鐘（app或單字）'], 'advanced': ['今天外語練習30分鐘（聽說讀寫）'], 'elite': ['今天外語練習60分鐘（含口說練習）']},
      '伸展': {'mini': ['今天伸展或瑜珈10分鐘'], 'advanced': ['今天伸展30分鐘（全身放鬆）'], 'elite': ['今天瑜珈60分鐘或完整流程']},
      '飲食': {'mini': ['今天喝2000ml水並記錄一餐'], 'advanced': ['今天均衡飲食三餐並記錄熱量'], 'elite': ['今天飲食完全按計畫並攝取足夠蔬果']},
    };
    for (final key in patterns.keys) {
      if (sub.contains(key)) return patterns[key]!;
    }
    return {
      'mini': ['今天做$sub 15分鐘'],
      'advanced': ['今天做$sub 30分鐘'],
      'elite': ['今天做$sub 60分鐘（全力投入）'],
    };
  }

  // ── Chat / Food Analysis ─────────────────────────────────────

  Future<String?> analyzeFood(String text) async {
    if (_gemini == null) return 'AI 分析暫時無法使用，請稍後再試。';
    _sendingMessage = true;
    notifyListeners();
    try {
      return await _gemini!.analyzeFood(text);
    } catch (e) {
      return GeminiService.isQuotaError(e)
          ? GeminiService.quotaErrorMessage()
          : '分析失敗，請確認網路後再試一次 🙏';
    } finally {
      _sendingMessage = false;
      notifyListeners();
    }
  }

  Future<String?> analyzeFoodImage(Uint8List bytes, String? note) async {
    if (_gemini == null) return 'AI 分析暫時無法使用，請稍後再試。';
    _sendingMessage = true;
    notifyListeners();
    try {
      return await _gemini!.analyzeFoodImage(bytes, note);
    } catch (e) {
      return GeminiService.isQuotaError(e)
          ? GeminiService.quotaErrorMessage()
          : '照片分析失敗，請確認網路後再試一次 🙏';
    } finally {
      _sendingMessage = false;
      notifyListeners();
    }
  }

  Future<void> saveMeal(Meal meal) async {
    await DatabaseService.insertMeal(meal);
    _todayMeals = await DatabaseService.getMealsForDay(
        _profile!.id, DateTime.now());
    notifyListeners();
  }

  Future<void> deleteMeal(String id) async {
    await DatabaseService.deleteMeal(id);
    _todayMeals = await DatabaseService.getMealsForDay(
        _profile!.id, DateTime.now());
    notifyListeners();
  }

  // ── Goals ────────────────────────────────────────────────────

  Future<void> addCategory(GoalCategory cat) async {
    await DatabaseService.saveCategory(_profile!.id, cat);
    _categories = await DatabaseService.getCategories(_profile!.id);
    notifyListeners();
  }

  Future<void> updateCategory(GoalCategory cat) async {
    await DatabaseService.saveCategory(_profile!.id, cat);
    final idx = _categories.indexWhere((c) => c.id == cat.id);
    if (idx >= 0) _categories[idx] = cat;
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await DatabaseService.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> logGoal(DailyGoalLog log) async {
    await DatabaseService.insertGoalLog(log);
    _todayLogs = await DatabaseService.getLogsForDay(_profile!.id, DateTime.now());
    await _addGrowthPoints(log.achieved.points * 10);
    // EXP for character relationship
    final expGain = log.achieved == GoalLevel.elite ? 20 : log.achieved == GoalLevel.advanced ? 10 : 5;
    await _addCharacterExp(expGain);
    // Random 5% bonus points
    if ((DateTime.now().millisecondsSinceEpoch % 20) == 0) {
      await _addGrowthPoints(50);
    }
    // Achievement checks
    await _checkGoalAchievements(log.achieved);
    notifyListeners();
  }

  Future<void> _checkGoalAchievements(GoalLevel level) async {
    if (_profile == null) return;
    // First elite
    if (level == GoalLevel.elite) {
      await _unlockIfNew('goal_elite');
    }
    // Count total goals
    final heatmap = await DatabaseService.getGoalHeatmapData(_profile!.id, 9999);
    final total = heatmap.values.fold(0, (s, v) => s + v);
    if (total >= 10) await _unlockIfNew('goal_10');
    if (total >= 50) await _unlockIfNew('goal_50');
    // First record ever
    if (total >= 1) await _unlockIfNew('first_record');
  }

  Future<void> removeGoalLog(String subItemId, GoalLevel level) async {
    await DatabaseService.deleteGoalLog(
        _profile!.id, subItemId, level, DateTime.now());
    _todayLogs = await DatabaseService.getLogsForDay(
        _profile!.id, DateTime.now());
    notifyListeners();
  }

  // ── Diary ────────────────────────────────────────────────────

  Future<void> saveDiary(DiaryEntry entry) async {
    await DatabaseService.saveDiary(entry);
    _todayDiary = entry;
    notifyListeners();
  }

  Future<String> completeDiary(String content) async {
    if (_gemini == null) throw Exception('AI 分析暫時無法使用，請稍後再試。');
    try {
      return await _gemini!
          .completeDiary(content, _profile!.nickname)
          .timeout(const Duration(seconds: 300));
    } catch (e) {
      if (GeminiService.isQuotaError(e)) throw Exception(GeminiService.quotaErrorMessage());
      rethrow;
    }
  }

  Future<List<String>> extractTodos(String content) async {
    if (_gemini == null) return [];
    return await _gemini!.extractTodos(content);
  }

  // ── Todos ────────────────────────────────────────────────────

  Future<void> addTodo(String content) async {
    if (_profile == null) return;
    final todo = TodoItem(profileId: _profile!.id, content: content);
    await DatabaseService.saveTodo(todo);
    _todos.insert(0, todo);
    notifyListeners();
  }

  Future<void> addTodos(List<String> contents) async {
    if (_profile == null) return;
    for (final c in contents) {
      final todo = TodoItem(profileId: _profile!.id, content: c);
      await DatabaseService.saveTodo(todo);
      _todos.insert(0, todo);
    }
    notifyListeners();
  }

  Future<void> removeTodo(String id) async {
    await DatabaseService.deleteTodo(id);
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> toggleTodo(String id) async {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final newDone = !_todos[idx].done;
    await DatabaseService.toggleTodo(id, newDone);
    _todos[idx].done = newDone;
    _todos[idx].doneAt = newDone ? DateTime.now() : null;
    if (newDone) await _addGrowthPoints(5);
    notifyListeners();
  }

  // ── Bonus Challenges ─────────────────────────────────────────

  Future<void> _ensureBonusChallengesForToday() async {
    if (_profile == null) return;
    final today = _dateKey(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kBonusChallengeDateKey);
    if (cached == today && _bonusChallenges.isNotEmpty) return;
    if (_bonusChallenges.isEmpty) {
      await generateBonusChallengesForToday();
    }
  }

  Future<void> generateBonusChallengesForToday() async {
    if (_profile == null || _gemini == null) return;
    final today = _dateKey(DateTime.now());
    final catNames = _categories.map((c) => c.title).toList();
    final challenges = await _gemini!.generateBonusChallenges(
      nickname: _profile!.nickname,
      goal: _profile!.goal.label,
      diaryContent: _todayDiary?.content,
      goalCategories: catNames,
      relationship: _relationship,
    );
    final prefs = await SharedPreferences.getInstance();
    for (final c in challenges) {
      final bc = BonusChallenge(
        profileId: _profile!.id,
        title: c['title'] ?? '完成挑戰',
        type: c['type'] ?? 'physical',
        date: today,
        points: 10,
      );
      await DatabaseService.saveBonusChallenge(bc);
    }
    await prefs.setString(_kBonusChallengeDateKey, today);
    _bonusChallenges = await DatabaseService.getBonusChallenges(_profile!.id, today);
    notifyListeners();
  }

  Future<void> completeBonusChallenge(String id) async {
    final idx = _bonusChallenges.indexWhere((c) => c.id == id);
    if (idx < 0 || _bonusChallenges[idx].done) return;
    await DatabaseService.completeBonusChallenge(id);
    _bonusChallenges[idx].done = true;
    _bonusChallenges[idx].doneAt = DateTime.now();
    await _addGrowthPoints(_bonusChallenges[idx].points);
    notifyListeners();
  }

  // ── Character Image (DALL-E 3 HD) ────────────────────────────

  Future<Uint8List?> generateCharacterImage() async {
    final profile = _profile;
    final character = _character;
    if (profile == null) return null;

    final isMirror = profile.characterMode == CharacterMode.mirror;
    final gender = isMirror ? (profile.mirrorGender ?? '她') : profile.sex;

    final aiService = openAI;
    if (aiService != null) {
      return aiService.generateCharacterImage(
        gender: gender,
        relationship: _relationship,
        isMirror: isMirror,
        appearance: character,
      );
    }
    // Fallback to Pollinations if OpenAI key unavailable
    return PollinationsService.generateCharacterImage(
      gender: gender,
      isMirror: isMirror,
      relationship: _relationship,
      skinTone: character?.skinTone?.name,
      hairStyle: character?.hairStyle?.name,
      hairColor: character?.hairColor?.name,
      muscleLevel: character?.muscleLevel ?? 0.0,
      fatLevel: character?.fatLevel ?? 0.3,
      outfitId: character?.outfitId,
      accessories: character?.accessories ?? [],
      tattoos: character?.tattoos ?? [],
    );
  }

  // Keep alias for backward compat with any remaining callers
  Future<Uint8List?> generateCharacterImagePollinations() => generateCharacterImage();

  // ── Vlog ─────────────────────────────────────────────────────

  Future<bool> generateTodayVlog({List<Uint8List> extraPhotos = const []}) async {
    if (_gemini == null) return false;
    final target = _profile!.calculatedCalorieTarget;
    final ratio = target > 0 ? todayCalories / target : 0.0;
    final level = ratio >= 0.8 && ratio <= 1.1
        ? '卓越'
        : ratio > 1.1
            ? '超標'
            : '低落';

    // Describe extra photos
    final photoDescriptions = <String>[];
    for (final photo in extraPhotos.take(3)) {
      final desc = await _gemini!.describeFoodPhoto(photo);
      if (desc.isNotEmpty) photoDescriptions.add(desc);
    }

    final narrative = await _gemini!.generateVlog(
      nickname: _profile!.nickname,
      calories: todayCalories,
      targetCalories: target,
      goalPoints: todayGoalPoints,
      diaryContent: _todayDiary?.content,
      characterMode: _profile!.characterMode.name,
      performanceLevel: level,
      foodPhotoDescriptions: photoDescriptions,
    );
    final vlog = VlogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      profileId: _profile!.id,
      narrative: narrative,
      style: level,
      performanceTag: level,
      stats: {
        'calories': todayCalories,
        'targetCalories': target,
        'goalPoints': todayGoalPoints,
      },
      date: DateTime.now(),
    );
    await DatabaseService.saveVlog(vlog);
    _todayVlog = vlog;
    // Update or insert in recent list
    final idx = _recentVlogs.indexWhere((v) => _isSameDay(v.date, vlog.date));
    if (idx >= 0) {
      _recentVlogs[idx] = vlog;
    } else {
      _recentVlogs.insert(0, vlog);
    }
    notifyListeners();
    return true;
  }

  Future<void> updateVlogEdit(VlogEntry vlog) async {
    await DatabaseService.updateVlog(vlog);
    final idx = _recentVlogs.indexWhere((v) => v.id == vlog.id);
    if (idx >= 0) _recentVlogs[idx] = vlog;
    if (_todayVlog?.id == vlog.id) _todayVlog = vlog;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getWeeklyStats() async {
    if (_profile == null) return {};
    final weeklyData = await DatabaseService.getWeeklyData(_profile!.id);
    final goalCompletion = await DatabaseService.getWeeklyGoalCompletion(_profile!.id);
    final recentDiaries = await DatabaseService.getRecentDiaries(_profile!.id, 7);
    final diaryContent = recentDiaries.isNotEmpty ? recentDiaries.first.content : null;
    final bonusDone = _bonusChallenges.where((c) => c.done).length;
    return {
      'weeklyData': weeklyData,
      'goalCompletion': goalCompletion,
      'bonusDone': bonusDone,
      'diaryContent': diaryContent,
    };
  }

  Future<String> generateWeeklyReport() async {
    if (_gemini == null || _profile == null) return '請設定 API Key';
    final stats = await getWeeklyStats();
    return _gemini!.generateWeeklyReport(
      nickname: _profile!.nickname,
      weeklyData: List<Map<String, dynamic>>.from(stats['weeklyData'] as List? ?? []),
      goalCompletions: (stats['goalCompletion'] as List?)?.fold<int>(0, (s, e) => s + (e['completions'] as int? ?? 0)) ?? 0,
      bonusDone: stats['bonusDone'] as int? ?? 0,
      diaryContent: stats['diaryContent'] as String?,
    );
  }

  Future<String> generateMonthlyReport() async {
    if (_gemini == null || _profile == null) return '請設定 API Key';
    final now = DateTime.now();
    final monthData = await DatabaseService.getMonthlyData(_profile!.id, now.year, now.month);
    final activeDays = monthData.where((d) => (d['calories'] as double) > 0).length;
    final avgCal = activeDays > 0 ? monthData.fold<double>(0, (s, d) => s + (d['calories'] as double)) / activeDays : 0.0;
    return _gemini!.generateMonthlyReport(
      nickname: _profile!.nickname,
      totalDays: monthData.length,
      activeDays: activeDays,
      avgCalories: avgCal,
      targetCalories: _profile!.calculatedCalorieTarget,
      totalGoalPoints: todayGoalPoints,
      growthPoints: _profile!.growthPoints,
    );
  }

  Future<List<Map<String, dynamic>>> generateGoalRebuildOptions(
      GoalCategory category, GoalSubItem item) async {
    if (_gemini == null) return [];
    final catTitle = category.title.replaceAll(RegExp(r'[^一-鿿㐀-䶿\w\s]'), '').trim();
    final heatmap = await DatabaseService.getGoalHeatmapData(_profile!.id, 30);
    final total = heatmap.values.fold(0, (s, v) => s + v);
    final possible = heatmap.length * 3;
    final rate = possible > 0 ? total / possible : 0.0;
    return _gemini!.generateGoalRebuildOptions(
      category: catTitle,
      subCategory: item.name,
      subItemName: item.name,
      subItemMini: item.miniTarget ?? '入門目標',
      subItemAdvanced: item.advancedTarget ?? '進階目標',
      subItemElite: item.eliteTarget ?? '精英目標',
      diaryContent: _todayDiary?.content,
      achievementRate: rate.clamp(0.0, 1.0),
    );
  }

  // ── Character & Shop ─────────────────────────────────────────

  Future<void> updateCharacterAppearance(CharacterAppearance a) async {
    await DatabaseService.saveCharacterAppearance(_profile!.id, a);
    _character = a;
    notifyListeners();
  }

  Future<bool> purchaseItem(String itemId, int price) async {
    if (_profile!.growthPoints < price) return false;
    await DatabaseService.purchaseItem(_profile!.id, itemId);
    _ownedItems.add(itemId);
    await _addGrowthPoints(-price);
    return true;
  }

  Future<void> equipItem(String itemId) async {
    if (_character == null || _profile == null) return;
    final cat = itemId.split('_').first;
    CharacterAppearance updated;
    switch (cat) {
      case 'outfit':
        updated = _character!.copyWith(outfitId: itemId);
      case 'hair':
        final parts = itemId.split('_');
        final style = parts.length > 1 ? parts[1] : null;
        final color = parts.length > 2 ? parts[2] : null;
        updated = _character!.copyWith(
          hairStyle: style != null ? HairStyle.values.firstWhere(
            (h) => h.name == style, orElse: () => _character!.hairStyle) : _character!.hairStyle,
          hairColor: color != null ? HairColor.values.firstWhere(
            (h) => h.name == color, orElse: () => _character!.hairColor) : _character!.hairColor,
        );
      case 'acc':
      case 'face':
      case 'furn':
      case 'special':
        final current = List<String>.from(_character!.accessories);
        if (!current.contains(itemId)) current.add(itemId);
        updated = _character!.copyWith(accessories: current);
      case 'bg':
        updated = _character!.copyWith(backgroundId: itemId);
      case 'tat':
        final current = List<String>.from(_character!.tattoos);
        if (!current.contains(itemId)) current.add(itemId);
        updated = _character!.copyWith(tattoos: current);
      default:
        updated = _character!;
    }
    await updateCharacterAppearance(updated);
  }

  Future<void> unequipItem(String itemId) async {
    if (_character == null || _profile == null) return;
    final cat = itemId.split('_').first;
    CharacterAppearance updated;
    switch (cat) {
      case 'outfit':
        updated = _character!.copyWith(outfitId: null);
      case 'acc':
      case 'face':
        final current = List<String>.from(_character!.accessories)
          ..remove(itemId);
        updated = _character!.copyWith(accessories: current);
      case 'bg':
        updated = _character!.copyWith(backgroundId: null);
      case 'tat':
        final current = List<String>.from(_character!.tattoos)
          ..remove(itemId);
        updated = _character!.copyWith(tattoos: current);
      default:
        return;
    }
    await updateCharacterAppearance(updated);
  }

  Future<void> _addGrowthPoints(int delta) async {
    final updated = _profile!.copyWith(
        growthPoints: (_profile!.growthPoints + delta).clamp(0, 999999));
    await DatabaseService.saveProfile(updated);
    _profile = updated;
    notifyListeners();
  }

  // ── Character Chat ────────────────────────────────────────────

  Future<String> sendCharacterMessage(String userText) async {
    if (_gemini == null || _profile == null) throw Exception('API Key 未設定');
    _chatting = true;
    notifyListeners();

    final userMsg = CharacterChatMessage(
      profileId: _profile!.id,
      role: 'user',
      content: userText,
    );
    _chatHistory.add(userMsg);
    await DatabaseService.saveChatMessage(userMsg);
    notifyListeners();

    try {
      final historyForAI = _chatHistory
          .where((m) => m.role == 'user' || m.role == 'character')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      // Compress if >50 messages
      String? memorySummary;
      if (historyForAI.length > 50) {
        memorySummary = await _getOrBuildMemorySummary(historyForAI);
      }

      final isMirror = _profile!.characterMode == CharacterMode.mirror;

      final styleHint = _buildStyleHint();
      final reply = await _gemini!.chatWithCharacter(
        characterName: characterName,
        relationship: _relationship,
        isMirror: isMirror,
        gender: _profile!.mirrorGender ?? _profile!.sex,
        history: historyForAI,
        userMessage: userText,
        todayData: {
          'calories': todayCalories,
          'targetCalories': _profile!.calculatedCalorieTarget,
          'goalPoints': todayGoalPoints,
          'diary': _todayDiary?.content ?? '',
        },
        memorySummary: memorySummary,
        styleHint: styleHint,
      );

      final charMsg = CharacterChatMessage(
        profileId: _profile!.id,
        role: 'character',
        content: reply,
      );
      _chatHistory.add(charMsg);
      await DatabaseService.saveChatMessage(charMsg);

      // EXP per chat message (diminishing: capped at 2 per day in spirit)
      await _addCharacterExp(3);
      // Achievement: chat 10 times
      final chatCount = await DatabaseService.getChatMessageCount(_profile!.id);
      if (chatCount >= 10) await _unlockIfNew('chat_10');

      await _updateRelationship();

      return reply;
    } finally {
      _chatting = false;
      notifyListeners();
    }
  }

  // ── Personal Advisor Chat ────────────────────────────────────

  Future<Map<String, dynamic>> _buildAdvisorContext() async {
    final id = _profile!.id;
    List<DiaryEntry> recentDiaries = const [];
    List<Map<String, dynamic>> weekly = const [];
    List<Map<String, dynamic>> goalComp = const [];
    try {
      recentDiaries = await DatabaseService.getRecentDiaries(id, 5);
    } catch (_) {}
    try {
      weekly = await DatabaseService.getWeeklyData(id);
    } catch (_) {}
    try {
      goalComp = await DatabaseService.getWeeklyGoalCompletion(id);
    } catch (_) {}

    return {
      'todayCalories': todayCalories,
      'targetCalories': _profile!.calculatedCalorieTarget,
      'todayGoalPoints': todayGoalPoints,
      'todayDiary': _todayDiary?.content ?? '',
      'weeklyCalories': weekly,
      'weeklyGoalCompletions': goalComp,
      'goals': _categories.map((c) => c.title).toList(),
      'loginStreak': _profile!.loginStreak,
      'recentDiaries': recentDiaries.map((d) => {
            'date': '${d.date.month}/${d.date.day}',
            'mood': d.mood,
            'snippet': d.content.length > 60
                ? '${d.content.substring(0, 60)}…'
                : d.content,
          }).toList(),
    };
  }

  /// Professional personal-advisor chat. Reuses the same chat history store
  /// as the (now-retired) character chat, but drives a consultant persona
  /// with rich diary / calorie / goal context.
  Future<String> sendAdvisorMessage(String userText) async {
    if (_gemini == null || _profile == null) throw Exception('API Key 未設定');
    _chatting = true;
    notifyListeners();

    final userMsg = CharacterChatMessage(
      profileId: _profile!.id,
      role: 'user',
      content: userText,
    );
    _chatHistory.add(userMsg);
    await DatabaseService.saveChatMessage(userMsg);
    notifyListeners();

    try {
      final historyForAI = _chatHistory
          .where((m) => m.role == 'user' || m.role == 'character')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      String? memorySummary;
      if (historyForAI.length > 50) {
        memorySummary = await _getOrBuildMemorySummary(historyForAI);
      }

      final ctx = await _buildAdvisorContext();
      final reply = await _gemini!.chatWithAdvisor(
        nickname: _profile!.nickname,
        history: historyForAI,
        userMessage: userText,
        context: ctx,
        memorySummary: memorySummary,
      );

      final aiMsg = CharacterChatMessage(
        profileId: _profile!.id,
        role: 'character',
        content: reply,
      );
      _chatHistory.add(aiMsg);
      await DatabaseService.saveChatMessage(aiMsg);
      return reply;
    } finally {
      _chatting = false;
      notifyListeners();
    }
  }

  /// On-demand: analyse the user's CURRENT app data and append a proactive
  /// advice message. Triggered by the "產生今日建議" button (no user bubble).
  Future<String> generateTodayAdvice() async {
    if (_gemini == null || _profile == null) throw Exception('API Key 未設定');
    _chatting = true;
    notifyListeners();
    try {
      final historyForAI = _chatHistory
          .where((m) => m.role == 'user' || m.role == 'character')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      final ctx = await _buildAdvisorContext();
      final reply = await _gemini!.chatWithAdvisor(
        nickname: _profile!.nickname,
        history: historyForAI,
        userMessage:
            '（系統請求）請根據我目前的 App 數據——飲食熱量、目標達成、日記——主動幫我做一次今日健康快檢，'
            '先用一句話總結今天狀態，再給我 2-3 個「今天就能執行」的具體建議，最後可用一個問題邀請我聊下去。',
        context: ctx,
        memorySummary: null,
      );
      final aiMsg = CharacterChatMessage(
        profileId: _profile!.id,
        role: 'character',
        content: reply,
      );
      _chatHistory.add(aiMsg);
      await DatabaseService.saveChatMessage(aiMsg);
      return reply;
    } finally {
      _chatting = false;
      notifyListeners();
    }
  }

  /// Clears the advisor/chat conversation without touching legacy
  /// character-relationship state.
  Future<void> clearChatHistory() async {
    if (_profile == null) return;
    await DatabaseService.clearChatHistory(_profile!.id);
    _chatHistory = [];
    notifyListeners();
  }

  Future<String?> _getOrBuildMemorySummary(List<Map<String, String>> allHistory) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kMemorySummaryPrefix${_profile!.id}';
    final existing = prefs.getString(key);

    final countKey = '${key}_count';
    final lastCount = prefs.getInt(countKey) ?? 0;
    if (existing != null && allHistory.length - lastCount < 20) {
      return existing;
    }

    // Build a lightweight summary from the older messages
    final older = allHistory.sublist(0, allHistory.length - 50);
    // Extract key content: last 5 user messages from the older set
    final keyMsgs = older
        .where((m) => m['role'] == 'user')
        .toList()
        .reversed
        .take(5)
        .toList()
        .reversed
        .toList();
    final summary = '過去${older.length}則對話摘要：'
        '${keyMsgs.map((m) => m['content'] ?? '').join('；')}';

    await prefs.setString(key, summary);
    await prefs.setInt(countKey, allHistory.length);
    return summary;
  }

  Future<void> _updateRelationship() async {
    if (_profile == null) return;
    final newRel = _profile!.relationshipLevel;
    if (newRel != _relationship) {
      final oldRel = _relationship;
      _relationship = newRel;
      // Achievement: first relationship level-up
      if (oldRel == '陌生人') await _unlockIfNew('relationship_up');
      if (newRel == '親密') await _unlockIfNew('relationship_intimate');
      notifyListeners();
    }
  }

  Future<void> resetCharacterRelationship() async {
    if (_profile == null) return;
    await DatabaseService.clearChatHistory(_profile!.id);
    _chatHistory = [];
    _relationship = '陌生人';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRelationshipKey, '陌生人');
    notifyListeners();
  }

  // ── Knowledge Pre-cache ───────────────────────────────────────

  Future<void> _preCacheKnowledgeIfNeeded(SharedPreferences prefs) async {
    final today = _dateKey(DateTime.now());
    final cached = prefs.getString(_kKnowledgeDateKey);
    if (cached == today) {
      _cachedKnowledge = await DatabaseService.getKnowledgeCache(today);
      notifyListeners();
      return;
    }

    final gemini = _gemini;
    if (gemini == null) return;

    final questions = <Map<String, dynamic>>[];
    final usedCategories = <String>{};
    final rng = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < 5 && i < _kKnowledgeCategories.length; i++) {
      final catIdx = (rng + i * 31) % _kKnowledgeCategories.length;
      var category = _kKnowledgeCategories[catIdx];
      var attempts = 0;
      while (usedCategories.contains(category) && attempts < 5) {
        category = _kKnowledgeCategories[(catIdx + attempts) % _kKnowledgeCategories.length];
        attempts++;
      }
      usedCategories.add(category);

      try {
        final q = await gemini.generateKnowledgeQuestionParsed(category);
        if (q != null) {
          q['idx'] = i;
          questions.add(q);
          await DatabaseService.saveKnowledgeCache(today, i, q);
        }
      } catch (_) {}
    }

    if (questions.isNotEmpty) {
      await prefs.setString(_kKnowledgeDateKey, today);
      _cachedKnowledge = questions;
      notifyListeners();
    }
  }

  Future<void> refreshKnowledgeCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKnowledgeDateKey);
    _cachedKnowledge = [];
    notifyListeners();
    await _preCacheKnowledgeIfNeeded(prefs);
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Knowledge Quiz ────────────────────────────────────────────

  Future<Map<String, String>?> generateKnowledgeQuestion(String category) async {
    return await _gemini?.generateKnowledgeQuestion(category);
  }

  Future<Map<String, dynamic>?> generateKnowledgeQuestionParsed(
      String category) async {
    return await _gemini?.generateKnowledgeQuestionParsed(category);
  }

  // ── Mirror Response ──────────────────────────────────────────

  Future<String> getMirrorResponse() async {
    if (_gemini == null || _profile == null) return 'AI 分析暫時無法使用，請稍後再試。';
    final target = _profile!.calculatedCalorieTarget;
    final ratio = target > 0 ? todayCalories / target : 0.0;
    return await _gemini!.getMirrorResponse(
      gender: _profile!.mirrorGender ?? '她',
      performanceRatio: ratio,
      diaryContent: _todayDiary?.content ?? '',
    );
  }

  // ── Profile Update ────────────────────────────────────────────

  Future<void> updateProfile(UserProfile updated) async {
    await DatabaseService.saveProfile(updated);
    _profile = updated;
    notifyListeners();
  }

  // ── CharacterExp & Achievements ───────────────────────────────

  Future<void> _addCharacterExp(int exp) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(characterExp: _profile!.characterExp + exp);
    await DatabaseService.saveProfile(updated);
    _profile = updated;
    _relationship = updated.relationshipLevel;
    notifyListeners();
  }

  Future<void> _unlockIfNew(String key) async {
    if (_profile == null) return;
    if (_achievements.any((a) => a.key == key)) return;
    final already = await DatabaseService.hasAchievement(_profile!.id, key);
    if (already) return;
    final a = Achievement(profileId: _profile!.id, key: key, unlockedAt: DateTime.now());
    await DatabaseService.unlockAchievement(a);
    _achievements.add(a);
  }

  // ── Equipment style hint ──────────────────────────────────────

  String? _buildStyleHint() {
    final acc = _character?.accessories ?? [];
    final parts = <String>[];
    if (acc.contains('round_glasses')) parts.add('說話帶點書卷氣，引用一些知識或名言很自然');
    if (acc.contains('sunglasses')) parts.add('說話酷酷的，不輕易表露情感，偶爾霸道');
    if (acc.contains('cap')) parts.add('說話隨性，喜歡用運動或戶外相關的比喻');
    if (acc.contains('scarf')) parts.add('說話溫柔細膩，帶點詩意，喜歡描述感受');
    return parts.isEmpty ? null : parts.join('；');
  }

  // ── Mood & Energy ─────────────────────────────────────────────

  Future<void> saveMoodEntry(MoodEntry entry) async {
    if (_profile == null) return;
    await DatabaseService.saveMood(entry);
    _todayMood = entry;
    // Achievement: 7-day mood streak
    final history = await DatabaseService.getMoodHistory(_profile!.id, 7);
    if (history.length >= 7) await _unlockIfNew('mood_check_7');
    notifyListeners();
  }

  Future<void> saveEnergyEntry(EnergyEntry entry) async {
    if (_profile == null) return;
    await DatabaseService.saveEnergy(entry);
    _todayEnergy = entry;
    if (entry.score >= 9) await _unlockIfNew('energy_high');
    notifyListeners();
  }

  // ── Water ─────────────────────────────────────────────────────

  Future<void> addWaterMl(int ml) async {
    if (_profile == null) return;
    final id = '${_profile!.id}_${DateTime.now().millisecondsSinceEpoch}';
    await DatabaseService.addWater(id, _profile!.id, DateTime.now(), ml);
    _waterMl += ml;
    notifyListeners();
  }

  Future<void> resetWater() async {
    if (_profile == null) return;
    await DatabaseService.resetWaterForDay(_profile!.id, DateTime.now());
    _waterMl = 0;
    notifyListeners();
  }

  // ── Morning Intent ────────────────────────────────────────────

  Future<void> saveMorningIntent(String intent) async {
    if (_profile == null) return;
    final today = DateTime.now();
    await DatabaseService.saveMorningIntent(_profile!.id, today, intent);
    final updated = _profile!.copyWith(
      morningIntent: intent,
      lastMorningIntentDate: _dateKey(today),
    );
    await DatabaseService.saveProfile(updated);
    _profile = updated;
    final streak = await DatabaseService.getMorningIntentStreak(_profile!.id);
    if (streak >= 7) await _unlockIfNew('morning_intent_7');
    notifyListeners();
  }

  void dismissLoginReward() {
    _loginRewardPending = false;
    notifyListeners();
  }

  void clearProactiveMessage() {
    _proactiveMessage = null;
    notifyListeners();
  }

  // ── Deep Analysis ─────────────────────────────────────────────

  Future<Map<String, String>> performDeepLifeAnalysis() async {
    if (_gemini == null || _profile == null) {
      return {'emotions': '請設定 API Key 後再試。', 'balance': '', 'advice': '', 'goalInsight': '', 'growth': ''};
    }
    await _unlockIfNew('explore_first');
    final catNames = _categories.map((c) => c.title).toList();
    final recentLogs = await DatabaseService.getLogsForDay(_profile!.id, DateTime.now());
    return _gemini!.performDeepLifeAnalysis(
      categories: catNames,
      recentLogs: recentLogs.map((l) => l.toMap()).toList(),
      diaryContent: _todayDiary?.content,
      moodScore: _todayMood?.score,
      energyScore: _todayEnergy?.score,
      nickname: _profile!.nickname,
    );
  }

  Future<String> generateMoodCorrelation() async {
    if (_gemini == null || _profile == null) return '持續記錄，AI 將發現你的規律。';
    final moods = await DatabaseService.getMoodHistory(_profile!.id, 7);
    final goalData = await DatabaseService.getWeeklyGoalCompletion(_profile!.id);
    return _gemini!.generateMoodCorrelation(
      weekMoods: moods.map((m) => {'date': _dateKey(m.date), 'score': m.score}).toList(),
      weekGoals: goalData,
    );
  }

  // ── Proactive Character Message ────────────────────────────────

  Future<void> _maybeGenerateProactiveMessage() async {
    if (_profile == null || _gemini == null) return;
    final today = DateTime.now();
    final last = _profile!.lastProactiveDate;
    if (last != null && _isSameDay(last, today)) return;
    if (today.hour < 9 || today.hour > 22) return;

    final target = _profile!.calculatedCalorieTarget;
    final ratio = target > 0 ? todayCalories / target : 0.0;
    final styleHint = _buildStyleHint();

    try {
      final msg = await _gemini!.generateCharacterProactiveMessage(
        characterName: characterName,
        relationship: _relationship,
        nickname: _profile!.nickname,
        caloriesRatio: ratio,
        goalPoints: todayGoalPoints,
        loginStreak: _profile!.loginStreak,
        diaryContent: _todayDiary?.content,
        gender: _profile!.mirrorGender ?? _profile!.sex,
        styleHint: styleHint,
      );
      _proactiveMessage = msg;
      final updated = _profile!.copyWith(lastProactiveDate: today);
      await DatabaseService.saveProfile(updated);
      _profile = updated;
      notifyListeners();
    } catch (_) {}
  }

  // ── Diary Title ───────────────────────────────────────────────

  Future<String> generateDiaryTitle(String content) async {
    if (_gemini == null) return '今日記錄';
    return _gemini!.generateDiaryTitle(content);
  }

  // ── Heatmap (3-month) ─────────────────────────────────────────

  Future<Map<String, int>> getHeatmap3Months() async {
    if (_profile == null) return {};
    return DatabaseService.getGoalHeatmapData(_profile!.id, 91);
  }

  // ── Year Ago ──────────────────────────────────────────────────

  Future<VlogEntry?> getVlogOneYearAgo() async {
    if (_profile == null) return null;
    final yearAgo = DateTime.now().subtract(const Duration(days: 365));
    final entry = await DatabaseService.getVlogForDay(_profile!.id, yearAgo);
    if (entry != null) await _unlockIfNew('year_memory');
    return entry;
  }

  // ── Journal Analysis ──────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeJournal(String content) async {
    if (_gemini == null) return {'events': [], 'todos': []};
    return _gemini!.analyzeJournal(content);
  }

  // ── Mind Map ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> generateMindMap() async {
    if (_gemini == null || _profile == null) {
      return {'center': '今日記錄', 'branches': []};
    }
    final categories = _categories.map((c) => c.title).toList();
    return _gemini!.generateMindMap(
      diaryContent: _todayDiary?.content ?? '',
      nickname: _profile!.nickname,
      goalCategories: categories,
      goalPoints: todayGoalPoints,
    );
  }

  // ── Todo Prioritization ───────────────────────────────────────

  Future<void> prioritizeTodos() async {
    if (_gemini == null || _todos.isEmpty) return;
    final pending = _todos.where((t) => !t.done).toList();
    if (pending.isEmpty) return;
    final input = pending.map((t) => {'id': t.id, 'content': t.content}).toList();
    final ordered = await _gemini!.prioritizeTodos(input);
    if (ordered.isEmpty) return;
    final idxMap = {for (var i = 0; i < ordered.length; i++) ordered[i]: i};
    _todos.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      final ai = idxMap[a.id] ?? 999;
      final bi = idxMap[b.id] ?? 999;
      return ai.compareTo(bi);
    });
    notifyListeners();
  }

  // ── Goal Review ───────────────────────────────────────────────

  Future<String> reviewGoals() async {
    if (_gemini == null || _profile == null) return '目前尚無足夠資料，繼續記錄後 AI 將為你分析。';
    final catData = _categories.map((c) => {'title': c.title}).toList();
    final recentLogs = _todayLogs.map((l) => {'subItemId': l.subItemId, 'level': l.achieved.name}).toList();
    return _gemini!.reviewGoals(
      nickname: _profile!.nickname,
      categories: catData,
      recentLogs: recentLogs,
    );
  }

  // ── Daily Knowledge Challenge ─────────────────────────────────

  List<Map<String, dynamic>> _dailyKnowledge = [];
  Map<String, bool> _knowledgeAnswers = {};
  int _knowledgeStreak = 0;
  bool _loadingKnowledge = false;

  List<Map<String, dynamic>> get dailyKnowledge => _dailyKnowledge;
  Map<String, bool> get knowledgeAnswers => _knowledgeAnswers;
  int get knowledgeStreak => _knowledgeStreak;
  bool get loadingKnowledge => _loadingKnowledge;

  String get _todayDateStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  Future<void> loadDailyKnowledge() async {
    if (_loadingKnowledge) return;
    final dateStr = _todayDateStr;

    final cached = await DatabaseService.getDailyKnowledge(dateStr);
    if (cached.length == 5) {
      final answers = await DatabaseService.getAnswersForDate(_profile?.id ?? '', dateStr);
      final streak = await DatabaseService.getKnowledgeStreak(_profile?.id ?? '');
      _dailyKnowledge = cached;
      _knowledgeAnswers = answers;
      _knowledgeStreak = streak;
      notifyListeners();
      return;
    }

    _loadingKnowledge = true;
    notifyListeners();

    try {
      final avoidTopics = await DatabaseService.getRecentKnowledgeTopics(30);
      final categories = GeminiService.getDailyCategories(dateStr);
      final questions = await _gemini!.generateDailyKnowledge(
        dateStr: dateStr,
        categories: categories,
        avoidTopics: avoidTopics,
      );
      for (var i = 0; i < questions.length; i++) {
        await DatabaseService.saveDailyKnowledge(dateStr, i, questions[i]);
      }
      // Purge questions older than 31 days
      final cutoff = DateTime.now().subtract(const Duration(days: 31));
      final cutoffStr = '${cutoff.year}-${cutoff.month.toString().padLeft(2,'0')}-${cutoff.day.toString().padLeft(2,'0')}';
      await DatabaseService.purgeDailyKnowledgeBefore(cutoffStr);

      final answers = await DatabaseService.getAnswersForDate(_profile?.id ?? '', dateStr);
      final streak = await DatabaseService.getKnowledgeStreak(_profile?.id ?? '');
      _dailyKnowledge = questions;
      _knowledgeAnswers = answers;
      _knowledgeStreak = streak;
    } catch (_) {
      _dailyKnowledge = [];
    } finally {
      _loadingKnowledge = false;
      notifyListeners();
    }
  }

  Future<void> answerKnowledge(String questionId, bool correct) async {
    if (_profile == null) return;
    await DatabaseService.saveKnowledgeAnswer(_profile!.id, questionId, correct);
    _knowledgeAnswers[questionId] = correct;

    // Update streak if all 5 answered correctly today
    final dateStr = _todayDateStr;
    final allAnswered = _dailyKnowledge.every((q) => _knowledgeAnswers.containsKey(q['id'] as String));
    if (allAnswered) {
      await DatabaseService.updateKnowledgeStreak(_profile!.id, dateStr);
      _knowledgeStreak = await DatabaseService.getKnowledgeStreak(_profile!.id);
      if (correct) await _addGrowthPoints(5);
    } else if (correct) {
      await _addGrowthPoints(5);
    }
    notifyListeners();
  }

  // ── Streak ────────────────────────────────────────────────────

  Future<void> checkAndUpdateStreak() async {
    if (_profile == null) return;
    final today = DateTime.now();
    final last = _profile!.lastLogDate;
    int newStreak = _profile!.streak;

    if (last == null) {
      newStreak = 1;
    } else if (_isSameDay(last, today)) {
      return;
    } else {
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        newStreak = newStreak + 1;
      } else if (diff > 1) {
        newStreak = 1;
      }
    }

    final updated = _profile!.copyWith(
        streak: newStreak, lastLogDate: today);
    await DatabaseService.saveProfile(updated);
    _profile = updated;
    notifyListeners();
  }
}
