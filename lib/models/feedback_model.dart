class FeedbackModel {
  final String id;
  final String oderId;
  final String userName;
  final String subject;
  final String category;
  final String message;
  final int rating;
  final String status; // 'pending', 'reviewed', 'resolved'
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FeedbackModel({
    required this.id,
    required this.oderId,
    required this.userName,
    required this.subject,
    this.category = 'General',
    required this.message,
    this.rating = 5,
    this.status = 'pending',
    this.adminResponse,
    required this.createdAt,
    this.respondedAt,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      oderId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      subject: map['subject'] ?? '',
      category: map['category'] ?? 'General',
      message: map['message'] ?? '',
      rating:
          map['rating'] is num
              ? (map['rating'] as num).toInt()
              : int.tryParse('${map['rating']}') ?? 5,
      status: map['status'] ?? 'pending',
      adminResponse: map['adminResponse'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      respondedAt:
          map['respondedAt'] != null
              ? DateTime.parse(map['respondedAt'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': oderId,
      'userName': userName,
      'subject': subject,
      'category': category,
      'message': message,
      'rating': rating,
      'status': status,
      'adminResponse': adminResponse,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }
}
