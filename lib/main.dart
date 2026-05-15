import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'utils/app_colors.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginPage(),
    );
  }
}