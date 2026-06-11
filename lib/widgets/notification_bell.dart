import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/screens/notification_screen.dart';

class NotificationBell extends StatefulWidget {
  final User user;
  final String role; // 'beneficiary' or 'donor'

  const NotificationBell({
    super.key,
    required this.user,
    this.role = 'beneficiary',
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchUnreadCount());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final prefix = widget.role == 'donor' ? '/donor' : '/beneficiary';
      final response = await ApiService.get('$prefix/notifications/unread-count');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _unreadCount = data['data']['unread_count'] ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  void _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(user: widget.user, role: widget.role),
      ),
    );
    _fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: _openNotifications,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
