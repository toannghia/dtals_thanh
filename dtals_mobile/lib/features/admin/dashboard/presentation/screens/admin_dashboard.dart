import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_dashboard_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/modern_card.dart';
import '../../../../../core/widgets/station_mini_map.dart';
import '../../../stations/presentation/screens/station_list_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(adminOverviewProvider);

    return overviewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
      data: (overview) {
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(adminOverviewProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionTitle('Mạng lưới trạm CORS', context),
              const SizedBox(height: 16),
              ref.watch(stationsProvider).maybeWhen(
                    data: (stations) => ModernCard(
                      padding: EdgeInsets.zero,
                      child: StationMiniMap(
                        stations: stations,
                        onTap: () => context.push('/admin/stations'),
                        height: 450,
                      ),
                    ),
                    orElse: () => const SizedBox(
                      height: 450,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              const SizedBox(height: 32),
              _buildSectionTitle('Thống kê hệ thống', context),
              const SizedBox(height: 16),
              _buildStatsChartCard(
                context: context,
                title: 'Trạm CORS',
                total: overview.stations.total,
                active: overview.stations.active,
                inactive: overview.stations.inactive,
                online: overview.stations.online,
                color: AppTheme.primaryColor,
                icon: Icons.cell_tower,
              ),
              const SizedBox(height: 16),
              _buildStatsChartCard(
                context: context,
                title: 'NTRIP Users',
                total: overview.users.total,
                active: overview.users.active,
                inactive: overview.users.inactive,
                online: overview.users.online,
                color: AppTheme.successColor,
                icon: Icons.group,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Thao tác nhanh', context),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSummaryRow(dynamic overview) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Tổng Trạm',
            overview.stations.total.toString(),
            Icons.cell_tower,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Tổng Users',
            overview.users.total.toString(),
            Icons.group,
            AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return ModernCard(
      color: color.withOpacity(0.05),
      padding: const EdgeInsets.all(20),
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final baseTextColor = colorScheme.onSurface;
          final secondaryTextColor = baseTextColor.withOpacity(0.65);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title, 
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value, 
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: baseTextColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsChartCard({
    required BuildContext context,
    required String title,
    required int total,
    required int active,
    required int inactive,
    required int online,
    required Color color,
    required IconData icon,
  }) {
    return ModernCard(
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final baseTextColor = colorScheme.onSurface;
          final secondaryTextColor = baseTextColor.withOpacity(0.65);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: secondaryTextColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: baseTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 140,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 50,
                              startDegreeOffset: -90,
                              sections: [
                                PieChartSectionData(
                                  value: active.toDouble() > 0 ? active.toDouble() : 0.1,
                                  color: color,
                                  title: '',
                                  radius: 16,
                                ),
                                PieChartSectionData(
                                  value: inactive.toDouble() > 0 ? inactive.toDouble() : 0.1,
                                  color: AppTheme.warningColor,
                                  title: '',
                                  radius: 12,
                                ),
                                PieChartSectionData(
                                  value: (total - active - inactive).clamp(0, total).toDouble(),
                                  color: const Color(0xFFF1F5F9), // Slate 100
                                  title: '',
                                  radius: 8,
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Online', 
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$online',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    color: baseTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(context, 'Hoạt động', active, color),
                        const SizedBox(height: 16),
                        _buildLegendItem(context, 'Tạm dừng', inactive, AppTheme.warningColor),
                        const SizedBox(height: 16),
                        _buildLegendItem(context, 'Tổng cộng', total, secondaryTextColor),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, int count, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseTextColor = colorScheme.onSurface;
    final secondaryTextColor = baseTextColor.withOpacity(0.65);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10, 
          height: 10, 
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label, 
              style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.w500),
            ),
            Text(
              '$count', 
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: baseTextColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildActionIcon(context, Icons.verified_user_rounded, 'Duyệt KYC', AppTheme.primaryLight, '/admin/ekyc'),
        _buildActionIcon(context, Icons.sell_rounded, 'Gói cước', AppTheme.successColor, '/admin/ntrip/packages'),
        _buildActionIcon(context, Icons.cell_tower_rounded, 'Trạm CORS', AppTheme.warningColor, '/admin/stations'),
        _buildActionIcon(context, Icons.headset_mic_rounded, 'Hỗ trợ', AppTheme.errorColor, '/admin/support'),
      ],
    );
  }

  Widget _buildActionIcon(BuildContext context, IconData icon, String label, Color color, String route) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
