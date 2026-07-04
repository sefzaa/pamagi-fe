import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _tokenKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
  }
}