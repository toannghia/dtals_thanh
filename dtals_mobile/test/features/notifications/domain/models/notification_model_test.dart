import 'package:flutter_test/flutter_test.dart';
import 'package:dtals_mobile/features/notifications/domain/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('should parse from json correctly', () {
      final json = {
        'id': 1,
        'user_id': 'uuid-123',
        'title': 'Test Title',
        'body': 'Test Body',
        'type': 'ORDER_STATUS',
        'is_read': false,
        'data': {'orderId': 101},
        'created_at': '2026-03-08T10:00:00Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 1);
      expect(model.userId, 'uuid-123');
      expect(model.type, NotificationType.orderStatus);
      expect(model.isRead, false);
      expect(model.data?['orderId'], 101);
    });

    test('should copyWith correctly', () {
      final model = NotificationModel(
        id: 1,
        userId: 'uuid-123',
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final updated = model.copyWith(isRead: true);
      expect(updated.isRead, true);
      expect(updated.id, 1);
    });
  });

  group('NotificationType Enum', () {
    test('should have all expected values', () {
      expect(NotificationType.values.length, 5);
      expect(NotificationType.orderStatus.name, 'orderStatus');
    });
  });
}
