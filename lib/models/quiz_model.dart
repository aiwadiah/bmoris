class QuizModel {
  final String id;
  final String lessonId;
  final String question;
  final String questionMalay;
  final List<String> options;
  final int correctIndex;
  final int difficulty;
  final String category;
  final String type; // 'multiple_choice', 'fill_blank', 'pronunciation'
  final int xpReward;

  QuizModel({
    required this.id,
    required this.lessonId,
    required this.question,
    required this.questionMalay,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    this.category = 'General',
    required this.type,
    this.xpReward = 5,
  });

  factory QuizModel.fromMap(Map<String, dynamic> map, String id) {
    return QuizModel(
      id: id,
      lessonId: map['lessonId'] ?? '',
      question: map['question'] ?? '',
      questionMalay: map['questionMalay'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
      difficulty: map['difficulty'] ?? 1,
      category: map['category'] ?? 'General',
      type: map['type'] ?? 'multiple_choice',
      xpReward: map['xpReward'] ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'question': question,
      'questionMalay': questionMalay,
      'options': options,
      'correctIndex': correctIndex,
      'difficulty': difficulty,
      'category': category,
      'type': type,
      'xpReward': xpReward,
    };
  }
}

class QuizAttempt {
  final String id;
  final String oderId;
  final String quizId;
  final int selectedIndex;
  final bool isCorrect;
  final DateTime attemptedAt;

  QuizAttempt({
    required this.id,
    required this.oderId,
    required this.quizId,
    required this.selectedIndex,
    required this.isCorrect,
    required this.attemptedAt,
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> map, String id) {
    return QuizAttempt(
      id: id,
      oderId: map['userId'] ?? '',
      quizId: map['quizId'] ?? '',
      selectedIndex: map['selectedIndex'] ?? 0,
      isCorrect: map['isCorrect'] ?? false,
      attemptedAt: DateTime.parse(map['attemptedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': oderId,
      'quizId': quizId,
      'selectedIndex': selectedIndex,
      'isCorrect': isCorrect,
      'attemptedAt': attemptedAt.toIso8601String(),
    };
  }
}
