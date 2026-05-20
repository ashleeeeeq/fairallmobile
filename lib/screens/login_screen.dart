import 'package:flutter/material.dart';
import 'package:fairallmobile/repositories/auth_repository.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/screens/home_screen.dart';
import 'package:fairallmobile/screens/donor_account_type_screen.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'auth/forgot_password_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();

  bool _hidePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  Future<void> _handleLogin() async {
    final String identifier = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter your email/login ID and password', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authRepository.login(identifier, password);

      if (!mounted) return;

      if (result['success']) {
        final User user = result['user'];

        // 🔒 REJECT STAFF USERS - Only allow beneficiary and donor
        if (user.userType == 'staff') {
          _showSnackBar(
            'Access denied. Staff members cannot access the mobile app. Please use the web portal.',
            Colors.red,
          );
          await _authRepository.logout(); // Clear any saved session
          setState(() => _isLoading = false);
          return;
        }

        // Only allow beneficiary and donor
        if (user.userType != 'beneficiary' && user.userType != 'donor') {
          _showSnackBar(
            'Access denied. Only beneficiaries and donors can use this app.',
            Colors.red,
          );
          await _authRepository.logout();
          setState(() => _isLoading = false);
          return;
        }

        _showSnackBar('Welcome back, ${user.displayName}!', Colors.green);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
        );
      } else {
        _showSnackBar(result['message'] ?? 'Invalid email or password', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Connection error. Please try again.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 4)),
    );
  }

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
                        'Log In',
                        style: TextStyle(
                          fontSize: 32,
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
                        'Access your account',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Email/Login ID Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email or Login ID',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your email or Login ID',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.navy),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.yellow, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Password Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.navy),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.yellow, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: AppColors.yellow,
                            checkColor: AppColors.navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.yellow,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Login Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                        : const Text(
                      'Log In',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign Up Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No account yet? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grayText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DonorAccountTypeScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign up for a donor account',
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

                // Info note
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Only beneficiaries and donors can access this app',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}