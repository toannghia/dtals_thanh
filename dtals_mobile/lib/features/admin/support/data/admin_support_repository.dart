import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../end_user/support/data/models/support_ticket.dart';

class AdminSupportRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<SupportTicket>> getAllRequests({int page = 1, int limit = 10, String? status}) async {
    final response = await _apiClient.dio.get('/admin/support', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    });
    final List data = response.data['items'] ?? response.data ?? [];
    return data.map((item) => SupportTicket.fromJson(item)).toList();
  }

  Future<List<SupportMessage>> getRequestMessages(String id) async {
    final response = await _apiClient.dio.get('/admin/support/$id/messages');
    final List data = response.data['messages'] ?? [];
    return data.map((item) => SupportMessage.fromJson(item)).toList();
  }

  Future<void> sendAdminMessage(String id, String content, {String? attachmentPath, List<int>? attachmentBytes, String? attachmentName}) async {
    final formData = FormData.fromMap({
      'content': content,
      if (attachmentPath != null)
        'attachment': await MultipartFile.fromFile(attachmentPath, filename: attachmentName ?? 'reply.jpg'),
      if (attachmentBytes != null)
        'attachment': MultipartFile.fromBytes(attachmentBytes, filename: attachmentName ?? 'reply.jpg'),
    });

    await _apiClient.dio.post(
      '/admin/support/$id/messages',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<void> updateStatus(String id, String status) async {
    await _apiClient.dio.patch('/admin/support/$id/status', data: {'status': status});
  }
}
