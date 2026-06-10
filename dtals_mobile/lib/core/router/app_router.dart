import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/shells/app_shell.dart';
import '../../features/end_user/dashboard/presentation/screens/end_user_dashboard.dart';
import '../../features/end_user/ekyc/presentation/screens/ekyc_submit_screen.dart';
import '../../features/end_user/ntrip_accounts/presentation/screens/my_ntrip_accounts.dart';
import '../../features/end_user/orders/presentation/screens/orders_screen.dart';
import '../../features/end_user/orders/presentation/screens/checkout_screen.dart';
import '../../features/end_user/orders/presentation/screens/payment_result_screen.dart';
import '../../features/end_user/map/presentation/screens/end_user_map_screen.dart';
import '../../features/end_user/support/presentation/screens/support_list_screen.dart';
import '../../features/end_user/support/presentation/screens/support_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/end_user/packages/presentation/screens/packages_screen.dart';
import '../../features/admin/stations/presentation/screens/station_list_screen.dart';
import '../../features/admin/stations/presentation/screens/admin_stations_map_screen.dart';
import '../../features/admin/finance/presentation/screens/finance_screen.dart';
import '../../features/admin/support/presentation/screens/admin_support_list_screen.dart';
import '../../features/admin/support/presentation/screens/admin_support_detail_screen.dart';
import '../../features/admin/tickets/presentation/screens/admin_tickets_screen.dart';
import '../../features/government/presentation/screens/gov_dashboard_screen.dart';
import '../../features/government/presentation/screens/gov_stations_screen.dart';
import '../../features/government/presentation/screens/gov_tickets_screen.dart';
import '../../features/notifications/presentation/screens/notification_screen.dart';
import '../../features/admin/dashboard/presentation/screens/admin_dashboard.dart';
import '../../features/admin/dashboard/presentation/widgets/admin_drawer.dart';
import '../../features/admin/users/presentation/screens/end_users_screen.dart';
import '../../features/admin/users/presentation/screens/system_users_screen.dart';
import '../../features/admin/ntrip/presentation/screens/ntrip_packages_screen.dart';
import '../../features/admin/ntrip/presentation/screens/admin_ntrip_accounts_screen.dart';
import '../../features/admin/ekyc/presentation/screens/ekyc_management_screen.dart';
import '../../features/admin/revenue_report/presentation/screens/revenue_report_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _adminShellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _userShellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _govShellNavigatorKey = GlobalKey<NavigatorState>();

final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final authRefreshNotifier = ValueNotifier<int>(0);
  ref.onDispose(authRefreshNotifier.dispose);
  ref.listen<AuthState>(authProvider, (_, __) {
    authRefreshNotifier.value++;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authRefreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';

      if (!isLoggedIn) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      if (isLoggingIn) {
        final role = authState.role?.toUpperCase();
        if (role == 'ADMIN' || 
            role == 'SUPER_ADMIN' || 
            role == 'SUPERADMIN' ||
            role == 'TECH' || 
            role == 'ACCOUNTANT') {
          return '/admin';
        }
        if (role == 'GOV' || role == 'AUTHORITY') return '/gov';
        return '/user';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const NotificationScreen(),
        ),
      ),
      ShellRoute(
        navigatorKey: _adminShellNavigatorKey,
        builder: (context, state, child) => AppShell(
          currentIndex: _getAdminIndex(state.uri.path),
          drawer: const AdminDrawer(),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Tổng quan'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Người dùng'),
            BottomNavigationBarItem(icon: Icon(Icons.wifi_tethering), label: 'Trạm CORS'),
            BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Hỗ trợ'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Phiếu'),
          ],
          onTap: (i) {
            final paths = ['/admin', '/admin/users', '/admin/stations', '/admin/support', '/admin/tickets'];
            if (i < paths.length) context.go(paths[i]);
          },
          child: child,
        ),
        routes: [
          GoRoute(path: '/admin', builder: (context, state) => const AdminDashboard()),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const EndUsersScreen(),
            routes: [
              GoRoute(path: 'system', builder: (context, state) => const SystemUsersScreen()),
            ],
          ),
          GoRoute(
            path: '/admin/stations',
            builder: (context, state) => const AdminStationsMapScreen(),
            routes: [
              GoRoute(path: 'list', builder: (context, state) => const StationListScreen()),
            ],
          ),
          GoRoute(path: '/admin/finance', builder: (context, state) => const FinanceScreen()),
          GoRoute(
            path: '/admin/ntrip',
            builder: (context, state) => const AdminNtripAccountsScreen(), // Default or redirect
            routes: [
              GoRoute(path: 'packages', builder: (context, state) => const NtripPackagesScreen()),
              GoRoute(path: 'accounts', builder: (context, state) => const AdminNtripAccountsScreen()),
            ],
          ),
          GoRoute(path: '/admin/ekyc', builder: (context, state) => const EkycManagementScreen()),
          GoRoute(path: '/admin/revenue', builder: (context, state) => const RevenueReportScreen()),
          GoRoute(path: '/admin/support', builder: (context, state) => const AdminSupportListScreen()),
          GoRoute(
            path: '/admin/support/:id',
            builder: (context, state) => AdminSupportDetailScreen(requestId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/admin/tickets', builder: (context, state) => const AdminTicketsScreen()),
        ],
      ),
      ShellRoute(
        navigatorKey: _userShellNavigatorKey,
        builder: (context, state, child) => AppShell(
          currentIndex: _getUserIndex(state.uri.path),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Tổng quan'),
            BottomNavigationBarItem(icon: Icon(Icons.cell_tower), label: 'Tài khoản NTRIP'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Bản đồ'),
            BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Hỗ trợ'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
          ],
          onTap: (i) {
            final paths = ['/user', '/user/ntrip-accounts', '/user/map', '/user/support', '/user/profile'];
            if (i < paths.length) context.go(paths[i]);
          },
          child: child,
        ),
        routes: [
          GoRoute(path: '/user', builder: (context, state) => const EndUserDashboard()),
          GoRoute(path: '/user/packages', builder: (context, state) => const PackagesScreen()),
          GoRoute(path: '/user/map', builder: (context, state) => const EndUserMapScreen()),
          GoRoute(path: '/user/ekyc', builder: (context, state) => const EkycSubmitScreen()),
          GoRoute(path: '/user/ntrip-accounts', builder: (context, state) => const MyNtripAccounts()),
          GoRoute(path: '/user/orders', builder: (context, state) => const OrdersScreen()),
          GoRoute(
            path: '/user/checkout',
            builder: (context, state) {
              final url = state.uri.queryParameters['url'] ?? '';
              if (url.isEmpty) {
                return const PaymentResultScreen(status: 'fail');
              }
              return CheckoutScreen(url: url);
            },
          ),
          GoRoute(
            path: '/user/payment-result',
            builder: (context, state) {
              final status = state.uri.queryParameters['status'] ?? 'fail';
              return PaymentResultScreen(status: status);
            },
          ),
          GoRoute(path: '/user/support', builder: (context, state) => const SupportListScreen()),
          GoRoute(
            path: '/user/support/:id',
            builder: (context, state) => SupportDetailScreen(ticketId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/user/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      ShellRoute(
        navigatorKey: _govShellNavigatorKey,
        builder: (context, state, child) => AppShell(
          currentIndex: _getGovIndex(state.uri.path),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Cơ quan'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Trạm CORS'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Yêu cầu'),
          ],
          onTap: (i) {
            final paths = ['/gov', '/gov/stations', '/gov/tickets'];
            if (i < paths.length) context.go(paths[i]);
          },
          child: child,
        ),
        routes: [
          GoRoute(path: '/gov', builder: (context, state) => const GovDashboardScreen()),
          GoRoute(path: '/gov/stations', builder: (context, state) => const GovStationsScreen()),
          GoRoute(path: '/gov/tickets', builder: (context, state) => const GovTicketsScreen()),
        ],
      ),
    ],
  );
});

int _getAdminIndex(String path) {
  if (path == '/admin') return 0;
  if (path.startsWith('/admin/users')) return 1;
  if (path.startsWith('/admin/stations')) return 2;
  if (path.startsWith('/admin/support')) return 3;
  if (path.startsWith('/admin/tickets')) return 4;
  return 0;
}

int _getGovIndex(String path) {
  if (path == '/gov') return 0;
  if (path.startsWith('/gov/stations')) return 1;
  if (path.startsWith('/gov/tickets')) return 2;
  return 0;
}

int _getUserIndex(String path) {
  if (path == '/user') return 0;
  if (path.startsWith('/user/ntrip-accounts') || path.startsWith('/user/packages')) return 1;
  if (path.startsWith('/user/map')) return 2;
  if (path.startsWith('/user/support')) return 3;
  if (path.startsWith('/user/profile')) return 4;
  return 0;
}
