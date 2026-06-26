import 'package:flutter/material.dart';
import '../models/document.dart';
import '../models/department.dart';
import '../services/document_service.dart';

class DocumentProvider extends ChangeNotifier {
  final DocumentService _service = DocumentService();

  List<Document> _documents = [];
  List<Document> _urgentDocuments = [];
  List<Document> _inboxDocuments = [];
  List<Document> _archiveDocuments = [];
  String _archiveAccessLevel = '';
  List<Department> _departments = [];
  Document? _currentDocument;

  bool _isLoading = false;
  String? _errorMessage;

  // ===================== GETTERS =====================
  List<Document> get documents => _documents;
  List<Document> get urgentDocuments => _urgentDocuments;
  List<Document> get inboxDocuments => _inboxDocuments;
  List<Document> get archiveDocuments => _archiveDocuments;
  String get archiveAccessLevel => _archiveAccessLevel;
  List<Department> get departments => _departments;
  Document? get currentDocument => _currentDocument;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get urgentCount => _urgentDocuments.length;
  int get inboxCount => _inboxDocuments.length;
  int get archiveCount => _archiveDocuments.length;

  // ===================== LOAD DOCUMENTS =====================

  /// Loads ALL documents via GET /documents (used by document list screen)
  Future<void> loadDocuments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _documents = await _service.getAllDocuments();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Loads urgent feed via GET /documents/urgent
  Future<void> loadUrgent() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _urgentDocuments = await _service.getUrgent();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Loads department inbox via GET /departments/inbox
  Future<void> loadInbox() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _inboxDocuments = await _service.getInbox();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Loads dashboard: urgent + inbox in parallel
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getUrgent(),
        _service.getInbox(),
      ]);
      _urgentDocuments = results[0];
      _inboxDocuments = results[1];
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load a single document by ID (fetches from full list, then fallbacks)
  Future<Document?> loadDocument(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDocument = await _service.getDocument(id);
      if (_currentDocument != null) {
        // Update in _documents list
        final index = _documents.indexWhere((d) => d.id == id);
        if (index != -1) {
          _documents[index] = _currentDocument!;
        } else {
          _documents.add(_currentDocument!);
        }

        // Update in _inboxDocuments list
        final inboxIndex = _inboxDocuments.indexWhere((d) => d.id == id);
        if (inboxIndex != -1) {
          _inboxDocuments[inboxIndex] = _currentDocument!;
        }
      }
      return _currentDocument;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search archive via GET /documents/archive?search=query
  Future<void> searchArchive(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.searchArchive(query);
      _archiveDocuments = result['documents'] as List<Document>;
      _archiveAccessLevel = result['access_level'] as String? ?? '';
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load departments via GET /departments
  Future<void> loadDepartments() async {
    try {
      _departments = await _service.getDepartments();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // ===================== DOCUMENT ACTIONS =====================

  // ✅ PHASE 1: UPLOAD DOCUMENT → POST /documents
  Future<bool> uploadDocument({
    required String title,
    required String filePath,
    String? comment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final error = await _service.uploadDocument(
        title: title,
        filePath: filePath,
        comment: comment,
      );

      if (error == null) {
        await loadUrgent();
        await loadDocuments();
        return true;
      }
      _errorMessage = error;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ PHASE 2: DG ASSIGN → POST /documents/{id}/direct
  Future<bool> assignDocument({
    required int id,
    required int departmentId,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final error = await _service.assignDocument(
        id: id,
        departmentId: departmentId,
        note: note,
      );

      if (error == null) {
        await loadUrgent();
        await loadDocument(id);
        return true;
      }
      _errorMessage = error;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ PHASE 3: DISPATCH → POST /documents/{id}/dispatch
  Future<bool> dispatchDocument({
    required int id,
    String? comment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final error = await _service.dispatchDocument(
        id: id,
        comment: comment,
      );

      if (error == null) {
        await loadUrgent();
        await loadDocument(id);
        return true;
      }
      _errorMessage = error;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ PHASE 4: UPLOAD REPORT → POST /documents/{id}/report
  Future<bool> uploadReport({
    required int id,
    required String filePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final error = await _service.uploadReport(
        id: id,
        filePath: filePath,
      );

      if (error == null) {
        await loadUrgent();
        await loadDocument(id);
        return true;
      }
      _errorMessage = error;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ PHASE 5 & 6: SIGN → POST /documents/{id}/vdg-sign or dg-sign
  Future<bool> signDocument(int id, bool isVdg) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final error = await _service.signDocument(id, isVdg);

      if (error == null) {
        await loadUrgent();
        await loadDocument(id);
        return true;
      }
      _errorMessage = error;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ PHASE 7: ARCHIVE → POST /documents/{id}/archive
  Future<bool> archiveDocument(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final error = await _service.archiveDocument(id);

      if (error == null) {
        await loadUrgent();
        await loadDocument(id);
        return true;
      }
      _errorMessage = error;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ DOWNLOAD FILE → GET /documents/{id}/download
  Future<Map<String, dynamic>> downloadFile(int id) async {
    return await _service.downloadFile(id);
  }

  // ✅ CLEAR FUNCTIONS
  void clearCurrentDocument() {
    _currentDocument = null;
    notifyListeners();
  }

  void clearArchive() {
    _archiveDocuments = [];
    _archiveAccessLevel = '';
    notifyListeners();
  }

  void clearAll() {
    _documents = [];
    _urgentDocuments = [];
    _inboxDocuments = [];
    _archiveDocuments = [];
    _currentDocument = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ✅ HELPERS
  int getDocumentCountByStatus(String status) {
    return _documents.where((doc) => doc.status == status).length;
  }

  List<Document> getUrgentDocumentsByRole(String role) {
    switch (role) {
      case 'dg':
        return _urgentDocuments
            .where((doc) =>
                doc.status == 'pending_dg_init' ||
                doc.status == 'pending_dg_approval')
            .toList();
      case 'file_dept':
        return _urgentDocuments
            .where((doc) =>
                doc.status == 'pending_dispatch' ||
                doc.status == 'dg_signed')
            .toList();
      case 'vdg':
        return _urgentDocuments
            .where((doc) => doc.status == 'pending_vdg_approval')
            .toList();
      case 'department':
      case 'staff':
        return _urgentDocuments
            .where((doc) => doc.status == 'dg_directed')
            .toList();
      default:
        return _urgentDocuments;
    }
  }

  Document? getDocumentByControlNo(String controlNo) {
    try {
      return _documents.firstWhere((doc) => doc.controlNo == controlNo);
    } catch (_) {
      return null;
    }
  }
}