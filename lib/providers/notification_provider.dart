import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      // Handle error silently
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    try {
      await _service.markAsRead(id);
      await loadNotifications();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> markAllRead() async {
    try {
      await _service.markAllRead();
      await loadNotifications();
    } catch (e) {
      // Handle error
    }
  }

  Future<int> getUnreadCount() async {
    try {
      _unreadCount = await _service.getUnreadCount();
      notifyListeners();
      return _unreadCount;
    } catch (e) {
      return 0;
    }
  }
}