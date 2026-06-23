import '../models/notification.dart';
import 'api_client.dart';

/// NOTE: The backend has no dedicated /notifications endpoint.
/// Notifications are derived from the urgent feed and department inbox.
/// This service polls those two endpoints and builds NotificationModel objects.
class NotificationService {
  final ApiClient _api = ApiClient();

  Future<List<NotificationModel>> getNotifications() async {
    final List<NotificationModel> result = [];

    // Poll urgent documents feed
    final urgentRes = await _api.get('/documents/urgent');
    if (!urgentRes.containsKey('error')) {
      final List<dynamic> docs =
          urgentRes['documents'] ?? urgentRes['data'] ?? [];
      for (final doc in docs) {
        result.add(_docToNotification(doc, isUrgent: true));
      }
    }

    // Poll department inbox
    final inboxRes = await _api.get('/departments/inbox');
    if (!inboxRes.containsKey('error')) {
      final List<dynamic> docs =
          inboxRes['documents'] ?? inboxRes['data'] ?? [];
      for (final doc in docs) {
        // Avoid duplicates (doc already in urgent)
        final alreadyAdded = result.any((n) => n.id == doc['id']);
        if (!alreadyAdded) {
          result.add(_docToNotification(doc, isUrgent: false));
        }
      }
    }

    // Sort by updatedAt descending
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  NotificationModel _docToNotification(
    Map<String, dynamic> doc, {
    required bool isUrgent,
  }) {
    final status = doc['status'] ?? '';
    final title = doc['title'] ?? 'Document';
    final controlNo = doc['control_no'] ?? '';
    final message = _statusMessage(status, title, controlNo);

    return NotificationModel(
      id: doc['id'] ?? 0,
      title: isUrgent ? 'Action Required' : 'Inbox Update',
      message: message,
      isRead: false,
      createdAt: DateTime.tryParse(doc['updated_at'] ?? '') ?? DateTime.now(),
      documentId: doc['id'],
    );
  }

  String _statusMessage(String status, String title, String controlNo) {
    switch (status) {
      case 'pending_dg_init':
        return '"$title" ($controlNo) is waiting for DG review.';
      case 'pending_dispatch':
        return '"$title" ($controlNo) is ready to be dispatched.';
      case 'dg_directed':
        return '"$title" ($controlNo) has been directed to your department.';
      case 'pending_vdg_approval':
        return '"$title" ($controlNo) requires VDG approval.';
      case 'pending_dg_approval':
        return '"$title" ($controlNo) requires DG final approval.';
      case 'dg_signed':
        return '"$title" ($controlNo) has been signed by DG. Ready to archive.';
      case 'completed_archive':
        return '"$title" ($controlNo) has been archived.';
      default:
        return '"$title" ($controlNo) — status: $status';
    }
  }

  /// Mark as read is local-only since the backend has no notification endpoint.
  Future<bool> markAsRead(int id) async => true;

  /// Mark all read is local-only.
  Future<bool> markAllRead() async => true;

  /// Count unread from urgent feed.
  Future<int> getUnreadCount() async {
    final res = await _api.get('/documents/urgent');
    if (res.containsKey('error')) return 0;
    final List<dynamic> docs = res['documents'] ?? res['data'] ?? [];
    return docs.length;
  }
}