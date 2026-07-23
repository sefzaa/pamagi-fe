import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _statusKey = 'subscription_status'; // Kunci baru

  static Future<void> saveAuthData(String access, String refresh, String status) async {
    await _storage.write(key: _tokenKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
    await _storage.write(key: _statusKey, value: status);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<String?> getSubscriptionStatus() async {
    return await _storage.read(key: _statusKey);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _statusKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshKey);
  }


}