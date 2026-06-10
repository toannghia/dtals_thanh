import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_dashboard_repository.dart';
import '../../data/models/admin_stats.dart';

final adminOverviewProvider = FutureProvider<SystemOverview>((ref) async {
  final repository = AdminDashboardRepository();
  return repository.getOverview();
});

final adminStationStatsProvider = FutureProvider<AdminStats>((ref) async {
  final repository = AdminDashboardRepository();
  return repository.getStationStats();
});

final adminUserStatsProvider = FutureProvider<AdminStats>((ref) async {
  final repository = AdminDashboardRepository();
  return repository.getUserStats();
});
