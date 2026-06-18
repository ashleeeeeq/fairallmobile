import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fairallmobile/services/api_service.dart';

class NotificationBadgeNotifier extends ChangeNotifier {
  static final NotificationBadgeNotifier _instance =
      NotificationBadgeNotifier._();
  factory NotificationBadgeNotifier() => _instance;
  NotificationBadgeNotifier._();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  String _currentRole = 'beneficiary';
  Timer? _timer;

  void startPolling(String role) {
    _currentRole = role;
    if (_timer != null) return;
    fetchUnreadCount();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchUnreadCount(),
    );
  }

  Future<void> fetchUnreadCount() async {
    try {
      final prefix = _currentRole == 'donor' ? '/donor' : '/beneficiary';
      final response =
          await ApiService.get('$prefix/notifications/unread-count');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _unreadCount = data['data']['unread_count'] ?? 0;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }
}
