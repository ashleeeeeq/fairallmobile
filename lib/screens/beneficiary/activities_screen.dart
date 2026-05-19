import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class BeneficiaryActivitiesScreen extends StatelessWidget {
  final User user;

  const BeneficiaryActivitiesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Activities'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Activities Screen - Coming Soon'),
      ),
    );
  }
}