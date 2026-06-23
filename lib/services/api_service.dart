import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/app_config.dart';
import '../utils/navigation_service.dart';
import '../screens/auth/login_screen.dart';
import 'auth_service.dart';

class ApiService {
  static final AuthService _authService = AuthService();

  // --- Private Connectivity Check ---
  static Future<bool> _hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // --- Core API Wrapper ---
  static Future<Map<String, dynamic>> call(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final String url = '${AppConfig.apiBaseUrl}$endpoint';
    final String? token = await _authService.getToken();

    if (!await _hasConnection()) {
      return {'error': true, 'message': 'No internet connection.'};
    }

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(Uri.parse(url), headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'PUT':
          response = await http.put(Uri.parse(url), headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers);
          break;
        default:
          response = await http.get(Uri.parse(url), headers: headers);
      }

      // --- Enhanced Status Handling ---
      if (response.statusCode == 401) {
        await _triggerGlobalLogout();
        return {'error': true, 'message': 'Session expired.', 'status': 401};
      }
      if (response.statusCode == 413) return {'error': true, 'message': 'File exceeds 10MB limit.', 'status': 413};
      if (response.statusCode == 422) return {'error': true, 'message': 'Invalid input data.', 'status': 422};

      dynamic decoded;
      try { decoded = jsonDecode(response.body); } catch (_) { decoded = {}; }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (decoded is List) ? {'data': decoded} : (decoded as Map<String, dynamic>);
      }

      return {'error': true, 'message': decoded['message'] ?? 'Error ${response.statusCode}', 'status': response.statusCode};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // --- Workflow Endpoints ---
  static Future<Map<String, dynamic>> assignToDepartment(int id, int deptId, String? note) =>
      call('POST', '/documents/$id/direct', body: {'assigned_department_id': deptId, 'dg_note': note});

  static Future<Map<String, dynamic>> dispatchDocument(int id, String? note) =>
      call('POST', '/documents/$id/dispatch', body: {'comment': note});

  static Future<Map<String, dynamic>> signDocument(int id, bool isVdg) =>
      call('POST', '/documents/$id/${isVdg ? 'vdg' : 'dg'}-sign');

  static Future<Map<String, dynamic>> archiveDocument(int id) =>
      call('POST', '/documents/$id/archive');

  // --- Multipart Methods ---
  static Future<Map<String, dynamic>> uploadDocument({required String title, required File file, String? comment}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${AppConfig.apiBaseUrl}/documents'));
    final token = await _authService.getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    if (comment != null) request.fields['comment'] = comment;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    
    final response = await http.Response.fromStream(await request.send());
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> uploadReport(int documentId, File file) async {
    final request = http.MultipartRequest('POST', Uri.parse('${AppConfig.apiBaseUrl}/documents/$documentId/report'));
    final token = await _authService.getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('report_file', file.path));
    
    final response = await http.Response.fromStream(await request.send());
    return jsonDecode(response.body);
  }

  // --- File Handling ---
  static Future<Map<String, dynamic>> downloadAndOpenFile(int id, String title) async {
    final url = '${AppConfig.apiBaseUrl}/documents/$id/download';
    final token = await _authService.getToken();
    final response = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf');
      await file.writeAsBytes(response.bodyBytes);
      await OpenFile.open(file.path);
      return {'error': false};
    }
    return {'error': true, 'message': 'Download failed'};
  }

  static Future<void> _triggerGlobalLogout() async {
    await _authService.clearAuth();
    NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}