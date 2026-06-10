import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';

class EkycRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> submitKyc({
    required String frontPath,
    String? backPath,
    required String selfiePath,
    String documentType = 'CCCD',
  }) async {
    final formData = FormData.fromMap({
      'documentType': documentType,
      'front': await MultipartFile.fromFile(frontPath, filename: 'front.jpg'),
      if (backPath != null)
        'back': await MultipartFile.fromFile(backPath, filename: 'back.jpg'),
      'selfie': await MultipartFile.fromFile(selfiePath, filename: 'selfie.jpg'),
    });

    final response = await _apiClient.dio.post(
      '/ekyc/submit',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getStatus() async {
    final response = await _apiClient.dio.get('/ekyc/status');
    return response.data;
  }
}
