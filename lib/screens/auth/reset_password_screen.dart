import 'package:flutter/material.dart';
import 'package:fairallmobile/repositories/auth_repository.dart';
import 'package:fairallmobile/screens/login_screen.dart';
import 'package:fairallmobile/utils/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  // Password validation
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  void _validatePassword(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[@$!%*#?&]'));
    });
  }

  String? _getPasswordError() {
    if (_passwordController.text.isEmpty) return null;
    if (!_hasMinLength) return 'Password must be at least 8 characters';
    if (!_hasUppercase) return 'Password must contain at least one uppercase letter';
    if (!_hasLowercase) return 'Password must contain at least one lowercase letter';
    if (!_hasNumber) return 'Password must contain at least one number';
    if (!_hasSpecialChar) return 'Password must contain at least one special character (@\$!%*#?&)';
    return null;
  }

  Future<void> _resetPassword() async {
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (password.isEmpty) {
      _showSnackBar('Please enter a new password', Colors.red);
      return;
    }

    // Check password strength
    final passwordError = _getPasswordError();
    if (passwordError != null) {
      _showSnackBar(passwordError, Colors.red);
      return;
    }

    if (confirmPassword.isEmpty) {
      _showSnackBar('Please confirm your password', Colors.red);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authRepository.resetPassword(
        widget.email,
        widget.code,
        password,
        confirmPassword,
      );

      if (!mounted) return;

      if (result.success) {
        _showSnackBar(result.message, Colors.green);

        // Navigate back to login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      } else {
        _showSnackBar(result.message, Colors.red);
      }
    } catch (e) {
      _showSnackBar('Connection error. Please try again.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passwordError = _getPasswordError();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Create New Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Password must contain:',
                style: TextStyle(fontSize: 16, color: AppColors.grayText),
              ),

              const SizedBox(height: 8),

              // Password requirements checklist
              _buildRequirementTile(
                'At least 8 characters',
                _hasMinLength,
              ),
              _buildRequirementTile(
                'At least one uppercase letter (A-Z)',
                _hasUppercase,
              ),
              _buildRequirementTile(
                'At least one lowercase letter (a-z)',
                _hasLowercase,
              ),
              _buildRequirementTile(
                'At least one number (0-9)',
                _hasNumber,
              ),
              _buildRequirementTile(
                'At least one special character (@\$!%*#?&)',
                _hasSpecialChar,
              ),

              const SizedBox(height: 30),

              // New Password
              TextField(
                controller: _passwordController,
                obscureText: _hidePassword,
                onChanged: _validatePassword,
                decoration: InputDecoration(
                  hintText: 'New Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hidePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: passwordError,
                ),
              ),

              const SizedBox(height: 20),

              // Confirm Password
              TextField(
                controller: _confirmPasswordController,
                obscureText: _hideConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hideConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _hideConfirmPassword = !_hideConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    foregroundColor: Colors.black,
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
                    'Reset Password',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementTile(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet ? Colors.green : Colors.grey,
              decoration: isMet ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}