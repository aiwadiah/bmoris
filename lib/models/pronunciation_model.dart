class PronunciationAttempt {
  final String id;
  final String userId;
  final String targetText;
  final String spokenText;
  final double accuracyScore;
  final List<PhonemeAnalysis> phonemeAnalysis;
  final String feedback;
  final DateTime attemptedAt;

  PronunciationAttempt({
    required this.id,
    required this.userId,
    required this.targetText,
    required this.spokenText,
    required this.accuracyScore,
    required this.phonemeAnalysis,
    required this.feedback,
    required this.attemptedAt,
  });

  factory PronunciationAttempt.fromMap(Map<String, dynamic> map, String id) {
    // Handle attemptedAt which might be Timestamp or String
    DateTime parsedAttemptedAt;
    try {
      if (map['attemptedAt'] == null) {
        parsedAttemptedAt = DateTime.now();
      } else if (map['attemptedAt'] is String) {
        parsedAttemptedAt = DateTime.parse(map['attemptedAt']);
      } else {
        // Firestore Timestamp
        parsedAttemptedAt = (map['attemptedAt'] as dynamic).toDate();
      }
    } catch (e) {
      parsedAttemptedAt = DateTime.now();
    }

    return PronunciationAttempt(
      id: id,
      userId: map['userId'] ?? '',
      targetText: map['targetText'] ?? '',
      spokenText: map['spokenText'] ?? '',
      accuracyScore: (map['accuracyScore'] ?? 0).toDouble(),
      phonemeAnalysis: (map['phonemeAnalysis'] as List<dynamic>?)
              ?.map((e) => PhonemeAnalysis.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      feedback: map['feedback'] ?? '',
      attemptedAt: parsedAttemptedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'targetText': targetText,
      'spokenText': spokenText,
      'accuracyScore': accuracyScore,
      'phonemeAnalysis': phonemeAnalysis.map((e) => e.toMap()).toList(),
      'feedback': feedback,
      'attemptedAt': attemptedAt.toIso8601String(),
    };
  }
}

class PhonemeAnalysis {
  final String phoneme;
  final bool isCorrect;
  final double score;
  final String suggestion;

  PhonemeAnalysis({
    required this.phoneme,
    required this.isCorrect,
    required this.score,
    required this.suggestion,
  });

  factory PhonemeAnalysis.fromMap(Map<String, dynamic> map) {
    return PhonemeAnalysis(
      phoneme: map['phoneme'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
      score: (map['score'] ?? 0).toDouble(),
      suggestion: map['suggestion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneme': phoneme,
      'isCorrect': isCorrect,
      'score': score,
      'suggestion': suggestion,
    };
  }
}
