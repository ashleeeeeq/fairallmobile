import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/screens/bottom_bar/beneficiary_bar.dart';
import 'package:fairallmobile/screens/bottom_bar/donor_bar.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Navigate to appropriate screen based on user type
    if (user.userType == 'beneficiary') {
      return BeneficiaryMainScreen(user: user);
    } else if (user.userType == 'donor') {
      // Create DonorMainScreen if you have it
      // return DonorMainScreen(user: user);
      // Temporary fallback
      return Scaffold(
        appBar: AppBar(title: const Text('Donor Dashboard')),
        body: Center(child: Text('Welcome Donor: ${user.displayName}')),
      );
    } else {
      // Fallback for staff or other types
      return Scaffold(
        appBar: AppBar(title: const Text('FAIRALL')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(user.displayName, style: const TextStyle(fontSize: 18)),
              Text(user.email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
  }
}