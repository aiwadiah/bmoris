import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/lesson_model.dart';

class OfflineService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/bmoris_offline.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE lessons (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            downloaded_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE progress (
            lesson_id TEXT PRIMARY KEY,
            completed INTEGER DEFAULT 0,
            score REAL DEFAULT 0,
            last_accessed TEXT
          )
        ''');
      },
    );
  }

  // Save lesson for offline access
  Future<void> saveLesson(LessonModel lesson) async {
    final db = await database;
    await db.insert(
      'lessons',
      {
        'id': lesson.id,
        'data': jsonEncode(lesson.toMap()),
        'downloaded_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get offline lessons
  Future<List<LessonModel>> getOfflineLessons() async {
    final db = await database;
    final results = await db.query('lessons');

    return results.map((row) {
      final data = jsonDecode(row['data'] as String);
      return LessonModel.fromMap(data, row['id'] as String);
    }).toList();
  }

  // Check if lesson is available offline
  Future<bool> isLessonOffline(String lessonId) async {
    final db = await database;
    final results = await db.query(
      'lessons',
      where: 'id = ?',
      whereArgs: [lessonId],
    );
    return results.isNotEmpty;
  }

  // Delete offline lesson
  Future<void> deleteOfflineLesson(String lessonId) async {
    final db = await database;
    await db.delete(
      'lessons',
      where: 'id = ?',
      whereArgs: [lessonId],
    );
  }

  // Save lesson progress
  Future<void> saveLessonProgress({
    required String lessonId,
    required bool completed,
    required double score,
  }) async {
    final db = await database;
    await db.insert(
      'progress',
      {
        'lesson_id': lessonId,
        'completed': completed ? 1 : 0,
        'score': score,
        'last_accessed': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get lesson progress
  Future<Map<String, dynamic>?> getLessonProgress(String lessonId) async {
    final db = await database;
    final results = await db.query(
      'progress',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // SharedPreferences for simple data
  Future<void> saveUserData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getUserData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> clearAllOfflineData() async {
    final db = await database;
    await db.delete('lessons');
    await db.delete('progress');

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
