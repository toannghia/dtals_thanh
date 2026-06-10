import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/auth_repository.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? role;
  final String? token;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.role,
    this.token,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.loading);
}

class AuthNotifier extends Notifier<AuthState> {
  final SecureStorage _storage = SecureStorage();
  final AuthRepository _repository = AuthRepository();

  @override
  AuthState build() {
    checkAuth();
    return AuthState.initial();
  }

  Future<void> checkAuth() async {
    final token = await _storage.getToken();
    if (token != null) {
      try {
        final profile = await _repository.getProfile();
        final role = profile['role']?.toString() ?? 'END_USER';
        state = AuthState(
          status: AuthStatus.authenticated,
          token: token,
          role: role,
        );
      } catch (e) {
        // Token invalid or expired
        await _storage.deleteToken();
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String username, String password, {bool rememberMe = false}) async {
    if (username.isEmpty || password.isEmpty) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu',
      );
      return;
    }

    state = AuthState(status: AuthStatus.loading);
    try {
      final response = await _repository.login(username, password);

      final token = response['access_token'] as String?;
      final user = response['user'] as Map<String, dynamic>?;
      final role = user?['role']?.toString() ?? 'END_USER';

      if (token == null || token.isEmpty) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Phản hồi từ máy chủ không hợp lệ',
        );
        return;
      }

      await _storage.saveToken(token);
      if (rememberMe) {
        await _storage.saveCredentials(username, password);
      } else {
        await _storage.clearCredentials();
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        role: role,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message;
      if (statusCode == 401) {
        message = 'Sai tài khoản hoặc mật khẩu';
      } else if (statusCode == 403) {
        message = 'Tài khoản đã bị khóa';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Không thể kết nối đến máy chủ. Vui lòng thử lại';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Lỗi kết nối mạng. Vui lòng kiểm tra Internet';
      } else {
        message = e.response?.data?['message']?.toString() ?? 'Đăng nhập thất bại';
      }
      if (kDebugMode) {
        debugPrint('Login error: $e');
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected login error: $e');
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Đã xảy ra lỗi không mong muốn',
      );
    }
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
