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
  }) async {
    final body = <String, dynamic>{'assigned_department_id': departmentId};
    if (note != null && note.isNotEmpty) body['dg_note'] = note;
    final response = await _api.post('/documents/$id/direct', body: body);
    return response.containsKey('error')
        ? (response['message'] ?? 'Assignment failed')
        : null;
  }

  // Phase 3: Dispatch → POST /documents/{id}/dispatch
  Future<String?> dispatchDocument({
    required int id,
    String? comment,
  }) async {
    final body = <String, dynamic>{};
    if (comment != null && comment.isNotEmpty) body['comment'] = comment;
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
  Future<String?> signDocument(int id, bool isVdg) async {
    final endpoint = '/documents/$id/${isVdg ? 'vdg' : 'dg'}-sign';
    final response = await _api.post(endpoint);
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

  // ===================== UTILS & SEARCH =====================

  /// GET /documents/archive?search=query
  Future<List<Document>> searchArchive(String query) async {
    final endpoint = query.isNotEmpty
        ? '/documents/archive?search=${Uri.encodeComponent(query)}'
        : '/documents/archive';
    final response = await _api.get(endpoint);
    if (response.containsKey('error')) return [];
    final List<dynamic> data = response['documents'] ?? response['data'] ?? [];
    return data.map((json) => Document.fromJson(json)).toList();
  }

  /// GET /documents/{id}/download — returns raw bytes
  Future<Map<String, dynamic>> downloadFile(int id) async {
    return await _api.downloadFile('/documents/$id/download');
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