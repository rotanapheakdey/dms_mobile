import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    await _storage.write(key: AppConstants.userKey, value: jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    String? userData = await _storage.read(key: AppConstants.userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }
}