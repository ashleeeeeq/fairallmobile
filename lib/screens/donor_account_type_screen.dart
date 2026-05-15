import 'package:flutter/material.dart';
import 'package:fairallmobile/screens/individual_registration_screen.dart';
import 'package:fairallmobile/screens/organization_registration_screen.dart';
import 'package:fairallmobile/screens/login_screen.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class DonorAccountTypeScreen extends StatefulWidget {
  const DonorAccountTypeScreen({super.key});

  @override
  State<DonorAccountTypeScreen> createState() => _DonorAccountTypeScreenState();
}

class _DonorAccountTypeScreenState extends State<DonorAccountTypeScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Create Donor Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 3,
                        color: AppColors.yellow,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Select your account type',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Individual Donor Card
                _buildAccountTypeCard(
                  title: 'Individual Donor',
                  description: 'Register as a person to make donations',
                  type: 'individual',
                ),
                const SizedBox(height: 20),

                // Organization Donor Card
                _buildAccountTypeCard(
                  title: 'Organization Donor',
                  description: 'Register an organization to make group donations',
                  type: 'organization',
                ),
                const SizedBox(height: 48),

                // Continue Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedType != null
                        ? () {
                      if (_selectedType == 'individual') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IndividualRegistrationScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrganizationRegistrationScreen(),
                          ),
                        );
                      }
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign In Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grayText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          'Sign in here',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required String title,
    required String description,
    required String type,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _selectedType == type ? AppColors.yellow.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: _selectedType == type ? AppColors.yellow : Colors.grey.shade300,
            width: _selectedType == type ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Radio(
              value: type,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
              activeColor: AppColors.yellow,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grayText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}