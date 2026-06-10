import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../domain/models/notification_model.dart';

part 'notification_repository.g.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await _dio.get('/notifications', queryParameters: {
      'page': page,
      'limit': limit,
    });
    
    final List<dynamic> items = response.data['items'] ?? [];
    return items.map((json) => NotificationModel.fromJson(json)).toList();
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread');
      if (response.data is Map) {
        return response.data['count'] ?? 0;
      }
      return response.data as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    await _dio.patch('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.post('/notifications/read-all');
  }

  Future<void> registerDeviceToken(String fcmToken, String platform) async {
    await _dio.post('/notifications/register-token', data: {
      'fcmToken': fcmToken,
      'platform': platform,
    });
  }
}

@riverpod
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepository(ref.watch(dioClientProvider));
}
