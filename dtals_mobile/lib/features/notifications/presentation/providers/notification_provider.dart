import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification_model.dart';
import '../../data/notification_repository.dart';

part 'notification_provider.g.dart';

@riverpod
class NotificationList extends _$NotificationList {
  @override
  FutureOr<List<NotificationModel>> build() {
    return ref.watch(notificationRepositoryProvider).getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        ref.read(notificationRepositoryProvider).getNotifications());
  }

  Future<void> markAsRead(int notificationId) async {
    await ref.read(notificationRepositoryProvider).markAsRead(notificationId);
    
    // Optimistic update
    final currentData = state.value;
    if (currentData != null) {
      state = AsyncValue.data(
        currentData.map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n).toList(),
      );
    }
    
    // Refresh unread count
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationRepositoryProvider).markAllAsRead();
    
    final currentData = state.value;
    if (currentData != null) {
      state = AsyncValue.data(
        currentData.map((n) => n.copyWith(isRead: true)).toList(),
      );
    }
    
    ref.invalidate(unreadNotificationCountProvider);
  }
}

@riverpod
Future<int> unreadNotificationCount(Ref ref) {
  return ref.watch(notificationRepositoryProvider).getUnreadCount();
}
