// lib/features/profile/data/models/user_model.dart

class UserModel {
  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String role;

  UserModel({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.phoneNumber,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      fullName: json['fullName']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      role: json['role'] is Map 
          ? (json['role']['name']?.toString() ?? '') 
          : (json['role']?.toString() ?? ''),
    );
  }
}
