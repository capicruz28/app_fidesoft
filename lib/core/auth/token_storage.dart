import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage._();

  static const _secure = FlutterSecureStorage();

  static String? _accessTokenMemory;

  static Future<String?> getAccessToken() async {
    if (_accessTokenMemory != null && _accessTokenMemory!.isNotEmpty) {
      return _accessTokenMemory;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null && token.isNotEmpty) {
      _accessTokenMemory = token;
    }
    return token;
  }

  static Future<void> setAccessToken(String token) async {
    _accessTokenMemory = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearAccessToken() async {
    _accessTokenMemory = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('token_type');
    await prefs.remove('user_roles');
    await prefs.remove('user_email');
  }

  static Future<String?> getRefreshToken() async {
    final token = await _secure.read(key: 'refresh_token');
    return token;
  }

  static Future<void> setRefreshToken(String token) async {
    await _secure.write(key: 'refresh_token', value: token);
  }

  static Future<void> clearRefreshToken() async {
    await _secure.delete(key: 'refresh_token');
  }

  static Future<void> clearAllTokens() async {
    await clearAccessToken();
    await clearRefreshToken();
  }
}

