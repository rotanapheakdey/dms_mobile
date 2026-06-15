import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';
import '../utils/navigation_service.dart';
import '../screens/login_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiService {
  static Future<Map<String, dynamic>> call(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final String url = '${AppConstants.apiBaseUrl}$endpoint';
    final String? token = await AuthService.getToken();

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return {
          'error': true,
          'message':
              'No internet connection. Please check your Wi-Fi or Mobile Data.',
        };
      }
      http.Response response;

      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        default:
          response = await http.get(Uri.parse(url), headers: headers);
      }

      if (response.statusCode == 401) {
        await _triggerGlobalLogout();
        return {
          'error': true,
          'message': 'Session expired. Please log in again.',
          'status': 401,
        };
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (jsonError) {
        print("RAW SERVER CRASH DUMP: ${response.body}");
        return {
          'error': true,
          'message':
              'Internal Server Error (${response.statusCode}). Check backend logs.',
          'status': response.statusCode,
        };
      }

      if (decoded is Map &&
          decoded.containsKey('message') &&
          decoded['message'].toString().toLowerCase().contains(
            'unauthenticated',
          )) {
        await _triggerGlobalLogout();
        return {
          'error': true,
          'message': 'Session expired. Please log in again.',
          'status': 401,
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is List) {
          return {'data': decoded};
        }
        return decoded;
      }

      return {
        'error': true,
        'message': decoded['message'] ?? 'Status Code: ${response.statusCode}',
        'status': response.statusCode,
      };
    } catch (e) {
      return {'error': true, 'message': 'Network connection error: $e'};
    }
  }

  static Future<void> _triggerGlobalLogout() async {
    print(
      "DEBUG: Token invalidation intercepted. Redirecting to LoginScreen...",
    );
    await AuthService.clearAuth();

    NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  static Future<Map<String, dynamic>> uploadDocument({
    required String title,
    required File file,
    String? comment,
  }) async {
    final String url = '${AppConstants.apiBaseUrl}/documents';
    final String? token = await AuthService.getToken();

    try {
      // Guard Check
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return {'error': true, 'message': 'No internet connection available.'};
      }

      var request = http.MultipartRequest('POST', Uri.parse(url));

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['title'] = title;
      if (comment != null && comment.isNotEmpty) {
        request.fields['comment'] = comment;
      }

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'error': true,
          'message':
              errorData['message'] ??
              'Upload failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Upload error: $e'};
    }
  }

  static Future<Map<String, dynamic>> downloadAndOpenFile(
    int id,
    String title, {
    bool isDirective = false,
  }) async {
    String url = '${AppConstants.apiBaseUrl}/documents/$id/download';
    if (isDirective) {
      url += '?directive=true';
    }
    final String? token = await AuthService.getToken();

    try {
      // Guard Check
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return {'error': true, 'message': 'No internet connection available.'};
      }

      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        String extension = '.pdf';
        if (response.headers.containsKey('content-type')) {
          final contentType = response.headers['content-type']!;
          if (contentType.contains('wordprocessingml')) extension = '.docx';
          if (contentType.contains('msword')) extension = '.doc';
        }

        Directory tempDir = await getTemporaryDirectory();
        String safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
        String savePath = '${tempDir.path}/$safeTitle$extension';

        File file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);

        final result = await OpenFile.open(savePath);

        if (result.type != ResultType.done) {
          return {
            'error': true,
            'message': 'Could not open file. No viewer installed.',
          };
        }
        return {'error': false, 'message': 'Success'};
      } else {
        return {
          'error': true,
          'message': 'Failed to download file. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Download error: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadReport(
    int documentId,
    File file,
  ) async {
    final String url =
        '${AppConstants.apiBaseUrl}/documents/$documentId/report';
    final String? token = await AuthService.getToken();

    try {
      // Guard Check
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return {'error': true, 'message': 'No internet connection available.'};
      }

      var request = http.MultipartRequest('POST', Uri.parse(url));

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('report_file', file.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'error': true,
          'message':
              errorData['message'] ??
              'Upload failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Upload error: $e'};
    }
  }
}
