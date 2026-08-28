import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';
import '../models/meal.dart';
import '../models/goal.dart';
import '../models/diary_entry.dart';
import '../models/character.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'time_machine.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE goal_categories (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE goal_logs (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        date TEXT NOT NULL,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE diary_entries (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        date TEXT NOT NULL,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE vlog_entries (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        date TEXT NOT NULL,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE character_appearance (
        profileId TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE owned_items (
        profileId TEXT NOT NULL,
        itemId TEXT NOT NULL,
        PRIMARY KEY (profileId, itemId)
      )
    ''');
    await db.execute('''
      CREATE TABLE knowledge_answers (
        profileId TEXT NOT NULL,
        questionId TEXT NOT NULL,
        correct INTEGER NOT NULL,
        answeredAt TEXT NOT NULL,
        PRIMARY KEY (profileId, questionId)
      )
    ''');
  }

  // ── Profile ─────────────────────────────────────────────────

  static Future<UserProfile?> getProfile(String id) async {
    final d = await db;
    final rows = await d.query('profiles', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(jsonDecode(rows.first['data'] as String));
  }

  static Future<UserProfile?> getFirstProfile() async {
    final d = await db;
    final rows = await d.query('profiles', limit: 1);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(jsonDecode(rows.first['data'] as String));
  }

  static Future<void> saveProfile(UserProfile p) async {
    final d = await db;
    await d.insert('profiles', {'id': p.id, 'data': jsonEncode(p.toMap())},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Meals ────────────────────────────────────────────────────

  static Future<void> insertMeal(Meal meal) async {
    final d = await db;
    await d.insert('meals', {
      'id': meal.id,
      'profileId': meal.profileId,
      'timestamp': meal.timestamp.toIso8601String(),
      'data': jsonEncode(meal.toMap()),
    });
  }

  static Future<void> deleteMeal(String id) async {
    final d = await db;
    await d.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Meal>> getMealsForDay(String profileId, DateTime day) async {
    final d = await db;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await d.query('meals',
        where: 'profileId = ? AND timestamp >= ? AND timestamp < ?',
        whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
        orderBy: 'timestamp ASC');
    return rows.map((r) => Meal.fromMap(jsonDecode(r['data'] as String))).toList();
  }

  static Future<List<Map<String, dynamic>>> getWeeklyData(String profileId) async {
    final d = await db;
    final start = DateTime.now().subtract(const Duration(days: 6));
    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final rows = await d.query('meals',
        where: 'profileId = ? AND timestamp >= ?',
        whereArgs: [profileId, startStr],
        orderBy: 'timestamp ASC');
    final meals = rows.map((r) => Meal.fromMap(jsonDecode(r['data'] as String))).toList();

    final Map<String, Map<String, dynamic>> byDay = {};
    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      byDay[key] = {'date': DateTime(day.year, day.month, day.day),
          'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
    }
    for (final m in meals) {
      final key = '${m.timestamp.year}-${m.timestamp.month}-${m.timestamp.day}';
      if (byDay.containsKey(key)) {
        byDay[key]!['calories'] = (byDay[key]!['calories'] as double) + m.totalCalories;
        byDay[key]!['protein'] = (byDay[key]!['protein'] as double) + m.protein;
        byDay[key]!['carbs'] = (byDay[key]!['carbs'] as double) + m.carbs;
        byDay[key]!['fat'] = (byDay[key]!['fat'] as double) + m.fat;
      }
    }
    return byDay.values.toList();
  }

  // ── Goals ────────────────────────────────────────────────────

  static Future<List<GoalCategory>> getCategories(String profileId) async {
    final d = await db;
    final rows = await d.query('goal_categories',
        where: 'profileId = ?', whereArgs: [profileId]);
    return rows.map((r) => GoalCategory.fromMap(jsonDecode(r['data'] as String))).toList();
  }

  static Future<void> saveCategory(String profileId, GoalCategory cat) async {
    final d = await db;
    await d.insert('goal_categories',
        {'id': cat.id, 'profileId': profileId, 'data': jsonEncode(cat.toMap())},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteCategory(String id) async {
    final d = await db;
    await d.delete('goal_categories', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> insertGoalLog(DailyGoalLog log) async {
    final d = await db;
    await d.insert('goal_logs', {
      'id': log.id,
      'profileId': log.profileId,
      'date': log.date.toIso8601String(),
      'data': jsonEncode(log.toMap()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<DailyGoalLog>> getLogsForDay(String profileId, DateTime day) async {
    final d = await db;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await d.query('goal_logs',
        where: 'profileId = ? AND date >= ? AND date < ?',
        whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()]);
    return rows.map((r) => DailyGoalLog.fromMap(jsonDecode(r['data'] as String))).toList();
  }

  static Future<Map<String, int>> getGoalHeatmapData(String profileId, int days) async {
    final d = await db;
    final start = DateTime.now().subtract(Duration(days: days));
    final rows = await d.query('goal_logs',
        where: 'profileId = ? AND date >= ?',
        whereArgs: [profileId, start.toIso8601String()]);
    final Map<String, int> result = {};
    for (final r in rows) {
      final log = DailyGoalLog.fromMap(jsonDecode(r['data'] as String));
      final key = '${log.date.year}-${log.date.month}-${log.date.day}';
      result[key] = (result[key] ?? 0) + log.achieved.points;
    }
    return result;
  }

  // ── Diary ────────────────────────────────────────────────────

  static Future<DiaryEntry?> getDiaryForDay(String profileId, DateTime day) async {
    final d = await db;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await d.query('diary_entries',
        where: 'profileId = ? AND date >= ? AND date < ?',
        whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
        limit: 1);
    if (rows.isEmpty) return null;
    return DiaryEntry.fromMap(jsonDecode(rows.first['data'] as String));
  }

  static Future<void> saveDiary(DiaryEntry entry) async {
    final d = await db;
    await d.insert('diary_entries', {
      'id': entry.id,
      'profileId': entry.profileId,
      'date': entry.date.toIso8601String(),
      'data': jsonEncode(entry.toMap()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<DiaryEntry>> getRecentDiaries(String profileId, int limit) async {
    final d = await db;
    final rows = await d.query('diary_entries',
        where: 'profileId = ?', whereArgs: [profileId],
        orderBy: 'date DESC', limit: limit);
    return rows.map((r) => DiaryEntry.fromMap(jsonDecode(r['data'] as String))).toList();
  }

  // ── Vlog ─────────────────────────────────────────────────────

  static Future<void> saveVlog(VlogEntry vlog) async {
    final d = await db;
    await d.insert('vlog_entries', {
      'id': vlog.id,
      'profileId': vlog.profileId,
      'date': vlog.date.toIso8601String(),
      'data': jsonEncode(vlog.toMap()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<VlogEntry>> getRecentVlogs(String profileId, int limit) async {
    final d = await db;
    final rows = await d.query('vlog_entries',
        where: 'profileId = ?', whereArgs: [profileId],
        orderBy: 'date DESC', limit: limit);
    return rows.map((r) => VlogEntry.fromMap(jsonDecode(r['data'] as String))).toList();
  }

  static Future<VlogEntry?> getVlogForDay(String profileId, DateTime day) async {
    final d = await db;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await d.query('vlog_entries',
        where: 'profileId = ? AND date >= ? AND date < ?',
        whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
        limit: 1);
    if (rows.isEmpty) return null;
    return VlogEntry.fromMap(jsonDecode(rows.first['data'] as String));
  }

  // ── Character ─────────────────────────────────────────────────

  static Future<CharacterAppearance?> getCharacterAppearance(String profileId) async {
    final d = await db;
    final rows = await d.query('character_appearance',
        where: 'profileId = ?', whereArgs: [profileId]);
    if (rows.isEmpty) return null;
    return CharacterAppearance.fromMap(jsonDecode(rows.first['data'] as String));
  }

  static Future<void> saveCharacterAppearance(String profileId, CharacterAppearance a) async {
    final d = await db;
    await d.insert('character_appearance',
        {'profileId': profileId, 'data': jsonEncode(a.toMap())},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Shop / Inventory ──────────────────────────────────────────

  static Future<Set<String>> getOwnedItems(String profileId) async {
    final d = await db;
    final rows = await d.query('owned_items',
        where: 'profileId = ?', whereArgs: [profileId]);
    return rows.map((r) => r['itemId'] as String).toSet();
  }

  static Future<void> purchaseItem(String profileId, String itemId) async {
    final d = await db;
    await d.insert('owned_items', {'profileId': profileId, 'itemId': itemId},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
