import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/document.dart';

class DocumentProvider extends ChangeNotifier {
  List<Document> urgentDocuments = [];
  bool isLoading = false;
  String? errorMessage;
  int urgentCount = 0;

  Future<void> fetchUrgentFeed() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await ApiService.call('GET', '/documents/urgent');

    if (result.containsKey('error') && result['error'] == true) {
      errorMessage = result['message'];
      urgentDocuments = [];
    } else {
      final List<dynamic> docData = result['documents'] ?? [];
      urgentDocuments = docData.map((json) => Document.fromJson(json)).toList();
      urgentCount = result['urgent_count'] ?? urgentDocuments.length;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> performAction(int documentId, String actionEndpoint, {Map<String, dynamic>? body}) async {
    isLoading = true;
    notifyListeners();

    final result = await ApiService.call('POST', '/documents/$documentId/$actionEndpoint', body: body);

    isLoading = false;
    notifyListeners();

    if (result.containsKey('error') && result['error'] == true) {
      errorMessage = result['message'];
      return false;
    }

    await fetchUrgentFeed();
    return true;
  }
}