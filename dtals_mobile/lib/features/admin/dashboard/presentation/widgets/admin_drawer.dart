import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'DTALS Management System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: 'Tổng quan',
                  route: '/admin',
                  isSelected: currentPath == '/admin',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Nhân viên hệ thống',
                  route: '/admin/users/system',
                  isSelected: currentPath == '/admin/users/system',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_alt_rounded,
                  title: 'Tài khoản End User',
                  route: '/admin/users',
                  isSelected: currentPath == '/admin/users',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.wifi_tethering_rounded,
                  title: 'Mạng lưới Trạm CORS',
                  route: '/admin/stations',
                  isSelected: currentPath.startsWith('/admin/stations'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.verified_user_rounded,
                  title: 'Duyệt hồ sơ eKYC',
                  route: '/admin/ekyc',
                  isSelected: currentPath.startsWith('/admin/ekyc'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.sell_rounded,
                  title: 'Cấu hình Gói cước',
                  route: '/admin/ntrip/packages',
                  isSelected: currentPath.startsWith('/admin/ntrip/packages'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.cell_tower,
                  title: 'Tài khoản NTRIP',
                  route: '/admin/ntrip/accounts',
                  isSelected: currentPath.startsWith('/admin/ntrip/accounts'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bar_chart_rounded,
                  title: 'Báo cáo Doanh thu',
                  route: '/admin/revenue',
                  isSelected: currentPath.startsWith('/admin/revenue'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.headset_mic_rounded,
                  title: 'Hỗ trợ khách hàng',
                  route: '/admin/support',
                  isSelected: currentPath.startsWith('/admin/support'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.assignment_rounded,
                  title: 'Quản lý Phiếu (Tickets)',
                  route: '/admin/tickets',
                  isSelected: currentPath.startsWith('/admin/tickets'),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              hoverColor: AppTheme.errorColor.withOpacity(0.1),
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String route, 
    required bool isSelected
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? Colors.white70 : AppTheme.textSecondary;
    final unselectedTextColor = isDark ? Colors.white : AppTheme.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? AppTheme.primaryColor : unselectedColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : unselectedTextColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context); // Close the drawer
          if (!isSelected) {
            context.go(route);
          }
        },
      ),
    );
  }
}
