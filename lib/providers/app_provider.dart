import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/meal.dart';
import '../models/goal.dart';
import '../models/diary_entry.dart';
import '../models/character.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/openai_service.dart';

const _kApiKey = 'gemini_api_key';
const _kOpenAIKey = 'openai_api_key';
const _kDefaultApiKey = '';

enum AppState { loading, onboarding, ready }

class AppProvider extends ChangeNotifier {
  AppState _state = AppState.loading;
  UserProfile? _profile;
  CharacterAppearance? _character;
  String? _apiKey;
  String? _openAIKey;

  List<Meal> _todayMeals = [];
  List<GoalCategory> _categories = [];
  List<DailyGoalLog> _todayLogs = [];
  DiaryEntry? _todayDiary;
  VlogEntry? _todayVlog;
  List<VlogEntry> _recentVlogs = [];

  bool _sendingMessage = false;
  String? _lastChatResponse;

  AppState get state => _state;
  UserProfile? get profile => _profile;
  CharacterAppearance? get character => _character;
  String? get apiKey => _apiKey;
  String? get openAIKey => _openAIKey;

  OpenAIService? get openAI {
    final key = _openAIKey ?? '';
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
  String? get lastChatResponse => _lastChatResponse;

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
    final key = _apiKey ?? _kDefaultApiKey;
    if (key.isEmpty) return null;
    return GeminiService(key);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_kApiKey);
    _openAIKey = prefs.getString(_kOpenAIKey);
    _profile = await DatabaseService.getFirstProfile();
    if (_profile == null) {
      _state = AppState.onboarding;
    } else {
      await _loadTodayData();
      _state = AppState.ready;
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
    _recentVlogs = await DatabaseService.getRecentVlogs(_profile!.id, 30);
    _todayVlog = _recentVlogs.isNotEmpty &&
            _isSameDay(_recentVlogs.first.date, today)
        ? _recentVlogs.first
        : null;
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

  Future<List<String>> suggestGoalSubCategories(String category) async {
    return await _gemini?.suggestGoalSubCategories(category) ?? [];
  }

  Future<Map<String, List<String>>?> generateGoalTargets(
      String category, String subCategory) async {
    return await _gemini?.generateGoalTargets(category, subCategory);
  }

  // ── Chat / Food Analysis ─────────────────────────────────────

  Future<String?> analyzeFood(String text) async {
    _sendingMessage = true;
    notifyListeners();
    try {
      final response = await _gemini!.analyzeFood(text);
      _lastChatResponse = response;
      return response;
    } finally {
      _sendingMessage = false;
      notifyListeners();
    }
  }

  Future<String?> analyzeFoodImage(Uint8List bytes, String? note) async {
    _sendingMessage = true;
    notifyListeners();
    try {
      final response = await _gemini!.analyzeFoodImage(bytes, note);
      _lastChatResponse = response;
      return response;
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
    // Award growth points
    await _addGrowthPoints(log.achieved.points * 10);
    notifyListeners();
  }

  // ── Diary ────────────────────────────────────────────────────

  Future<void> saveDiary(DiaryEntry entry) async {
    await DatabaseService.saveDiary(entry);
    _todayDiary = entry;
    notifyListeners();
  }

  Future<String> completeDiary(String content) async {
    return await _gemini!.completeDiary(content, _profile!.nickname);
  }

  Future<List<String>> extractTodos(String content) async {
    return await _gemini!.extractTodos(content);
  }

  // ── Vlog ─────────────────────────────────────────────────────

  Future<void> generateTodayVlog() async {
    final target = _profile!.calculatedCalorieTarget;
    final ratio = target > 0 ? todayCalories / target : 0.0;
    final level = ratio >= 0.8 && ratio <= 1.1
        ? '卓越'
        : ratio > 1.1
            ? '超標'
            : '低落';
    final narrative = await _gemini!.generateVlog(
      nickname: _profile!.nickname,
      calories: todayCalories,
      targetCalories: target,
      goalPoints: todayGoalPoints,
      diaryContent: _todayDiary?.content,
      characterMode: _profile!.characterMode.name,
      performanceLevel: level,
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
    await _addGrowthPoints(-price);
    return true;
  }

  Future<void> _addGrowthPoints(int delta) async {
    final updated = _profile!.copyWith(
        growthPoints: (_profile!.growthPoints + delta).clamp(0, 999999));
    await DatabaseService.saveProfile(updated);
    _profile = updated;
  }

  // ── Knowledge Quiz ────────────────────────────────────────────

  Future<Map<String, String>?> generateKnowledgeQuestion(String category) async {
    return await _gemini?.generateKnowledgeQuestion(category);
  }

  // ── Mirror Response ──────────────────────────────────────────

  Future<String> getMirrorResponse() async {
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
      newStreak = diff <= 2 ? newStreak + 1 : 1;
    }

    final updated = _profile!.copyWith(
        streak: newStreak, lastLogDate: today);
    await DatabaseService.saveProfile(updated);
    _profile = updated;
    notifyListeners();
  }
}
