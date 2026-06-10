// lib/features/end_user/ntrip_accounts/data/models/ntrip_account.dart

class NtripAccount {
  final String id;
  final String username;
  final String password;
  final String mountpoint;
  final String packageName;
  final DateTime? expiryDate;
  final int status; // 1: active, 0: disabled

  NtripAccount({
    required this.id,
    required this.username,
    required this.password,
    required this.mountpoint,
    required this.packageName,
    this.expiryDate,
    required this.status,
  });

  factory NtripAccount.fromJson(Map<String, dynamic> json) {
    return NtripAccount(
      id: json['id']?.toString() ?? '0',
      username: json['name'] ?? json['ntripAccountName'] ?? json['username'] ?? '',
      password: json['userPwd'] ?? json['ntripPassword'] ?? json['password'] ?? '',
      mountpoint: json['mountpoint'] ?? 'RTK',
      packageName: json['packageName'] ?? '',
      status: json['status'] ?? (json['enabled'] == true || json['enabled'] == 1 ? 1 : 0),
      expiryDate: json['endTime'] != null 
          ? (json['endTime'] is int ? DateTime.fromMillisecondsSinceEpoch(json['endTime']) : DateTime.tryParse(json['endTime'].toString()))
          : (json['expiredDate'] != null ? DateTime.tryParse(json['expiredDate'].toString()) : null),
    );
  }

  bool get isActive => status == 1;
}
