// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    _NotificationModel(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type:
          $enumDecodeNullable(_$NotificationTypeEnumMap, json['type']) ??
          NotificationType.general,
      isRead: json['is_read'] as bool,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$NotificationModelToJson(_NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'body': instance.body,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'is_read': instance.isRead,
      'data': instance.data,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$NotificationTypeEnumMap = {
  NotificationType.general: 'GENERAL',
  NotificationType.orderStatus: 'ORDER_STATUS',
  NotificationType.ekycStatus: 'EKYC_STATUS',
  NotificationType.supportReply: 'SUPPORT_REPLY',
  NotificationType.ticketStatus: 'TICKET_STATUS',
};
