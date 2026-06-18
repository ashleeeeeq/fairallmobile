import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/notification_badge_notifier.dart';
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
  late final NotificationBadgeNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = NotificationBadgeNotifier();
    _notifier.startPolling(widget.role);
  }

  void _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NotificationScreen(user: widget.user, role: widget.role),
      ),
    );
    _notifier.fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        final count = _notifier.unreadCount;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: _openNotifications,
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    count > 99 ? '99+' : '$count',
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
      },
    );
  }
}
