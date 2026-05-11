import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../models/pronunciation_model.dart';
import '../models/feedback_model.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';
import '../models/weekly_leaderboard_entry.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Expose firestore instance for direct access when needed
  FirebaseFirestore get firestore => _firestore;

  static DateTime getWeekStart([DateTime? date]) {
    final value = date ?? DateTime.now();
    final local = DateTime(value.year, value.month, value.day);
    return local.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  static DateTime getNextWeekStart([DateTime? date]) {
    return getWeekStart(date).add(const Duration(days: 7));
  }

  static String getWeekId([DateTime? date]) {
    final weekStart = getWeekStart(date);
    final month = weekStart.month.toString().padLeft(2, '0');
    final day = weekStart.day.toString().padLeft(2, '0');
    return '${weekStart.year}-$month-$day';
  }

  CollectionReference<Map<String, dynamic>> _weeklyEntriesRef(String weekId) {
    return _firestore
        .collection('weekly_leaderboards')
        .doc(weekId)
        .collection('entries');
  }

  // Lessons
  Future<List<LessonModel>> getLessons() async {
    final snapshot = await _firestore
        .collection('lessons')
        .orderBy('difficulty')
        .get();
    return snapshot.docs
        .map((doc) => LessonModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<LessonModel>> getLessonsByCategory(String category) async {
    final snapshot = await _firestore
        .collection('lessons')
        .where('category', isEqualTo: category)
        .orderBy('difficulty')
        .get();
    return snapshot.docs
        .map((doc) => LessonModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<LessonModel?> getLessonById(String id) async {
    final doc = await _firestore.collection('lessons').doc(id).get();
    if (doc.exists) {
      return LessonModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> createLesson(LessonModel lesson) async {
    await _firestore.collection('lessons').add(lesson.toMap());
  }

  Future<void> updateLesson(String id, Map<String, dynamic> data) async {
    await _firestore.collection('lessons').doc(id).update(data);
  }

  Future<void> deleteLesson(String id) async {
    await _firestore.collection('lessons').doc(id).delete();
  }

  // Quizzes
  Future<List<QuizModel>> getQuizzesByLesson(String lessonId) async {
    final snapshot = await _firestore
        .collection('quizzes')
        .where('lessonId', isEqualTo: lessonId)
        .orderBy('difficulty')
        .get();
    return snapshot.docs
        .map((doc) => QuizModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<QuizModel>> getQuizzes() async {
    final snapshot = await _firestore
        .collection('quizzes')
        .orderBy('difficulty')
        .get();
    return snapshot.docs
        .map((doc) => QuizModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<QuizModel?> getQuizById(String id) async {
    final doc = await _firestore.collection('quizzes').doc(id).get();
    if (!doc.exists) return null;
    return QuizModel.fromMap(doc.data()!, doc.id);
  }

  Future<List<QuizModel>> getQuizzesByDifficulty(int difficulty) async {
    final snapshot = await _firestore
        .collection('quizzes')
        .where('difficulty', isEqualTo: difficulty)
        .get();
    return snapshot.docs
        .map((doc) => QuizModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> saveQuizAttempt(QuizAttempt attempt) async {
    await _firestore.collection('quiz_attempts').add(attempt.toMap());
  }

  Future<List<QuizAttempt>> getUserQuizAttempts(String userId) async {
    final snapshot = await _firestore
        .collection('quiz_attempts')
        .where('userId', isEqualTo: userId)
        .orderBy('attemptedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => QuizAttempt.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Pronunciation
  Future<void> savePronunciationAttempt(PronunciationAttempt attempt) async {
    await _firestore.collection('pronunciation_attempts').add(attempt.toMap());
  }

  Future<List<PronunciationAttempt>> getUserPronunciationHistory(String userId) async {
    final snapshot = await _firestore
        .collection('pronunciation_attempts')
        .where('userId', isEqualTo: userId)
        .orderBy('attemptedAt', descending: true)
        .limit(50)
        .get();
    return snapshot.docs
        .map((doc) => PronunciationAttempt.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Feedback
  Future<void> sendFeedback(FeedbackModel feedback) async {
    await _firestore.collection('feedback').add(feedback.toMap());
  }

  Future<List<FeedbackModel>> getAllFeedback() async {
    final snapshot = await _firestore
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => FeedbackModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<FeedbackModel>> getFilteredFeedback({
    int? rating,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allFeedback = await getAllFeedback();
    return allFeedback.where((feedback) {
      final matchesRating = rating == null || feedback.rating == rating;
      final createdAt = feedback.createdAt;
      final matchesStart = startDate == null || !createdAt.isBefore(startDate);
      final matchesEnd = endDate == null || !createdAt.isAfter(endDate);
      return matchesRating && matchesStart && matchesEnd;
    }).toList();
  }

  Future<void> respondToFeedback(
    String id, {
    required String status,
    required String response,
  }) async {
    await _firestore.collection('feedback').doc(id).update({
      'status': status,
      'adminResponse': response,
      'respondedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteFeedback(String id) async {
    await _firestore.collection('feedback').doc(id).delete();
  }

  // Announcements
  Future<List<AnnouncementModel>> getAnnouncements() async {
    final snapshot = await _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => AnnouncementModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<AnnouncementModel>> getActiveAnnouncements() async {
    final announcements = await getAnnouncements();
    final now = DateTime.now();

    return announcements.where((announcement) {
      if (!announcement.isActive) {
        return false;
      }

      if (announcement.expiresAt != null &&
          announcement.expiresAt!.isBefore(now)) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    await _firestore.collection('announcements').add(announcement.toMap());
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> data) async {
    await _firestore.collection('announcements').doc(id).update(data);
  }

  // Leaderboard
  Future<List<UserModel>> getLeaderboard({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .orderBy('xp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<UserModel>> getLeaderboardByStreak({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .orderBy('streak', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      return null;
    }
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<int?> getLifetimeLeaderboardRank(String userId) async {
    final user = await getUserById(userId);
    if (user == null || user.role != 'user') {
      return null;
    }

    final higherSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .where('xp', isGreaterThan: user.xp)
        .get();
    return higherSnapshot.docs.length + 1;
  }

  Future<int?> getLifetimeLeaderboardGapToNextRank(String userId) async {
    final user = await getUserById(userId);
    if (user == null || user.role != 'user') {
      return null;
    }

    final higherSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .where('xp', isGreaterThan: user.xp)
        .get();
    if (higherSnapshot.docs.isEmpty) {
      return 0;
    }

    final nextXp = higherSnapshot.docs
        .map((doc) => (doc.data()['xp'] ?? 0) as int)
        .reduce((value, element) => value < element ? value : element);
    return nextXp - user.xp;
  }

  Future<List<WeeklyLeaderboardEntry>> getWeeklyLeaderboard({
    int limit = 50,
    String? weekId,
  }) async {
    final resolvedWeekId = weekId ?? getWeekId();
    final snapshot = await _weeklyEntriesRef(resolvedWeekId)
        .orderBy('xp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => WeeklyLeaderboardEntry.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<WeeklyLeaderboardEntry?> getWeeklyLeaderboardEntry(
    String userId, {
    String? weekId,
  }) async {
    final resolvedWeekId = weekId ?? getWeekId();
    final doc = await _weeklyEntriesRef(resolvedWeekId).doc(userId).get();
    if (!doc.exists) {
      return null;
    }
    return WeeklyLeaderboardEntry.fromMap(doc.data()!, doc.id);
  }

  Future<int?> getWeeklyLeaderboardRank(
    String userId, {
    String? weekId,
  }) async {
    final entry = await getWeeklyLeaderboardEntry(userId, weekId: weekId);
    if (entry == null) {
      return null;
    }

    final higherSnapshot = await _weeklyEntriesRef(weekId ?? getWeekId())
        .where('xp', isGreaterThan: entry.xp)
        .get();
    return higherSnapshot.docs.length + 1;
  }

  Future<int?> getWeeklyLeaderboardGapToNextRank(
    String userId, {
    String? weekId,
  }) async {
    final resolvedWeekId = weekId ?? getWeekId();
    final entry = await getWeeklyLeaderboardEntry(userId, weekId: resolvedWeekId);
    if (entry == null) {
      return null;
    }

    final higherSnapshot = await _weeklyEntriesRef(resolvedWeekId)
        .where('xp', isGreaterThan: entry.xp)
        .orderBy('xp')
        .limit(1)
        .get();
    if (higherSnapshot.docs.isEmpty) {
      return 0;
    }

    final nextEntry = WeeklyLeaderboardEntry.fromMap(
      higherSnapshot.docs.first.data(),
      higherSnapshot.docs.first.id,
    );
    return nextEntry.xp - entry.xp;
  }

  Future<void> syncWeeklyXpFromAdminDelta({
    required UserModel user,
    required Map<String, dynamic> updates,
  }) async {
    final xpDelta = ((updates['xp'] as int?) ?? user.xp) - user.xp;
    final mergedName = (updates['name'] as String?) ?? user.name;
    final mergedPhotoUrl = updates['photoUrl'] as String? ?? user.photoUrl;
    final mergedStreak = (updates['streak'] as int?) ?? user.streak;
    final mergedLevel = (updates['currentLevel'] as int?) ?? user.currentLevel;

    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(user.uid);
      transaction.update(userRef, updates);

      if (user.role != 'user') {
        return;
      }

      final weekId = getWeekId();
      final weeklyRef = _weeklyEntriesRef(weekId).doc(user.uid);
      final weeklyDoc = await transaction.get(weeklyRef);
      final currentWeeklyXp = weeklyDoc.exists
          ? ((weeklyDoc.data()?['xp'] ?? 0) as int)
          : 0;
      final nextWeeklyXp = xpDelta == 0
          ? currentWeeklyXp
          : (currentWeeklyXp + xpDelta).clamp(0, 1 << 31).toInt();

      final payload = {
        'userId': user.uid,
        'name': mergedName,
        'photoUrl': mergedPhotoUrl,
        'xp': nextWeeklyXp,
        'streak': mergedStreak,
        'currentLevel': mergedLevel,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      transaction.set(weeklyRef, payload, SetOptions(merge: true));
    });
  }

  // Admin - User Management
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Map<String, dynamic>> getUserAnalytics() async {
    final users = await _firestore.collection('users').get();
    final pronunciations = await _firestore.collection('pronunciation_attempts').get();
    final quizAttempts = await _firestore.collection('quiz_attempts').get();

    int totalXp = 0;
    int totalStreak = 0;
    for (var doc in users.docs) {
      totalXp += (doc.data()['xp'] ?? 0) as int;
      totalStreak += (doc.data()['streak'] ?? 0) as int;
    }

    return {
      'totalUsers': users.docs.length,
      'totalPronunciationAttempts': pronunciations.docs.length,
      'totalQuizAttempts': quizAttempts.docs.length,
      'averageXp': users.docs.isNotEmpty ? totalXp ~/ users.docs.length : 0,
      'averageStreak': users.docs.isNotEmpty ? totalStreak ~/ users.docs.length : 0,
    };
  }
}
