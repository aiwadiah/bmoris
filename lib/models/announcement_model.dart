class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String createdBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdBy,
    this.isActive = true,
    required this.createdAt,
    this.expiresAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdBy: map['createdBy'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdBy': createdBy,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}
