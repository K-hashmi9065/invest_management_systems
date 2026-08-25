class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final int? memberId;
  final String createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.memberId,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      role: map['role'] as String,
      memberId: map['member_id'] as int?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'member_id': memberId,
      'created_at': createdAt,
    };
  }
}
