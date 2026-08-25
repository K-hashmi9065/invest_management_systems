class AuditLogModel {
  final int id;
  final int? userId;
  final String username;
  final String action;
  final String details;
  final String timestamp;

  AuditLogModel({
    required this.id,
    this.userId,
    required this.username,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as int,
      userId: map['user_id'] as int?,
      username: map['username'] as String,
      action: map['action'] as String,
      details: map['details'] as String,
      timestamp: map['timestamp'] as String,
    );
  }
}
