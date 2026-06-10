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
  late Dio dio;
  final SecureStorage _storage = SecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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
            // Handle unauthorized (session expired)
            await _storage.deleteToken();
            // Trigger logout or navigation to login if needed via event bus or provider
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
