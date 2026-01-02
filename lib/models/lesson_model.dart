class LessonModel {
  final String id;
  final String title;
  final String titleMalay;
  final String description;
  final int difficulty; // 1-5
  final String category;
  final List<LessonContent> contents;
  final int xpReward;
  final bool isOfflineAvailable;
  final DateTime createdAt;

  LessonModel({
    required this.id,
    required this.title,
    required this.titleMalay,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.contents,
    this.xpReward = 10,
    this.isOfflineAvailable = false,
    required this.createdAt,
  });

  factory LessonModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle createdAt which might be Timestamp or String
    DateTime parsedCreatedAt;
    try {
      if (map['createdAt'] == null) {
        parsedCreatedAt = DateTime.now();
      } else if (map['createdAt'] is String) {
        parsedCreatedAt = DateTime.parse(map['createdAt']);
      } else {
        // Firestore Timestamp
        parsedCreatedAt = (map['createdAt'] as dynamic).toDate();
      }
    } catch (e) {
      parsedCreatedAt = DateTime.now();
    }

    return LessonModel(
      id: id,
      title: map['title'] ?? '',
      titleMalay: map['titleMalay'] ?? '',
      description: map['description'] ?? '',
      difficulty: map['difficulty'] ?? 1,
      category: map['category'] ?? '',
      contents: (map['contents'] as List<dynamic>?)
              ?.map((e) => LessonContent.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      xpReward: map['xpReward'] ?? 10,
      isOfflineAvailable: map['isOfflineAvailable'] ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'titleMalay': titleMalay,
      'description': description,
      'difficulty': difficulty,
      'category': category,
      'contents': contents.map((e) => e.toMap()).toList(),
      'xpReward': xpReward,
      'isOfflineAvailable': isOfflineAvailable,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class LessonContent {
  final String type; // 'text', 'audio', 'pronunciation', 'quiz'
  final String malay;
  final String english;
  final String? audioUrl;
  final List<String>? phonemes;

  LessonContent({
    this.type = 'text',
    required this.malay,
    required this.english,
    this.audioUrl,
    this.phonemes,
  });

  factory LessonContent.fromMap(Map<String, dynamic> map) {
    return LessonContent(
      type: map['type'] ?? 'text',
      malay: map['malay'] ?? '',
      english: map['english'] ?? '',
      audioUrl: map['audioUrl'],
      phonemes: map['phonemes'] != null ? List<String>.from(map['phonemes']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'malay': malay,
      'english': english,
      'audioUrl': audioUrl,
      'phonemes': phonemes,
    };
  }
}
