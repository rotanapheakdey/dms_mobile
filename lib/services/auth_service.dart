import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.post('/login', body: {
        'email': email,
        'password': password,
      });

      if (response.containsKey('error')) {
        return false;
      }

      if (response.containsKey('access_token')) {
        await _storage.write(
          key: AppConfig.tokenKey,
          value: response['access_token'],
        );
        await _storage.write(
          key: AppConfig.userKey,
          value: jsonEncode(response['user']),
        );
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (e) {
      // Ignore error on logout
    } finally {
      await _storage.delete(key: AppConfig.tokenKey);
      await _storage.delete(key: AppConfig.userKey);
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final userJson = await _storage.read(key: AppConfig.userKey);
      if (userJson != null) {
        final data = jsonDecode(userJson);
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.tokenKey);
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.userKey);
  }
}