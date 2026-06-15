import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? currentUser;
  String? token;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners(); 

    final result = await ApiService.call('POST', '/login', body: {
      'email': email,
      'password': password,
    });

    isLoading = false;

    if (result.containsKey('error') && result['error'] == true) {
      errorMessage = result['message'];
      notifyListeners();
      return false;
    }

    if (result.containsKey('access_token')) {
      token = result['access_token'];
      currentUser = result['user'];
      
      await AuthService.saveToken(token!);
      await AuthService.saveUser(currentUser!);
      
      notifyListeners();
      return true;
    }

    errorMessage = 'An unknown error occurred.';
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await AuthService.clearAuth();
    currentUser = null;
    token = null;
    notifyListeners();
  }
}