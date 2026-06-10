import '../../../../../core/network/api_client.dart';
import 'models/admin_user_models.dart';

class AdminEndUserRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> listUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final response = await _apiClient.dio.get('/admin/end-users', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
      if (status != null) 'status': status,
    });
    
    final responseData = response.data;
    final List items = responseData['data'] ?? responseData['items'] ?? [];
    final int total = responseData['meta']?['total'] ?? responseData['total'] ?? 0;
    
    return {
      'items': items.map((e) => AdminEndUser.fromJson(e)).toList(),
      'total': total,
    };
  }

  Future<void> updateStatus(String id, String status) async {
    await _apiClient.dio.put('/admin/end-users/$id/status', data: {'status': status});
  }

  Future<void> activateUser(String id) async {
    await _apiClient.dio.put('/admin/end-users/$id/activate');
  }

  Future<AdminEndUser> getDetail(String id) async {
    final response = await _apiClient.dio.get('/admin/end-users/$id');
    return AdminEndUser.fromJson(response.data);
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/auth/register', data: data);
  }

  Future<void> deleteUser(String id) async {
    await _apiClient.dio.delete('/admin/end-users/$id');
  }
}
