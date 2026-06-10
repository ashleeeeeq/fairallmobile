import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'utils/app_colors.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase init error (non-fatal): $e');
  }

  runApp(const FAIRALLApp());
}

class FAIRALLApp extends StatelessWidget {
  const FAIRALLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
