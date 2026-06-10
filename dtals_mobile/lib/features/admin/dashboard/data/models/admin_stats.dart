// lib/features/admin/dashboard/data/models/admin_stats.dart

class AdminStats {
  final int total;
  final int active;
  final int inactive;
  final int online;

  AdminStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.online,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json, {bool isUser = false}) {
    if (isUser) {
      final byStatus = json['byStatus'] ?? {};
      return AdminStats(
        total: json['totalUsers'] ?? 0,
        active: byStatus['enabled'] ?? 0,
        inactive: byStatus['disabled'] ?? 0,
        online: json['totalOnline'] ?? 0,
      );
    } else {
      final byStatus = json['byStatus'] ?? {};
      final byConnection = json['byConnection'] ?? {};
      return AdminStats(
        total: json['total'] ?? 0,
        active: byStatus['running'] ?? 0,
        inactive: byStatus['stopped'] ?? 0,
        online: byConnection['online'] ?? 0,
      );
    }
  }
}

class SystemOverview {
  final AdminStats stations;
  final AdminStats users;

  SystemOverview({required this.stations, required this.users});

  factory SystemOverview.fromJson(Map<String, dynamic> json) {
    return SystemOverview(
      stations: AdminStats.fromJson(json['stations'] ?? {}),
      users: AdminStats.fromJson(json['users'] ?? {}, isUser: true),
    );
  }
}
