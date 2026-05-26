import 'package:flutter/material.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/screens/bottom_bar/beneficiary_bar.dart';
// TODO: Uncomment when donor features are ready
// import 'package:fairallmobile/screens/bottom_bar/donor_bar.dart';
import 'package:fairallmobile/screens/login_screen.dart';
import 'package:fairallmobile/repositories/auth_repository.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Double-check: Staff should not be here
    if (user.userType == 'staff') {
      // Redirect to login with error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Staff members cannot access the mobile app.',
              style: TextStyle(fontFamily: AppFonts.roboto),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
      return const SizedBox.shrink();
    }

    // Navigate to appropriate screen based on user type
    if (user.userType == 'beneficiary') {
      return BeneficiaryMainScreen(user: user);
    }
    // TODO: Uncomment when donor features are ready
    // else if (user.userType == 'donor') {
    //   return DonorMainScreen(user: user);
    // }
    else {
      // Fallback for donor or other user types
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: const Text(
            'FAIRALL',
            style: TextStyle(fontFamily: AppFonts.roboto, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.surface,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Donor Portal Coming Soon!',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome, ${user.displayName}',
                style: const TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user.email,
                style: const TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 14,
                  color: AppColors.grayText,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  // Logout for now
                  final authRepo = AuthRepository();
                  await authRepo.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }
  }
}