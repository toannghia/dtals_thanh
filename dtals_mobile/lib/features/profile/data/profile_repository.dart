import '../../../../core/network/api_client.dart';
import 'models/user_model.dart';

class ProfileRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> getProfile() async {
    final response = await _apiClient.dio.get('/auth/profile');
    return UserModel.fromJson(response.data);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _apiClient.dio.put('/auth/profile', data: data);
  }
}
