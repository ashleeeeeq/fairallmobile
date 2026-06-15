import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  final User user;
  final String role; // 'beneficiary' or 'donor'

  const NotificationScreen({
    super.key,
    required this.user,
    this.role = 'beneficiary',
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool showAll = true;
  bool _isLoading = true;
  bool _hasError = false;

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  String get _prefix => widget.role == 'donor' ? '/donor' : '/beneficiary';

  List<Map<String, dynamic>> get _filteredNotifications {
    if (showAll) return _notifications;
    return _notifications.where((n) => n['is_read'] == false).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ApiService.get('$_prefix/notifications');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final rawList = data['data']['notifications'] as List;
          setState(() {
            _notifications = rawList.map((e) => Map<String, dynamic>.from(e)).toList();
            _unreadCount = data['data']['unread_count'] ?? 0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Notification fetch error: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await ApiService.put('$_prefix/notifications/$id/read', {});
      _fetchNotifications();
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.post('$_prefix/notifications/read-all', {});
      _fetchNotifications();
    } catch (e) {
      debugPrint('Mark all read error: $e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await ApiService.delete('$_prefix/notifications/$id');
      _fetchNotifications();
    } catch (e) {
      debugPrint('Delete notification error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_left, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Notification',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
            ? _buildError()
            : _notifications.isEmpty
            ? _buildEmpty()
            : _buildContent(),
      );
    }

  Widget _buildContent() {
    final filtered = _filteredNotifications;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                        title: 'All',
                        isActive: showAll,
                        onTap: () => setState(() => showAll = true)
                    ),
                    _buildTabButton(
                        title: 'Unread',
                        isActive: !showAll,
                        badgeCount: _unreadCount,
                        onTap: () => setState(() => showAll = false)
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all, size: 18, color: AppColors.surface),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    fontFamily: AppFonts.roboto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  showAll ? 'No notifications' : 'No unread notifications',
                  style: const TextStyle(color: AppColors.grayText, fontSize: 16, fontFamily: AppFonts.roboto),
                ),
              ),
            )
          else
            ...filtered.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNotificationCard(n),
            )),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String title, required bool isActive, int? badgeCount, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.tertiary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: AppFonts.roboto,
                color: AppColors.surface,
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: AppColors.grayText, shape: BoxShape.circle),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_rounded, color: AppColors.orangeAccent, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification['title'] ?? 'NOTIFICATION',
                          style: const TextStyle(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppFonts.roboto,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          notification['created_at'] ?? '',
                          style: const TextStyle(color: AppColors.grayText, fontSize: 11, fontFamily: AppFonts.roboto),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification['message'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: AppFonts.roboto),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          notification['is_read'] == true
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightredbg,
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _deleteNotification(notification['id']),
                    child: const Text('Delete',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: AppFonts.roboto)),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightredbg,
                          foregroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () => _deleteNotification(notification['id']),
                        child: const Text('Delete',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: AppFonts.roboto)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tertiaryContainer,
                          foregroundColor: AppColors.onTertiaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () => _markAsRead(notification['id']),
                        child: const Text('Mark as read',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: AppFonts.roboto)),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.grayText),
          const SizedBox(height: 16),
          const Text(
            'Failed to load notifications',
            style: TextStyle(color: AppColors.grayText, fontSize: 16, fontFamily: AppFonts.roboto),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tertiary,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.grayText),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(color: AppColors.grayText, fontSize: 16, fontFamily: AppFonts.roboto),
          ),
        ],
      ),
    );
  }
}
