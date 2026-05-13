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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}