import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../utils/navigation_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final storage = const FlutterSecureStorage();
  final String baseUrl = AppConfig.apiBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.read(key: AppConfig.tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> multipart(
    String endpoint,
    Map<String, String> fields,
    String fileKey,
    String filePath,
  ) async {
    final token = await storage.read(key: AppConfig.tokenKey);
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileKey, filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> multipartFromBytes(
    String endpoint,
    Map<String, String> fields,
    String fileKey,
    Uint8List fileBytes,
    String filename,
  ) async {
    final token = await storage.read(key: AppConfig.tokenKey);
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);
    request.files.add(http.MultipartFile.fromBytes(
      fileKey,
      fileBytes,
      filename: filename,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  /// Multipart PUT — for updating profile with optional avatar file.
  /// Laravel requires a workaround: use POST with _method=PUT field.
  Future<Map<String, dynamic>> multipartPut(
    String endpoint,
    Map<String, String> fields, {
    String? fileKey,
    String? filePath,
  }) async {
    final token = await storage.read(key: AppConfig.tokenKey);
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Laravel method spoofing for PUT
    request.fields['_method'] = 'PUT';
    request.fields.addAll(fields);

    if (fileKey != null && filePath != null) {
      request.files.add(await http.MultipartFile.fromPath(fileKey, filePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> downloadFile(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return {'success': true, 'data': response.bodyBytes};
    }

    String errorMessage = 'Download failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('message')) {
        errorMessage = decoded['message'];
      }
    } catch (_) {}

    return {'error': true, 'message': errorMessage, 'statusCode': response.statusCode};
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      _handleUnauthorized();
    }

    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else if (decoded is List) {
          return {'data': decoded};
        }
        return {'data': decoded};
      }
      return {
        'error': true,
        'message': decoded is Map ? (decoded['message'] ?? 'Request failed') : 'Request failed',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'error': true,
        'message': 'Failed to parse response: $e',
        'statusCode': response.statusCode,
      };
    }
  }

  void _handleUnauthorized() {
    storage.delete(key: AppConfig.tokenKey);
    storage.delete(key: AppConfig.userKey);
    NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (_) => false,
    );
  }
}