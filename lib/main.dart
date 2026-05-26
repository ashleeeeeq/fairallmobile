import 'package:flutter/material.dart';
import 'screens/login_screen.dart';


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
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFD6E4F0), // BGcolor
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF162172),
          primary: const Color(0xFF162172), // Deep Blue
          secondary: const Color(0xFF1E56A0), // Vibrant Blue
          surface: const Color(0xFF1C2143), // Dark Blue
          tertiary: const Color(0xFFFFCC33), // Yellow Accent
          shadow: const Color(0xFF010101), // Pure Black
          error: const Color(0xFFA90008), // Warning/Cancel Red
          tertiaryContainer: const Color(0xFFDBFCE7), // Green BG
          onTertiaryContainer: const Color(0xFF1E974F), // Green Text
        ),
      ),
      home: const LoginPage(),
    );
  }
}