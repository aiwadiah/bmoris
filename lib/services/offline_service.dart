import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/lesson_model.dart';

class OfflineLessonMetadata {
  final String lessonId;
  final DateTime downloadedAt;
  final DateTime? lastAccessed;
  final int sizeBytes;

  const OfflineLessonMetadata({
    required this.lessonId,
    required this.downloadedAt,
    required this.sizeBytes,
    this.lastAccessed,
  });
}

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
    await db.insert('lessons', {
      'id': lesson.id,
      'data': jsonEncode(lesson.toMap()),
      'downloaded_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<List<OfflineLessonMetadata>> getOfflineLessonMetadata() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT lessons.id, lessons.data, lessons.downloaded_at, progress.last_accessed
      FROM lessons
      LEFT JOIN progress ON lessons.id = progress.lesson_id
    ''');

    return results.map((row) {
      final downloadedAtText = row['downloaded_at'] as String?;
      final lastAccessedText = row['last_accessed'] as String?;
      final data = row['data'] as String? ?? '';

      return OfflineLessonMetadata(
        lessonId: row['id'] as String,
        downloadedAt:
            downloadedAtText == null
                ? DateTime.now()
                : DateTime.tryParse(downloadedAtText) ?? DateTime.now(),
        lastAccessed:
            lastAccessedText == null
                ? null
                : DateTime.tryParse(lastAccessedText),
        sizeBytes: utf8.encode(data).length,
      );
    }).toList();
  }

  Future<int> getOfflineStorageUsageBytes() async {
    final db = await database;
    final pageCountResult = await db.rawQuery('PRAGMA page_count');
    final pageSizeResult = await db.rawQuery('PRAGMA page_size');

    final pageCount = Sqflite.firstIntValue(pageCountResult) ?? 0;
    final pageSize = Sqflite.firstIntValue(pageSizeResult) ?? 0;
    return pageCount * pageSize;
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
    await db.delete('lessons', where: 'id = ?', whereArgs: [lessonId]);
  }

  // Save lesson progress
  Future<void> saveLessonProgress({
    required String lessonId,
    required bool completed,
    required double score,
  }) async {
    final db = await database;
    await db.insert('progress', {
      'lesson_id': lessonId,
      'completed': completed ? 1 : 0,
      'score': score,
      'last_accessed': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> recordLessonAccess(String lessonId) async {
    final db = await database;
    final timestamp = DateTime.now().toIso8601String();
    final existing = await db.query(
      'progress',
      columns: ['lesson_id'],
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );

    if (existing.isEmpty) {
      await db.insert('progress', {
        'lesson_id': lessonId,
        'last_accessed': timestamp,
      });
      return;
    }

    await db.update(
      'progress',
      {'last_accessed': timestamp},
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
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
