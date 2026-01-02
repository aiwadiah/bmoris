import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/firestore_service.dart';
import '../services/offline_service.dart';

class LessonProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final OfflineService _offlineService = OfflineService();

  List<LessonModel> _lessons = [];
  List<LessonModel> _offlineLessons = [];
  LessonModel? _currentLesson;
  bool _isLoading = false;
  String? _error;

  List<LessonModel> get lessons => _lessons;
  List<LessonModel> get offlineLessons => _offlineLessons;
  LessonModel? get currentLesson => _currentLesson;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLessons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lessons = await _firestoreService.getLessons();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load lessons';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLessonsByCategory(String category) async {
    _isLoading = true;
    notifyListeners();

    try {
      _lessons = await _firestoreService.getLessonsByCategory(category);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load lessons';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOfflineLessons() async {
    _offlineLessons = await _offlineService.getOfflineLessons();
    notifyListeners();
  }

  Future<void> downloadLesson(LessonModel lesson) async {
    await _offlineService.saveLesson(lesson);
    await loadOfflineLessons();
  }

  Future<void> removeOfflineLesson(String lessonId) async {
    await _offlineService.deleteOfflineLesson(lessonId);
    await loadOfflineLessons();
  }

  Future<bool> isLessonOffline(String lessonId) async {
    return await _offlineService.isLessonOffline(lessonId);
  }

  void setCurrentLesson(LessonModel lesson) {
    _currentLesson = lesson;
    notifyListeners();
  }

  List<LessonModel> getLessonsByDifficulty(int difficulty) {
    return _lessons.where((l) => l.difficulty == difficulty).toList();
  }

  List<String> getCategories() {
    return _lessons.map((l) => l.category).toSet().toList();
  }
}
