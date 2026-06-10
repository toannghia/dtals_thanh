import '../../../../core/network/api_client.dart';

class AdminNtripAccountRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> listAccounts({
    int page = 1,
    int size = 10,
    String? search,
    String? status,
  }) async {
    final query = {
      'page': page,
      'size': size,
      if (search != null && search.isNotEmpty) 'keywords': search,
      if (status != null && status.isNotEmpty) 'enabled': status,
    };
    final response = await _apiClient.dio.get('/ntrip-users', queryParameters: query);
    return response.data is Map ? response.data : {'items': [], 'meta': {}};
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    await _apiClient.dio.patch('/ntrip-users/$id/toggle', data: {'enabled': enabled ? 1 : 0});
  }

  Future<void> createAccount(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/ntrip-users', data: data);
  }

  Future<void> updateAccount(String id, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/ntrip-users/$id', data: data);
  }

  Future<void> deleteAccount(String id) async {
    await _apiClient.dio.delete('/ntrip-users/$id');
  }
}
