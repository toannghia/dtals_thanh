import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/government_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/modern_card.dart';
import '../../../../../core/widgets/station_mini_map.dart';
import 'gov_stations_screen.dart';
import 'package:go_router/go_router.dart';

final govDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = GovernmentRepository();
  return repository.getDashboard();
});

class GovDashboardScreen extends ConsumerWidget {
  const GovDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(govDashboardProvider);
    final stationsAsync = ref.watch(govStationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan Nhà nước')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(govDashboardProvider);
              ref.invalidate(govStationsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bản đồ trạm khu vực', 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/gov/stations'),
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ModernCard(
                  padding: EdgeInsets.zero,
                  child: stationsAsync.maybeWhen(
                    data: (stations) => StationMiniMap(
                      stations: stations,
                      onTap: () => context.push('/gov/stations'),
                    ),
                    orElse: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatsGrid(stats),
                const SizedBox(height: 24),
                _buildRecentActivity(stats, context),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildCombinedStatCard(
            title: 'Trạm CORS',
            icon: Icons.cell_tower_rounded,
            color: AppTheme.primaryColor,
            label1: 'Tổng số',
            value1: '${stats['totalStations'] ?? 0}',
            label2: 'Hoạt động',
            value2: '${stats['activeStations'] ?? 0}',
            color2: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCombinedStatCard(
            title: 'Phiếu hỗ trợ',
            icon: Icons.assignment_rounded,
            color: AppTheme.warningColor,
            label1: 'Yêu cầu',
            value1: '${stats['totalTickets'] ?? 0}',
            label2: 'Đã xử lý',
            value2: '${stats['closedTickets'] ?? 0}',
            color2: AppTheme.infoColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCombinedStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required String label1,
    required String value1,
    required String label2,
    required String value2,
    required Color color2,
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow(label1, value1, color),
          const SizedBox(height: 12),
          _buildStatRow(label2, value2, color2),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: valueColor)),
      ],
    );
  }

  Widget _buildRecentActivity(Map<String, dynamic> stats, BuildContext context) {
    final activities = stats['recentActivities'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoạt động gần đây', 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        if (activities.isEmpty) 
          const ModernCard(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Chưa có hoạt động nào',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else 
          ModernCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final a = activities[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, size: 20, color: AppTheme.infoColor),
                  ),
                  title: Text(
                    a['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      a['time'] ?? '',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
