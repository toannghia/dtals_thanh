// lib/features/end_user/support/data/models/support_ticket.dart

class SupportTicket {
  final String id;
  final String title;
  final String status; // OPEN, IN_PROGRESS, CLOSED
  final DateTime createdAt;
  /// Nội dung chi tiết người dùng gửi khi tạo yêu cầu.
  final String? content;
  /// Tin nhắn mới nhất (thường là phản hồi từ hỗ trợ).
  final String? lastMessage;

  SupportTicket({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.content,
    this.lastMessage,
  });

  /// Nội dung hiển thị trên thẻ danh sách — ưu tiên mô tả yêu cầu của người dùng.
  String get requestPreview {
    final detail = content?.trim();
    if (detail != null && detail.isNotEmpty) return detail;
    final latest = lastMessage?.trim();
    if (latest != null && latest.isNotEmpty) return latest;
    return '';
  }

  SupportTicket copyWith({
    String? content,
    String? lastMessage,
  }) {
    return SupportTicket(
      id: id,
      title: title,
      status: status,
      createdAt: createdAt,
      content: content ?? this.content,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  static String? _firstNonEmpty(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static String? _contentFromMessagesList(dynamic raw) {
    if (raw is! List || raw.isEmpty) return null;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final text = _firstNonEmpty(map, ['content', 'message', 'text', 'body']);
      if (text != null) return text;
    }
    return null;
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    String rawStatus = (json['status'] ?? 'OPEN').toString();
    if (rawStatus == 'PENDING') rawStatus = 'OPEN';
    if (rawStatus == 'RESOLVED') rawStatus = 'CLOSED';

    final title = (json['title'] ?? json['subject'] ?? '').toString();
    final content = _firstNonEmpty(json, [
          'message',
          'content',
          'description',
          'body',
          'detail',
          'initialMessage',
          'requestMessage',
        ]) ??
        _contentFromMessagesList(json['messages']);

    final lastMessage = _firstNonEmpty(json, [
      'lastMessage',
      'latestMessage',
      'last_message',
      'lastMessageContent',
    ]);

    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    final createdAt = createdAtRaw != null
        ? DateTime.parse(createdAtRaw.toString()).toLocal()
        : DateTime.now();

    return SupportTicket(
      id: json['id'].toString(),
      title: title,
      status: rawStatus,
      createdAt: createdAt,
      content: content,
      lastMessage: lastMessage,
    );
  }
}

class SupportMessage {
  final String id;
  final String? senderId;
  final String content;
  final String senderType; // USER, STAFF, ADMIN, etc.
  final DateTime createdAt;
  final String? attachmentUrl;
  final bool? _isFromUserFlag;

  SupportMessage({
    required this.id,
    this.senderId,
    required this.content,
    required this.senderType,
    required this.createdAt,
    this.attachmentUrl,
    bool? isFromUserFlag,
  }) : _isFromUserFlag = isFromUserFlag;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    // Determine sender type from explicit flags or role object/string.
    String roleName = 'UNKNOWN';

    final rawSenderType = json['senderType'] ?? json['senderRole'] ?? json['role'];
    if (rawSenderType != null) {
      roleName = rawSenderType.toString();
    }

    final sender = json['sender'];
    if (sender != null && sender['role'] != null) {
      if (sender['role'] is Map) {
        roleName = sender['role']['name']?.toString() ?? roleName;
      } else {
        roleName = sender['role'].toString();
      }
    }

    final rawIsFromUser = json['isFromUser'] ?? json['fromUser'] ?? json['isUser'] ?? json['isCustomer'];
    bool? isFromUserFlag;
    if (rawIsFromUser is bool) {
      isFromUserFlag = rawIsFromUser;
    } else if (rawIsFromUser is num) {
      isFromUserFlag = rawIsFromUser != 0;
    } else if (rawIsFromUser is String) {
      final normalized = rawIsFromUser.toLowerCase();
      isFromUserFlag = normalized == 'true' || normalized == '1';
    }

    return SupportMessage(
      id: json['id'].toString(),
      senderId: json['senderId']?.toString(),
      content: (json['content'] ?? json['message'] ?? json['text'] ?? '').toString(),
      senderType: roleName,
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      attachmentUrl: (json['attachmentUrl'] ?? json['attachment'] ?? json['fileUrl'])?.toString(),
      isFromUserFlag: isFromUserFlag,
    );
  }

  bool get isFromUser => _isFromUserFlag ??
      senderType == 'USER' ||
      senderType == 'END_USER' ||
      senderType == 'CUSTOMER';
}
