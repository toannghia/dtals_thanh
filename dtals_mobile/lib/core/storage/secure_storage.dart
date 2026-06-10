import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';
  static const String _usernameKey = 'saved_username';
  static const String _passwordKey = 'saved_password';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveUser(String userData) async {
    await _storage.write(key: _userKey, value: userData);
  }

  Future<String?> getUser() async {
    return await _storage.read(key: _userKey);
  }

  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<Map<String, String?>> getCredentials() async {
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    return {'username': username, 'password': password};
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
