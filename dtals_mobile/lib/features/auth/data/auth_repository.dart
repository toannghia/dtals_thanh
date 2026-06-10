import '../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _apiClient.dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/auth/register', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.dio.get('/auth/profile');
    return response.data;
  }
}


