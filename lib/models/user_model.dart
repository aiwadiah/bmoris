class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? photoUrl;
  final String role;
  final int xp;
  final int streak;
  final List<String> badges;
  final int currentLevel;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int dailyGoalTarget;
  final int dailyActivitiesCount;
  final String lastActivityDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.photoUrl,
    this.role = 'user',
    this.xp = 0,
    this.streak = 0,
    this.badges = const [],
    this.currentLevel = 1,
    required this.createdAt,
    required this.lastLoginAt,
    this.dailyGoalTarget = 5,
    this.dailyActivitiesCount = 0,
    this.lastActivityDate = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'],
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'user',
      xp: map['xp'] ?? 0,
      streak: map['streak'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      currentLevel: map['currentLevel'] ?? 1,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: DateTime.parse(map['lastLoginAt'] ?? DateTime.now().toIso8601String()),
      dailyGoalTarget: map['dailyGoalTarget'] ?? 5,
      dailyActivitiesCount: map['dailyActivitiesCount'] ?? 0,
      lastActivityDate: map['lastActivityDate'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role,
      'xp': xp,
      'streak': streak,
      'badges': badges,
      'currentLevel': currentLevel,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'dailyGoalTarget': dailyGoalTarget,
      'dailyActivitiesCount': dailyActivitiesCount,
      'lastActivityDate': lastActivityDate,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    String? role,
    int? xp,
    int? streak,
    List<String>? badges,
    int? currentLevel,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? dailyGoalTarget,
    int? dailyActivitiesCount,
    String? lastActivityDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      badges: badges ?? this.badges,
      currentLevel: currentLevel ?? this.currentLevel,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      dailyGoalTarget: dailyGoalTarget ?? this.dailyGoalTarget,
      dailyActivitiesCount: dailyActivitiesCount ?? this.dailyActivitiesCount,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  bool get isAdmin => role == 'admin';
}
