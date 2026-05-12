class WeeklyLeaderboardEntry {
  final String userId;
  final String name;
  final String? photoUrl;
  final int xp;
  final int streak;
  final int currentLevel;
  final DateTime updatedAt;

  const WeeklyLeaderboardEntry({
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.xp,
    required this.streak,
    required this.currentLevel,
    required this.updatedAt,
  });

  factory WeeklyLeaderboardEntry.fromMap(Map<String, dynamic> map, String userId) {
    return WeeklyLeaderboardEntry(
      userId: map['userId'] ?? userId,
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      xp: map['xp'] ?? 0,
      streak: map['streak'] ?? 0,
      currentLevel: map['currentLevel'] ?? 1,
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'photoUrl': photoUrl,
      'xp': xp,
      'streak': streak,
      'currentLevel': currentLevel,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
