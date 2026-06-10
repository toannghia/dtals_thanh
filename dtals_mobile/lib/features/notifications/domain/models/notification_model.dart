import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

enum NotificationType {
  @JsonValue('GENERAL')
  general,
  @JsonValue('ORDER_STATUS')
  orderStatus,
  @JsonValue('EKYC_STATUS')
  ekycStatus,
  @JsonValue('SUPPORT_REPLY')
  supportReply,
  @JsonValue('TICKET_STATUS')
  ticketStatus,
}

@freezed
abstract class NotificationModel with _$NotificationModel {
  const NotificationModel._();

  const factory NotificationModel({
    required int id,
    required String userId,
    required String title,
    required String body,
    @Default(NotificationType.general) NotificationType type,
    required bool isRead,
    Map<String, dynamic>? data,
    required DateTime createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: _parseType(json['type']?.toString()),
      isRead: json['isRead'] == true || json['is_read'] == true || json['isRead'] == 1 || json['is_read'] == 1,
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  static NotificationType _parseType(String? type) {
    if (type == null) return NotificationType.general;
    final upperType = type.toUpperCase();
    switch (upperType) {
      case 'ORDER_STATUS': return NotificationType.orderStatus;
      case 'EKYC_STATUS': return NotificationType.ekycStatus;
      case 'SUPPORT_REPLY': return NotificationType.supportReply;
      case 'TICKET_STATUS': return NotificationType.ticketStatus;
      default: return NotificationType.general;
    }
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    return DateTime.tryParse(date.toString()) ?? DateTime.now();
  }
}
