class NotificationModel {
  final int id;
  final int? userId;
  final String title;
  final String message;
  final String type;
  final String createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int,
      userId: map['user_id'] as int?,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String,
      createdAt: map['created_at'] as String,
      isRead: (map['is_read'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'created_at': createdAt,
      'is_read': isRead ? 1 : 0,
    };
  }
}
