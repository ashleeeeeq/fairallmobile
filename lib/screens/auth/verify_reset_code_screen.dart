import 'package:flutter/material.dart';
import 'package:fairallmobile/repositories/auth_repository.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'reset_password_screen.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  final String email;

  const VerifyResetCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyResetCodeScreen> createState() =>
      _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState
    extends State<VerifyResetCodeScreen> {
  final TextEditingController _codeController =
  TextEditingController();

  final AuthRepository _authRepository =
  AuthRepository();

  bool _isLoading = false;

  Future<void> _verifyCode() async {
    final String code =
    _codeController.text.trim();

    // Validation
    if (code.isEmpty) {
      _showSnackBar(
        'Please enter verification code',
        Colors.red,
      );
      return;
    }

    if (code.length != 6) {
      _showSnackBar(
        'Enter a valid 6-digit code',
        Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
      await _authRepository
          .verifyResetCode(
        widget.email,
        code,
      );

      if (!mounted) return;

      if (result.success) {
        _showSnackBar(
          result.message,
          Colors.green,
        );

        // Navigate only if verified
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ResetPasswordScreen(
                  email: widget.email,
                  code: code,
                ),
          ),
        );
      } else {
        _showSnackBar(
          result.message,
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Connection error. Please try again.',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(
      String message,
      Color color,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Verify Code'),
        backgroundColor:
        AppColors.surface,
        foregroundColor:
        Colors.white,
      ),
      body: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 20,
            ),

            const Text(
              'Verification Code',
              style: TextStyle(
                fontSize: 28,
                fontWeight:
                FontWeight.bold,
                color:
                AppColors.surface,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              'Enter the 6-digit code sent to\n${widget.email}',
              style:
              const TextStyle(
                fontSize: 16,
                color:
                AppColors
                    .grayText,
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            TextField(
              controller:
              _codeController,
              keyboardType:
              TextInputType
                  .number,
              maxLength: 6,
              decoration:
              InputDecoration(
                hintText:
                '6-digit code',
                prefixIcon:
                const Icon(
                  Icons.security,
                ),
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            SizedBox(
              width:
              double.infinity,
              height: 50,
              child:
              ElevatedButton(
                onPressed:
                _isLoading
                    ? null
                    : _verifyCode,
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  AppColors
                      .tertiary,
                  foregroundColor:
                  Colors.black,
                ),
                child:
                _isLoading
                    ? const SizedBox(
                  height:
                  20,
                  width:
                  20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(
                      Colors
                          .black,
                    ),
                  ),
                )
                    : const Text(
                  'Verify Code',
                  style:
                  TextStyle(
                    fontSize:
                    16,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(
                      context);
                },
                child:
                const Text(
                  'Back',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}