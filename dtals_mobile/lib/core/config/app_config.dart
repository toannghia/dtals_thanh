// lib/core/config/app_config.dart
class AppConfig {
  // static const String baseUrl = 'http://localhost:3000'; // Change to 10.0.2.2 for Android emulator
  static const String baseUrl = 'https://dtals.api.zps.vn';
  static const String apiVersion = 'v1';
  static const String mapboxToken = '';
}

// lib/core/config/env.dart
enum Environment { dev, staging, prod }
