import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';
import '../models/meal.dart';
import '../models/goal.dart';
import '../models/diary_entry.dart';
import '../models/character.dart';
import '../models/chat_message.dart';
import '../models/todo_item.dart';
import '../models/bonus_challenge.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'time_machine.db');
    return openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS character_chats (
          id TEXT PRIMARY KEY,
          profileId TEXT NOT NULL,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS knowledge_cache (
          date TEXT NOT NULL,
          idx INTEGER NOT NULL,
          data TEXT NOT NULL,
          PRIMARY KEY (date, idx)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS todos (
          id TEXT PRIMARY KEY,
          profileId TEXT NOT NULL,
          content TEXT NOT NULL,
          done INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          doneAt TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bonus_challenges (
          id TEXT PRIMARY KEY,
          profileId TEXT NOT NULL,
          title TEXT NOT NULL,
          type TEXT NOT NULL,
          date TEXT NOT NULL,
          done INTEGER NOT NULL DEFAULT 0,
          points INTEGER NOT NULL DEFAULT 10,
          doneAt TEXT
        )
      ''');
    }
  }

  static Future<void> _createAllTables(Database db) async {
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
        subItemId TEXT NOT NULL,
        level TEXT NOT NULL,
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
    await db.execute('''
      CREATE TABLE character_chats (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE knowledge_cache (
        date TEXT NOT NULL,
        idx INTEGER NOT NULL,
        data TEXT NOT NULL,
        PRIMARY KEY (date, idx)
      )
    ''');
    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        content TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        doneAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE bonus_challenges (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        points INTEGER NOT NULL DEFAULT 10,
        doneAt TEXT
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
    final start = DateTime(log.date.year, log.date.month, log.date.day);
    final end = start.add(const Duration(days: 1));
    await d.delete('goal_logs',
        where: 'profileId = ? AND subItemId = ? AND level = ? AND date >= ? AND date < ?',
        whereArgs: [log.profileId, log.subItemId, log.achieved.name,
            start.toIso8601String(), end.toIso8601String()]);
    await d.insert('goal_logs', {
      'id': log.id,
      'profileId': log.profileId,
      'subItemId': log.subItemId,
      'level': log.achieved.name,
      'date': log.date.toIso8601String(),
      'data': jsonEncode(log.toMap()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteGoalLog(String profileId, String subItemId,
      GoalLevel level, DateTime day) async {
    final d = await db;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    await d.delete('goal_logs',
        where: 'profileId = ? AND subItemId = ? AND level = ? AND date >= ? AND date < ?',
        whereArgs: [profileId, subItemId, level.name,
            start.toIso8601String(), end.toIso8601String()]);
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
    // Upsert by (profileId, date-prefix) so same-day re-generate overwrites
    final dateKey = vlog.date.toIso8601String().substring(0, 10);
    final existing = await d.query('vlog_entries',
        where: "profileId = ? AND date LIKE ?",
        whereArgs: [vlog.profileId, '$dateKey%'], limit: 1);
    if (existing.isNotEmpty) {
      // Overwrite with same row id
      final existingId = existing.first['id'] as String;
      final updatedMap = vlog.toMap()..['id'] = existingId;
      await d.update('vlog_entries',
          {'id': existingId, 'profileId': vlog.profileId,
           'date': vlog.date.toIso8601String(), 'data': jsonEncode(updatedMap)},
          where: 'id = ?', whereArgs: [existingId]);
    } else {
      await d.insert('vlog_entries', {
        'id': vlog.id,
        'profileId': vlog.profileId,
        'date': vlog.date.toIso8601String(),
        'data': jsonEncode(vlog.toMap()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<void> updateVlog(VlogEntry vlog) async {
    final d = await db;
    await d.update('vlog_entries',
        {'date': vlog.date.toIso8601String(), 'data': jsonEncode(vlog.toMap())},
        where: 'id = ?', whereArgs: [vlog.id]);
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

  static Future<List<Map<String, dynamic>>> getMonthlyData(String profileId, int year, int month) async {
    final d = await db;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final rows = await d.query('meals',
        where: 'profileId = ? AND timestamp >= ? AND timestamp < ?',
        whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
        orderBy: 'timestamp ASC');
    final meals = rows.map((r) => Meal.fromMap(jsonDecode(r['data'] as String))).toList();
    final Map<int, Map<String, dynamic>> byDay = {};
    for (var day = 1; day <= DateTime(year, month + 1, 0).day; day++) {
      byDay[day] = {'day': day, 'calories': 0.0, 'protein': 0.0};
    }
    for (final m in meals) {
      final day = m.timestamp.day;
      if (byDay.containsKey(day)) {
        byDay[day]!['calories'] = (byDay[day]!['calories'] as double) + m.totalCalories;
        byDay[day]!['protein'] = (byDay[day]!['protein'] as double) + m.protein;
      }
    }
    return byDay.values.toList();
  }

  static Future<List<Map<String, dynamic>>> getWeeklyGoalCompletion(String profileId) async {
    final d = await db;
    final start = DateTime.now().subtract(const Duration(days: 6));
    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final rows = await d.rawQuery(
      "SELECT date, data FROM goal_logs WHERE profileId = ? AND date >= ? ORDER BY date ASC",
      [profileId, startStr]);
    final Map<String, int> byDay = {};
    for (final r in rows) {
      final dateKey = (r['date'] as String).substring(0, 10);
      byDay[dateKey] = (byDay[dateKey] ?? 0) + 1;
    }
    return byDay.entries.map((e) => {'date': e.key, 'completions': e.value}).toList();
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

  // ── Character Chat ────────────────────────────────────────────

  static Future<void> saveChatMessage(CharacterChatMessage msg) async {
    final d = await db;
    await d.insert('character_chats', {
      'id': msg.id,
      'profileId': msg.profileId,
      'role': msg.role,
      'content': msg.content,
      'timestamp': msg.timestamp.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<CharacterChatMessage>> getChatHistory(String profileId) async {
    final d = await db;
    final rows = await d.query('character_chats',
        where: 'profileId = ?', whereArgs: [profileId],
        orderBy: 'timestamp ASC');
    return rows.map((r) => CharacterChatMessage(
      id: r['id'] as String,
      profileId: r['profileId'] as String,
      role: r['role'] as String,
      content: r['content'] as String,
      timestamp: DateTime.parse(r['timestamp'] as String),
    )).toList();
  }

  static Future<void> clearChatHistory(String profileId) async {
    final d = await db;
    await d.delete('character_chats', where: 'profileId = ?', whereArgs: [profileId]);
  }

  static Future<int> getChatMessageCount(String profileId) async {
    final d = await db;
    final result = await d.rawQuery(
        'SELECT COUNT(*) as cnt FROM character_chats WHERE profileId = ?', [profileId]);
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── Knowledge Cache ───────────────────────────────────────────

  static Future<void> saveKnowledgeCache(String date, int idx,
      Map<String, dynamic> data) async {
    final d = await db;
    await d.insert('knowledge_cache', {
      'date': date,
      'idx': idx,
      'data': jsonEncode(data),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getKnowledgeCache(String date) async {
    final d = await db;
    final rows = await d.query('knowledge_cache',
        where: 'date = ?', whereArgs: [date], orderBy: 'idx ASC');
    return rows.map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>).toList();
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

  // ── Todos ─────────────────────────────────────────────────────

  static Future<List<TodoItem>> getTodos(String profileId) async {
    final d = await db;
    final rows = await d.query('todos',
        where: 'profileId = ?', whereArgs: [profileId],
        orderBy: 'done ASC, createdAt DESC');
    return rows.map((r) => TodoItem.fromMap({
      'id': r['id'],
      'profileId': r['profileId'],
      'content': r['content'],
      'done': r['done'],
      'createdAt': r['createdAt'],
      'doneAt': r['doneAt'],
    })).toList();
  }

  static Future<void> saveTodo(TodoItem todo) async {
    final d = await db;
    await d.insert('todos', {
      'id': todo.id,
      'profileId': todo.profileId,
      'content': todo.content,
      'done': todo.done ? 1 : 0,
      'createdAt': todo.createdAt.toIso8601String(),
      'doneAt': todo.doneAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteTodo(String id) async {
    final d = await db;
    await d.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> toggleTodo(String id, bool done) async {
    final d = await db;
    await d.update('todos',
        {'done': done ? 1 : 0, 'doneAt': done ? DateTime.now().toIso8601String() : null},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── Bonus Challenges ──────────────────────────────────────────

  static Future<List<BonusChallenge>> getBonusChallenges(
      String profileId, String date) async {
    final d = await db;
    final rows = await d.query('bonus_challenges',
        where: 'profileId = ? AND date = ?', whereArgs: [profileId, date]);
    return rows.map((r) => BonusChallenge.fromMap({
      'id': r['id'],
      'profileId': r['profileId'],
      'title': r['title'],
      'type': r['type'],
      'date': r['date'],
      'done': r['done'],
      'points': r['points'],
      'doneAt': r['doneAt'],
    })).toList();
  }

  static Future<void> saveBonusChallenge(BonusChallenge c) async {
    final d = await db;
    await d.insert('bonus_challenges', {
      'id': c.id,
      'profileId': c.profileId,
      'title': c.title,
      'type': c.type,
      'date': c.date,
      'done': c.done ? 1 : 0,
      'points': c.points,
      'doneAt': c.doneAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> completeBonusChallenge(String id) async {
    final d = await db;
    await d.update('bonus_challenges',
        {'done': 1, 'doneAt': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }
}
