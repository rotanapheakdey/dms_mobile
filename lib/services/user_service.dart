import '../models/user.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _api = ApiClient();

  /// GET /users/{id} — fetch single user
  Future<User?> getUser(int id) async {
    final response = await _api.get('/users/$id');
    if (response.containsKey('error')) return null;
    final json = response['user'];
    if (json == null) return null;
    return User.fromJson(json);
  }

  /// PUT /users/{id} — update own profile (name, email, password, avatar)
  /// Uses POST + _method=PUT for multipart compatibility with Laravel.
  Future<Map<String, dynamic>> updateProfile({
    required int id,
    String? name,
    String? email,
    String? password,
    String? avatarPath,
  }) async {
    final fields = <String, String>{};
    if (name != null && name.isNotEmpty) fields['name'] = name;
    if (email != null && email.isNotEmpty) fields['email'] = email;
    if (password != null && password.isNotEmpty) fields['password'] = password;

    Map<String, dynamic> response;

    if (avatarPath != null) {
      // Use multipart when uploading avatar
      response = await _api.multipartPut(
        '/users/$id',
        fields,
        fileKey: 'avatar',
        filePath: avatarPath,
      );
    } else if (fields.isEmpty) {
      return {'error': true, 'message': 'No changes to save'};
    } else {
      // Plain PUT for text-only updates
      response = await _api.put(
        '/users/$id',
        body: Map<String, dynamic>.from(fields),
      );
    }

    return response;
  }

  /// POST /users/{id}/avatar — update only the avatar
  Future<Map<String, dynamic>> updateAvatar({
    required int id,
    required String avatarPath,
  }) async {
    return await _api.multipart(
      '/users/$id/avatar',
      {},
      'avatar',
      avatarPath,
    );
  }

  /// DELETE /users/{id}/avatar — remove the avatar
  Future<Map<String, dynamic>> removeAvatar(int id) async {
    return await _api.delete('/users/$id/avatar');
  }
}
