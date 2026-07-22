import 'dart:async';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

part 'api_client.g.dart';

@riverpod
Dio dioClient(Ref ref) {
  return ApiClient().dio;
}

class ApiClient {
  static final StreamController<void> unauthorizedStream = StreamController<void>.broadcast();

  late Dio dio;
  final SecureStorage _storage = SecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60), // Longer for file uploads
        sendTimeout: const Duration(seconds: 60),    // Longer for file uploads
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final path = e.requestOptions.path;
            // Do NOT logout for ekyc submit - the upload may have succeeded
            // even if the response has unexpected status
            final isEkycSubmit = path.contains('/ekyc/submit');
            if (!isEkycSubmit) {
              await _storage.deleteToken();
              unauthorizedStream.add(null);
            }
          }
          return handler.next(e);
        },
      ),
    );

    // Add logging interceptor in dev mode
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
}
