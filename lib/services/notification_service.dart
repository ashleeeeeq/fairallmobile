import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fairallmobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  void Function(Map<String, dynamic>)? onNotificationTap;
  Map<String, dynamic>? currentUserData;

  bool _initialized = false;
  String? _lastRegisteredToken;

  static const _tokenKey = 'fcm_token';

  Future<void> initialize() async {
    if (_initialized) return;

    final messagingSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Notification permission: ${messagingSettings.authorizationStatus}',
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await FlutterLocalNotificationsPlugin().initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageData(initialMessage.data);
    }

    _initialized = true;
  }

  void _onTokenRefresh(String newToken) {
    debugPrint('FCM token refreshed: $newToken');
    _registerToken(newToken);
  }

  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('FCM token error: $e');
      return null;
    }
  }

  Future<void> registerToken() async {
    try {
      final token = await getToken();
      if (token == null) return;
      _registerToken(token);
    } catch (e) {
      debugPrint('Register device token error: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      if (token == savedToken && _lastRegisteredToken == token) return;

      final deviceType = Platform.isIOS ? 'ios' : 'android';
      await ApiService.post('/device-tokens', {
        'token': token,
        'device_type': deviceType,
      });
      await prefs.setString(_tokenKey, token);
      _lastRegisteredToken = token;
      debugPrint('✅ Device token registered ($deviceType)');
    } catch (e) {
      debugPrint('Register device token error: $e');
    }
  }

  Future<void> unregisterToken() async {
    try {
      final token = await getToken();
      if (token == null) return;

      await ApiService.post('/device-tokens/revoke', {'token': token});
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      _lastRegisteredToken = null;
      debugPrint('Device token revoked');
    } catch (e) {
      debugPrint('Revoke device token error: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        id: data.hashCode,
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: data,
      );
    } else if (data.isNotEmpty) {
      _showLocalNotification(
        id: data.hashCode,
        title: data['title'] ?? 'New Update',
        body: data['body'] ?? data['message'] ?? '',
        payload: data,
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _handleMessageData(message.data);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = Map<String, dynamic>.from(jsonDecode(response.payload!));
        _handleMessageData(data);
      } catch (_) {}
    }
  }

  void _handleMessageData(Map<String, dynamic> data) {
    if (onNotificationTap != null) {
      onNotificationTap!(data);
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Notifications',
      channelDescription: 'App notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await FlutterLocalNotificationsPlugin().show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }
}
