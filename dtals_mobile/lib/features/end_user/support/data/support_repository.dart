import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import 'models/support_ticket.dart';

class SupportRepository {
  final ApiClient _apiClient = ApiClient();
  static final Map<String, String> _requestPreviewCache = {};

  Future<List<SupportTicket>> getMyTickets() async {
    final response = await _apiClient.dio.get('/support');
    final List data = response.data['items'] ?? response.data ?? [];
    final tickets = data
        .map((item) => SupportTicket.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return Future.wait(tickets.map(_ensureRequestPreview));
  }

  Future<SupportTicket> _ensureRequestPreview(SupportTicket ticket) async {
    if (ticket.requestPreview.isNotEmpty) return ticket;

    final cached = _requestPreviewCache[ticket.id];
    if (cached != null && cached.isNotEmpty) {
      return ticket.copyWith(content: cached);
    }

    try {
      final messages = await getMessages(ticket.id);
      final preview = _extractRequestPreview(messages);
      if (preview != null && preview.isNotEmpty) {
        _requestPreviewCache[ticket.id] = preview;
        return ticket.copyWith(content: preview);
      }
    } catch (_) {
      // Giữ ticket gốc nếu không tải được tin nhắn.
    }
    return ticket;
  }

  String? _extractRequestPreview(List<SupportMessage> messages) {
    if (messages.isEmpty) return null;

    for (final message in messages) {
      if (!message.isFromUser) continue;
      final text = message.content.trim();
      if (text.isNotEmpty) return text;
    }

    for (final message in messages) {
      final text = message.content.trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  Future<List<SupportMessage>> getMessages(String ticketId) async {
    final response = await _apiClient.dio.get('/support/$ticketId/messages');
    final List data = response.data['messages'] ?? response.data['items'] ?? response.data ?? [];
    return data.map((item) => SupportMessage.fromJson(item)).toList();
  }

  Future<void> sendMessage(String ticketId, String content, {String? attachmentPath, List<int>? attachmentBytes, String? attachmentName}) async {
    final formData = FormData.fromMap({
      'content': content,
      if (attachmentPath != null)
        'attachment': await MultipartFile.fromFile(attachmentPath, filename: attachmentName ?? 'support_at.jpg'),
      if (attachmentBytes != null)
        'attachment': MultipartFile.fromBytes(attachmentBytes, filename: attachmentName ?? 'support_at.jpg'),
    });

    await _apiClient.dio.post(
      '/support/$ticketId/messages',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<void> createTicket(String title, String content, {String? attachmentPath, List<int>? attachmentBytes, String? attachmentName}) async {
    final formData = FormData.fromMap({
      'subject': title,
      'message': content,
      if (attachmentPath != null)
        'attachment': await MultipartFile.fromFile(attachmentPath, filename: attachmentName ?? 'support_req.jpg'),
      if (attachmentBytes != null)
        'attachment': MultipartFile.fromBytes(attachmentBytes, filename: attachmentName ?? 'support_req.jpg'),
    });

    await _apiClient.dio.post(
      '/support',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
