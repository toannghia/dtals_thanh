class AdminEndUser {
  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String status;
  final String kycStatus;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AdminEndUser({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.phoneNumber,
    required this.status,
    required this.kycStatus,
    required this.createdAt,
    this.lastLogin,
  });

  factory AdminEndUser.fromJson(Map<String, dynamic> json) {
    return AdminEndUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      kycStatus: json['kycStatus']?.toString() ?? 'NONE',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      lastLogin: json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt'].toString()) : null,
    );
  }
}

class SystemUser {
  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final List<String> roles;
  final bool isActive;
  final String status;

  SystemUser({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    required this.roles,
    required this.isActive,
    required this.status,
  });

  factory SystemUser.fromJson(Map<String, dynamic> json) {
    // Backend may return role as object {name: 'ADMIN'} or as roleName string
    List<String> parseRoles(Map<String, dynamic> j) {
      if (j['roles'] is List) return List<String>.from(j['roles']);
      if (j['role'] is Map) return [j['role']['name']?.toString() ?? 'N/A'];
      if (j['roleName'] is String) return [j['roleName']];
      if (j['role'] is String) return [j['role']];
      return ['N/A'];
    }

    final status = json['status']?.toString() ?? 'ACTIVE';
    return SystemUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      email: json['email']?.toString(),
      roles: parseRoles(json),
      isActive: status == 'ACTIVE',
      status: status,
    );
  }
}
