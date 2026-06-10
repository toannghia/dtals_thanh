import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../../domain/models/notification_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationListProvider);
    final authState = ref.watch(authProvider);

    String fallbackPath() {
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(fallbackPath());
            }
          },
        ),
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: () => ref.read(notificationListProvider.notifier).markAllAsRead(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Không có thông báo nào',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationItem(
                  notification: notification,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Lỗi: $error')),
        ),
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationItem({super.key, required this.notification});

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.orderStatus:
        return Icons.shopping_bag;
      case NotificationType.ekycStatus:
        return Icons.verified_user;
      case NotificationType.supportReply:
        return Icons.support_agent;
      case NotificationType.ticketStatus:
        return Icons.confirmation_number;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.orderStatus:
        return Colors.blue;
      case NotificationType.ekycStatus:
        return Colors.green;
      case NotificationType.supportReply:
        return Colors.orange;
      case NotificationType.ticketStatus:
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getIconColor().withOpacity(0.1),
        child: Icon(_getIcon(), color: _getIconColor()),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm dd/MM/yyyy').format(notification.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      tileColor: notification.isRead ? null : AppTheme.primaryColor.withOpacity(0.05),
      onTap: () async {
        try {
          if (!notification.isRead) {
            await ref.read(notificationListProvider.notifier).markAsRead(notification.id);
          }
          
          if (!context.mounted) return;

          // Navigation based on notification type
          final data = notification.data;
          final String? linkedId = data?['ticketId']?.toString() ?? data?['id']?.toString();

          switch (notification.type) {
            case NotificationType.orderStatus:
              context.go('/user/orders');
              break;
            case NotificationType.supportReply:
            case NotificationType.ticketStatus:
              if (linkedId != null) {
                context.go('/user/support/$linkedId');
              } else {
                context.go('/user/support');
              }
              break;
            case NotificationType.ekycStatus:
              context.go('/user/profile');
              break;
            default:
              // For general notifications, we stay here or do nothing
              break;
          }
        } catch (e) {
          if (context.mounted) {
            AppToast.show(context, 'Không thể mở thông báo: $e', type: AppToastType.error);
          }
        }
      },
    );
  }
}
