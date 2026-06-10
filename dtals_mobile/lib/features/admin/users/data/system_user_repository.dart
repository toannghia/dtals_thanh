import '../../../../core/network/api_client.dart';
import './models/admin_user_models.dart';

class SystemUserRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<SystemUser>> listSystemUsers() async {
    final response = await _apiClient.dio.get('/users');
    // Backend returns {data: [...], meta: {...}} OR directly a List
    final responseData = response.data;
    List items;
    if (responseData is List) {
      items = responseData;
    } else if (responseData is Map) {
      items = responseData['data'] ?? responseData['items'] ?? [];
    } else {
      items = [];
    }
    return items.map((e) => SystemUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createSystemUser(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/users', data: data);
  }

  Future<void> updateSystemUser(String id, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/users/$id', data: data);
  }

  Future<void> deleteSystemUser(String id) async {
    await _apiClient.dio.delete('/users/$id');
  }
}
