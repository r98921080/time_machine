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

const _kDefaultGeminiKey =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
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
    return GeminiService(key);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_kApiKey);
    _openAIKey = prefs.getString(_kOpenAIKey);
    _relationship = prefs.getString(_kRelationshipKey) ?? '陌生人';
    _profile = await DatabaseService.getFirstProfile();
    if (_profile == null) {
      _state = AppState.onboarding;
    } else {
      await _loadTodayData();
      _state = AppState.ready;
      _preCacheKnowledgeIfNeeded(prefs);
      _ensureBonusChallengesForToday();
    }
    notifyListeners();
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
      '跑步': {'mini': ['每天慢跑15分鐘'], 'advanced': ['每天跑步30分鐘，達5km'], 'elite': ['每週跑步5天，每次8km以上']},
      '重訓': {'mini': ['每週重訓2次，每次30分鐘'], 'advanced': ['每週重訓4次，每次45分鐘'], 'elite': ['每天重訓，週期計畫且持續12週']},
      '游泳': {'mini': ['每週游泳1次，500m'], 'advanced': ['每週游泳3次，每次1km'], 'elite': ['每週游泳5次，每次2km以上']},
      '閱讀': {'mini': ['每天閱讀10分鐘'], 'advanced': ['每天閱讀30分鐘，每月完成1本書'], 'elite': ['每天閱讀1小時，每月讀2本以上']},
      '冥想': {'mini': ['每天冥想5分鐘'], 'advanced': ['每天冥想20分鐘'], 'elite': ['每天冥想40分鐘，連續90天不中斷']},
      '睡眠': {'mini': ['每天11點前入睡'], 'advanced': ['每天睡滿7小時，固定作息'], 'elite': ['每天睡滿8小時，睡眠品質分數達90分']},
    };
    for (final key in patterns.keys) {
      if (sub.contains(key)) return patterns[key]!;
    }
    return {
      'mini': ['每天做$sub 15分鐘'],
      'advanced': ['每天做$sub 30分鐘，堅持4週'],
      'elite': ['每天做$sub 60分鐘，連續90天達標'],
    };
  }

  // ── Chat / Food Analysis ─────────────────────────────────────

  Future<String?> analyzeFood(String text) async {
    if (_gemini == null) return '請先在設定中輸入 Gemini API Key。';
    _sendingMessage = true;
    notifyListeners();
    try {
      return await _gemini!.analyzeFood(text);
    } finally {
      _sendingMessage = false;
      notifyListeners();
    }
  }

  Future<String?> analyzeFoodImage(Uint8List bytes, String? note) async {
    if (_gemini == null) return '請先在設定中輸入 Gemini API Key。';
    _sendingMessage = true;
    notifyListeners();
    try {
      return await _gemini!.analyzeFoodImage(bytes, note);
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
    _todayLogs = await DatabaseService.getLogsForDay(
        _profile!.id, DateTime.now());
    await _addGrowthPoints(log.achieved.points * 10);
    notifyListeners();
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
    if (_gemini == null) throw Exception('請設定 API Key');
    return await _gemini!
        .completeDiary(content, _profile!.nickname)
        .timeout(const Duration(seconds: 300));
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

  // ── Character Image (Pollinations.ai) ────────────────────────

  Future<Uint8List?> generateCharacterImagePollinations() async {
    final profile = _profile;
    final character = _character;
    if (profile == null || character == null) return null;

    final isMirror = profile.characterMode == CharacterMode.mirror;
    final gender = isMirror ? (profile.mirrorGender ?? '她') : profile.sex;

    return PollinationsService.generateCharacterImage(
      gender: gender,
      isMirror: isMirror,
      relationship: _relationship,
      skinTone: character.skinTone?.name,
      hairStyle: character.hairStyle?.name,
      hairColor: character.hairColor?.name,
      muscleLevel: character.muscleLevel,
      fatLevel: character.fatLevel,
      outfitId: character.outfitId,
    );
  }

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
    _recentVlogs.insert(0, vlog);
    notifyListeners();
    return true;
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
      );

      final charMsg = CharacterChatMessage(
        profileId: _profile!.id,
        role: 'character',
        content: reply,
      );
      _chatHistory.add(charMsg);
      await DatabaseService.saveChatMessage(charMsg);

      await _updateRelationship();

      return reply;
    } finally {
      _chatting = false;
      notifyListeners();
    }
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
    final count = await DatabaseService.getChatMessageCount(_profile!.id);
    String newRel;
    if (count < 20) {
      newRel = '陌生人';
    } else if (count < 60) {
      newRel = '朋友';
    } else if (count < 150) {
      newRel = '曖昧';
    } else {
      newRel = '親密';
    }
    if (newRel != _relationship) {
      _relationship = newRel;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRelationshipKey, _relationship);
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
    if (_gemini == null) return '請先設定 Gemini API Key。';
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
