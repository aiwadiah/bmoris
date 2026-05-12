import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/firestore_service.dart';

class QuizProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<QuizModel> _quizzes = [];
  int _currentQuizIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int _currentDifficulty = 1;
  bool _isLoading = false;
  bool _isCompleted = false;
  List<int> _userAnswers = [];

  List<QuizModel> get quizzes => _quizzes;
  QuizModel? get currentQuiz =>
      _currentQuizIndex < _quizzes.length ? _quizzes[_currentQuizIndex] : null;
  int get currentQuizIndex => _currentQuizIndex;
  int get score => _score;
  int get correctAnswers => _correctAnswers;
  int get totalQuestions => _quizzes.length;
  bool get isLoading => _isLoading;
  bool get isCompleted => _isCompleted;
  int get currentDifficulty => _currentDifficulty;
  List<int> get userAnswers => _userAnswers;

  Future<void> loadQuizzes(String lessonId) async {
    _isLoading = true;
    _currentQuizIndex = 0;
    _score = 0;
    _correctAnswers = 0;
    _isCompleted = false;
    _userAnswers = [];
    notifyListeners();

    try {
      _quizzes = await _firestoreService.getQuizzesByLesson(lessonId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAdaptiveQuizzes(int difficulty) async {
    _isLoading = true;
    _currentQuizIndex = 0;
    _score = 0;
    _correctAnswers = 0;
    _isCompleted = false;
    _userAnswers = [];
    _currentDifficulty = difficulty;
    notifyListeners();

    try {
      _quizzes = await _firestoreService.getQuizzesByDifficulty(difficulty);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void answerQuestion(int selectedIndex, String userId) {
    if (currentQuiz == null) return;

    _userAnswers.add(selectedIndex);
    final isCorrect = selectedIndex == currentQuiz!.correctIndex;

    if (isCorrect) {
      _correctAnswers++;
      _score += currentQuiz!.xpReward;
    }

    // Save attempt
    final attempt = QuizAttempt(
      id: '',
      userId: userId,
      quizId: currentQuiz!.id,
      selectedIndex: selectedIndex,
      isCorrect: isCorrect,
      attemptedAt: DateTime.now(),
      difficulty: currentQuiz!.difficulty,
      category: currentQuiz!.category,
    );
    _firestoreService.saveQuizAttempt(attempt);

    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuizIndex < _quizzes.length - 1) {
      _currentQuizIndex++;
      notifyListeners();
    } else {
      _isCompleted = true;
      _adaptDifficulty();
      notifyListeners();
    }
  }

  void _adaptDifficulty() {
    final percentage = _quizzes.isNotEmpty
        ? _correctAnswers / _quizzes.length
        : 0.0;

    if (percentage >= 0.8 && _currentDifficulty < 5) {
      _currentDifficulty++;
    } else if (percentage < 0.5 && _currentDifficulty > 1) {
      _currentDifficulty--;
    }
  }

  int getRecommendedDifficulty() {
    return _currentDifficulty;
  }

  void reset() {
    _currentQuizIndex = 0;
    _score = 0;
    _correctAnswers = 0;
    _isCompleted = false;
    _userAnswers = [];
    notifyListeners();
  }

  double get accuracyPercentage {
    if (_quizzes.isEmpty) return 0;
    return (_correctAnswers / _quizzes.length) * 100;
  }
}
