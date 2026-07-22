import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_client.dart';

// Conditional import: uses dart:io on mobile, XFile bytes on web
import 'ekyc_repository_io.dart' if (dart.library.html) 'ekyc_repository_web.dart';

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
      'front': await buildMultipartFile(frontPath, 'front.jpg'),
      if (backPath != null)
        'back': await buildMultipartFile(backPath, 'back.jpg'),
      'selfie': await buildMultipartFile(selfiePath, 'selfie.jpg'),
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
