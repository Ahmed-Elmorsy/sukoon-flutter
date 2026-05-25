import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'auth_session.dart';

/// Singleton polling service that checks for new notifications every N seconds
/// and broadcasts changes to listeners. Works on ALL platforms (no FCM needed).
class NotificationPoller extends ChangeNotifier {
  NotificationPoller._();
  static final NotificationPoller instance = NotificationPoller._();

  Timer? _timer;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _latest = [];

  int get unreadCount => _unreadCount;
  List<Map<String, dynamic>> get latest => _latest;

  /// Start polling. Call once after login.
  void start({Duration interval = const Duration(seconds: 15)}) {
    stop();
    _poll(); // immediate first check
    _timer = Timer.periodic(interval, (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    final token = AuthSession.instance.token;
    if (token.isEmpty) return;
    try {
      final res = await ApiService.getNotifications(token);
      if (res['status'] == 200) {
        final data = (res['body']['data'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final unread = data.where((n) => n['status']?.toString() != 'read').length;
        if (unread != _unreadCount || data.length != _latest.length) {
          _unreadCount = unread;
          _latest = data;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Force an immediate refresh (e.g. after user reads a notification)
  Future<void> refresh() => _poll();
}
