import 'package:flutter/material.dart';
import 'bottom_bar/beneficiary_bar.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryDark = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'SAMPLE ACTIVITIES PAGE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: primaryDark,
            ),
          ),
        ),
      ),
    );
  }
}