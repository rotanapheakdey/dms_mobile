import '../models/document.dart';
import '../models/department.dart';
import 'api_client.dart';

class DocumentService {
  final ApiClient _api = ApiClient();

  // ===================== GETTERS =====================

  /// GET /documents/urgent — documents needing attention by current user's role
  Future<List<Document>> getUrgent() async {
    final response = await _api.get('/documents/urgent');
    if (response.containsKey('error')) return [];
    final List<dynamic> data = response['documents'] ?? response['data'] ?? [];
    return data.map((json) => Document.fromJson(json)).toList();
  }

  /// GET /departments/inbox — documents assigned to current user's department
  Future<List<Document>> getInbox() async {
    final response = await _api.get('/departments/inbox');
    if (response.containsKey('error')) return [];
    final List<dynamic> data = response['documents'] ?? response['data'] ?? [];
    return data.map((json) => Document.fromJson(json)).toList();
  }

  /// GET /documents — list all documents (for document list screen)
  Future<List<Document>> getAllDocuments() async {
    final response = await _api.get('/documents');
    if (response.containsKey('error')) return [];
    final List<dynamic> data = response['documents'] ?? response['data'] ?? [];
    return data.map((json) => Document.fromJson(json)).toList();
  }

  /// GET /documents — find a specific document by ID from the full list
  /// NOTE: The API does not expose GET /documents/{id}, so we fetch the list
  /// and filter. Falls back to urgent/inbox feeds if not found.
  Future<Document?> getDocument(int id) async {
    try {
      final response = await _api.get('/documents/$id');
      if (!response.containsKey('error')) {
        final json = response['document'] ?? response['data'] ?? response;
        return Document.fromJson(json);
      }
    } catch (_) {
      // Fall back if direct fetch fails
    }

    // Try the full document list first
    final all = await getAllDocuments();
    final found = all.where((d) => d.id == id).toList();
    if (found.isNotEmpty) return found.first;

    // Fallback: search urgent feed
    final urgent = await getUrgent();
    final urgentFound = urgent.where((d) => d.id == id).toList();
    if (urgentFound.isNotEmpty) return urgentFound.first;

    // Fallback: search inbox
    final inbox = await getInbox();
    final inboxFound = inbox.where((d) => d.id == id).toList();
    if (inboxFound.isNotEmpty) return inboxFound.first;

    // Fallback: search archive
    try {
      final archiveResult = await searchArchive('');
      final List<dynamic> archiveDocs = archiveResult['documents'] ?? [];
      final archiveFound = archiveDocs.where((d) => d.id == id).toList();
      if (archiveFound.isNotEmpty) return archiveFound.first;
    } catch (_) {
      // Ignore archive search errors
    }

    return null;
  }

  // ===================== WORKFLOW ACTIONS =====================

  // Phase 1: Upload → POST /documents
  Future<String?> uploadDocument({
    required String title,
    required String filePath,
    String? comment,
  }) async {
    final fields = <String, String>{'title': title};
    if (comment != null && comment.isNotEmpty) fields['comment'] = comment;
    final response = await _api.multipart('/documents', fields, 'file', filePath);
    return response.containsKey('error')
        ? (response['message'] ?? 'Upload failed')
        : null;
  }

  // Phase 2: DG Direct/Assign → POST /documents/{id}/direct
  Future<String?> assignDocument({
    required int id,
    required int departmentId,
    String? note,
    double? x,
    double? y,
    double? width,
    double? height,
    int? page,
  }) async {
    final body = <String, dynamic>{'assigned_department_id': departmentId};
    if (note != null && note.isNotEmpty) body['dg_note'] = note;
    if (x != null) {
      body['x'] = x;
      body['y'] = y;
      body['width'] = width;
      body['height'] = height;
      body['page'] = page;
    }
    final response = await _api.post('/documents/$id/direct', body: body);
    return response.containsKey('error')
        ? (response['message'] ?? 'Assignment failed')
        : null;
  }

  // Phase 3: Dispatch → POST /documents/{id}/dispatch
  Future<String?> dispatchDocument({
    required int id,
    String? comment,
    double? x,
    double? y,
    double? width,
    double? height,
    int? page,
  }) async {
    final body = <String, dynamic>{};
    if (comment != null && comment.isNotEmpty) {
      body['comment'] = comment;
      body['additional_comment'] = comment;
    }
    if (x != null) {
      body['x'] = x;
      body['y'] = y;
      body['width'] = width;
      body['height'] = height;
      body['page'] = page;
    }
    final response = await _api.post('/documents/$id/dispatch', body: body);
    return response.containsKey('error')
        ? (response['message'] ?? 'Dispatch failed')
        : null;
  }

  // Phase 4: Upload Report → POST /documents/{id}/report
  Future<String?> uploadReport({
    required int id,
    required String filePath,
  }) async {
    final response = await _api.multipart(
      '/documents/$id/report',
      {},
      'report_file',
      filePath,
    );
    return response.containsKey('error')
        ? (response['message'] ?? 'Report upload failed')
        : null;
  }

  // Phase 5: VDG Sign → POST /documents/{id}/vdg-sign
  // Phase 6: DG Final Sign → POST /documents/{id}/dg-sign
  Future<String?> signDocument({
    required int id,
    required bool isVdg,
    double? x,
    double? y,
    double? width,
    double? height,
    int? page,
  }) async {
    final endpoint = '/documents/$id/${isVdg ? 'vdg' : 'dg'}-sign';
    final body = <String, dynamic>{};
    if (x != null) {
      body['x'] = x;
      body['y'] = y;
      body['width'] = width;
      body['height'] = height;
      body['page'] = page;
    }
    final response = await _api.post(endpoint, body: body.isEmpty ? null : body);
    return response.containsKey('error')
        ? (response['message'] ?? 'Signature failed')
        : null;
  }

  // Phase 7: Archive → POST /documents/{id}/archive
  Future<String?> archiveDocument(int id) async {
    final response = await _api.post('/documents/$id/archive');
    return response.containsKey('error')
        ? (response['message'] ?? 'Archive failed')
        : null;
  }

  // Reject Report → POST /documents/{id}/reject
  Future<String?> rejectDocument({
    required int id,
    required String notes,
  }) async {
    final body = <String, dynamic>{'notes': notes};
    final response = await _api.post('/documents/$id/reject', body: body);
    return response.containsKey('error')
        ? (response['message'] ?? 'Rejection failed')
        : null;
  }

  // ===================== UTILS & SEARCH =====================

  /// GET /documents/archive?search=query
  /// Returns: { documents, access_level, result_count }
  Future<Map<String, dynamic>> searchArchive(String query) async {
    final endpoint = query.isNotEmpty
        ? '/documents/archive?search=${Uri.encodeComponent(query)}'
        : '/documents/archive';
    final response = await _api.get(endpoint);

    if (response.containsKey('error')) {
      return {'documents': <Document>[], 'access_level': '', 'result_count': 0};
    }

    final List<dynamic> data = response['documents'] ?? response['data'] ?? [];
    final documents = data.map((json) => Document.fromJson(json)).toList();

    return {
      'documents': documents,
      'access_level': response['access_level'] ?? '',
      'result_count': response['result_count'] ?? documents.length,
    };
  }

  /// GET /documents/{id}/download — returns raw bytes
  Future<Map<String, dynamic>> downloadFile(int id) async {
    return await _api.downloadFile('/documents/$id/download');
  }

  /// GET /documents/{id}/report/download — returns raw bytes for action report
  Future<Map<String, dynamic>> downloadReportFile(int id) async {
    return await _api.downloadFile('/documents/$id/report/download');
  }

  /// GET /documents/{id}/directive/download — returns raw bytes for directive verification slip
  Future<Map<String, dynamic>> downloadDirectiveFile(int id) async {
    return await _api.downloadFile('/documents/$id/directive/download');
  }

  /// GET /departments — list all departments for assignment dialog
  Future<List<Department>> getDepartments() async {
    final response = await _api.get('/departments');
    if (response.containsKey('error')) return [];
    final List<dynamic> data =
        response['departments'] ?? response['data'] ?? [];
    return data.map((json) => Department.fromJson(json)).toList();
  }
}