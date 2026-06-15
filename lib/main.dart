import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user_model.dart';
import 'screens/login_screen.dart';
import 'screens/beneficiary/competition_details_screen.dart';
import 'screens/beneficiary/event_details_screen.dart';
import 'screens/beneficiary/activity_details_screen.dart';
import 'utils/app_colors.dart';
import 'services/notification_service.dart';
import 'config/app_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase init error (non-fatal): $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final userJson = prefs.getString(AppConfig.userKey);
  final storedToken = prefs.getString(AppConfig.tokenKey);
  if (userJson != null) {
    try {
      NotificationService().currentUserData = jsonDecode(userJson);
    } catch (_) {}
  }
  if (storedToken != null && storedToken.isNotEmpty) {
    NotificationService().registerToken();
  }

  NotificationService().onNotificationTap = (data) {
    final type = data['type'] ?? '';
    final id = data['id'];

    if (id == null) return;

    final userMap = NotificationService().currentUserData;
    if (userMap == null) return;

    final user = User.fromJson(userMap);

    Widget screen;
    if (type == 'competition') {
      screen = CompetitionDetailsScreen(
        competition: data,
        user: user,
      );
    } else if (type == 'event') {
      screen = EventDetailsScreen(eventId: id, user: user);
    } else {
      screen = ActivityDetailsScreen(activityId: id, user: user);
    }

    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => screen),
    );
  };

  runApp(const FAIRALLApp());
}

class FAIRALLApp extends StatelessWidget {
  const FAIRALLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'FAIRALL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.surface),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginPage(),
    );
  }
}
