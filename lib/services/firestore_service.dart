import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../models/pronunciation_model.dart';
import '../models/feedback_model.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Expose firestore instance for direct access when needed
  FirebaseFirestore get firestore => _firestore;

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
    final snapshot = await _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => AnnouncementModel.fromMap(doc.data(), doc.id))
        .toList();
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
