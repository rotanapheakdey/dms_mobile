import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  Future<void> loadUser() async {
    _user = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _authService.login(email, password);
    if (success) {
      _user = await _authService.getCurrentUser();
    } else {
      _errorMessage = 'Invalid email or password';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update own profile — PUT /users/{id}
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? password,
    String? avatarPath,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userService.updateProfile(
        id: _user!.id,
        name: name,
        email: email,
        password: password,
        avatarPath: avatarPath,
      );

      if (response.containsKey('error')) {
        _errorMessage = response['message'] ?? 'Update failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update local user from server response
      final updatedJson = response['user'];
      if (updatedJson != null) {
        _user = User.fromJson(updatedJson);
      } else {
        // Fallback: update fields locally
        _user = _user!.copyWith(
          name: name,
          email: email,
          avatarUrl: avatarPath,
        );
      }
      await _authService.saveUser(_user!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload new avatar — POST /users/{id}/avatar
  Future<bool> updateAvatar(String avatarPath) async {
    if (_user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userService.updateAvatar(
        id: _user!.id,
        avatarPath: avatarPath,
      );

      if (response.containsKey('error')) {
        _errorMessage = response['message'] ?? 'Avatar update failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Refresh user to get new avatar_url from server
      final refreshed = await _userService.getUser(_user!.id);
      if (refreshed != null) _user = refreshed;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove avatar — DELETE /users/{id}/avatar
  Future<bool> removeAvatar() async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _userService.removeAvatar(_user!.id);
      if (response.containsKey('error')) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _user = _user!.copyWith(clearAvatar: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload new signature — POST /users/{id}/signature
  Future<bool> updateSignature(Uint8List signatureBytes) async {
    if (_user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userService.updateSignature(
        id: _user!.id,
        signatureBytes: signatureBytes,
      );

      if (response.containsKey('error')) {
        _errorMessage = response['message'] ?? 'Signature update failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Refresh user to get new signature_url from server
      final refreshed = await _userService.getUser(_user!.id);
      if (refreshed != null) {
        _user = refreshed;
        await _authService.saveUser(_user!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove signature — DELETE /users/{id}/signature
  Future<bool> removeSignature() async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _userService.removeSignature(_user!.id);
      if (response.containsKey('error')) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _user = _user!.copyWith(clearSignature: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  bool hasPermission(String action) {
    if (_user == null) return false;

    final Map<String, List<String>> permissions = {
      'upload': ['file_dept'],
      'assign': ['dg'],
      'dispatch': ['file_dept'],
      'sign_vdg': ['vdg'],
      'sign_dg': ['dg'],
      'archive': ['file_dept'],
      'manage_users': ['dg'],
      'view_all': ['dg', 'file_dept'],
      'view_department': ['vdg', 'department', 'staff'],
    };

    return permissions[action]?.contains(_user!.role) ?? false;
  }

  // Convenience getters
  bool get canUpload => hasPermission('upload');
  bool get canAssign => hasPermission('assign');
  bool get canDispatch => hasPermission('dispatch');
  bool get canVDGSign => hasPermission('sign_vdg');
  bool get canDGSign => hasPermission('sign_dg');
  bool get canArchive => hasPermission('archive');
  bool get canManageUsers => hasPermission('manage_users');
}