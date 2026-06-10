import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../notifications/presentation/providers/notification_provider.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/theme/app_theme.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  final List<BottomNavigationBarItem> items;
  final void Function(int) onTap;
  final int currentIndex;
  final Widget? drawer;

  const AppShell({
    super.key,
    required this.child,
    required this.items,
    required this.onTap,
    required this.currentIndex,
    this.drawer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadAsync.value ?? 0;
    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      if (items.length == 5) {
        // Special 5-tab layout with prominent center FAB
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: _buildAppBar(context, unreadCount),
          drawer: drawer,
          body: child,
          floatingActionButton: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.navAccent.withOpacity(0.35),
                  blurRadius: 18,
                  spreadRadius: 3,
                )
              ],
            ),
            child: Transform.translate(
              offset: const Offset(0, -6),
              child: FloatingActionButton(
                onPressed: () => onTap(2), // Center item is index 2
                backgroundColor: AppTheme.navAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const CircleBorder(),
                child: items[2].icon,
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            color: Theme.of(context).colorScheme.surface,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            padding: EdgeInsets.zero,
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(items[0], 0, currentIndex == 0),
                _buildNavItem(items[1], 1, currentIndex == 1),
                const SizedBox(width: 56), // Empty space for FAB
                _buildNavItem(items[3], 3, currentIndex == 3),
                _buildNavItem(items[4], 4, currentIndex == 4),
              ],
            ),
          ),
        );
      }

      // Default Mobile NavigationBar (fall back for < 5 items)
      return Scaffold(
        appBar: _buildAppBar(context, unreadCount),
        drawer: drawer,
        body: child,
        // Modern Floating-style Bottom Navigation using NavigationBar
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 72,
            indicatorColor: AppTheme.navAccent.withOpacity(0.18),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppTheme.navAccent : AppTheme.textSecondary,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 26,
                color: isSelected ? AppTheme.navAccent : AppTheme.textSecondary,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 8,
            destinations: items.map((item) {
              return NavigationDestination(
                icon: item.icon,
                selectedIcon: item.activeIcon,
                label: item.label ?? '',
              );
            }).toList(),
          ),
        ),
      );
    }

    // Tablet & Desktop Layout with NavigationRail
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 1,
            destinations: items.map((item) {
              return NavigationRailDestination(
                icon: item.icon,
                selectedIcon: item.activeIcon,
                label: Text(item.label ?? ''),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Scaffold(
              appBar: _buildAppBar(context, unreadCount),
              drawer: drawer,
              body: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BottomNavigationBarItem item, int index, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        radius: 30, // Ripple effect constraint
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              (isSelected && item.activeIcon != null) ? (item.activeIcon as Icon).icon : (item.icon as Icon).icon,
              color: isSelected ? AppTheme.navAccent : AppTheme.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              item.label ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppTheme.navAccent : AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context, int unreadCount) {
    final location = GoRouterState.of(context).uri.path;
    
    // For End User screens, we let them handle their own AppBar to avoid double stacking
    if (location.startsWith('/user') || location.startsWith('/gov')) return null;

    String title = 'DTALS';
    if (location == '/admin/stations') {
      title = 'Bản đồ';
    } else if (location == '/gov/stations') {
      title = 'Bản đồ';
    }

    return AppBar(
      title: Text(title),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Thông báo',
                onPressed: () => context.go('/notifications'),
                // Touch target size
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

