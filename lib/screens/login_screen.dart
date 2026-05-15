import 'package:flutter/material.dart';
import 'package:fairallmobile/repositories/auth_repository.dart';
import 'package:fairallmobile/models/user_model.dart';
import 'package:fairallmobile/screens/home_screen.dart';
import 'package:fairallmobile/utils/app_colors.dart';
import 'auth/forgot_password_screen.dart';

class LogoPlaceholder extends StatelessWidget {
  final double size;

  const LogoPlaceholder({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.image,
        color: Colors.white70,
        size: 45,
      ),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  void goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => goToLogin(context),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgTop,
                AppColors.bgBottom,
              ],
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LogoPlaceholder(size: 175),
              SizedBox(height: 24),
              Text(
                'FAIRALL',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final AuthRepository _authRepository =
  AuthRepository();

  bool _hidePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final String email =
    _emailController.text.trim();

    final String password =
    _passwordController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(
        'Please enter email and password',
        Colors.red,
      );
      return;
    }

    if (!email.contains('@') ||
        !email.contains('.')) {
      _showSnackBar(
        'Please enter a valid email address',
        Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
      await _authRepository.login(
        email,
        password,
      );

      if (!mounted) return;

      if (result['success']) {
        final User user =
        result['user'];

        _showSnackBar(
          'Welcome back, ${user.displayName}!',
          Colors.green,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HomeScreen(user: user),
          ),
        );
      } else {
        _showSnackBar(
          result['message'] ??
              'Invalid email or password',
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: AppColors.bgTop,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            const Positioned(
              top: 75,
              child: LogoPlaceholder(
                size: 125,
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height:
                MediaQuery.of(context)
                    .size
                    .height *
                    0.70,
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 42,
                  vertical: 55,
                ),
                decoration:
                const BoxDecoration(
                  color: AppColors.card,
                  borderRadius:
                  BorderRadius.only(
                    topLeft:
                    Radius.circular(45),
                    topRight:
                    Radius.circular(45),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color:
                        AppColors.navy,
                        fontSize: 34,
                        fontWeight:
                        FontWeight
                            .w900,
                      ),
                    ),

                    const SizedBox(
                        height: 8),

                    const Text(
                      'Log In to continue',
                      style: TextStyle(
                        color: AppColors
                            .grayText,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                        height: 48),

                    TextField(
                      controller:
                      _emailController,
                      decoration:
                      InputDecoration(
                        hintText:
                        'Email Address',
                        prefixIcon:
                        const Icon(
                          Icons.person,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            30,
                          ),
                        ),
                      ),
                      keyboardType:
                      TextInputType
                          .emailAddress,
                    ),

                    const SizedBox(
                        height: 22),

                    TextField(
                      controller:
                      _passwordController,
                      obscureText:
                      _hidePassword,
                      decoration:
                      InputDecoration(
                        hintText:
                        'Password',
                        prefixIcon:
                        const Icon(
                          Icons.lock,
                        ),
                        suffixIcon:
                        IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons
                                .visibility
                                : Icons
                                .visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _hidePassword =
                              !_hidePassword;
                            });
                          },
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            30,
                          ),
                        ),
                      ),
                    ),

                    Align(
                      alignment:
                      Alignment
                          .centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 40),

                    SizedBox(
                      width:
                      double.infinity,
                      height: 52,
                      child:
                      ElevatedButton(
                        onPressed:
                        _isLoading
                            ? null
                            : _handleLogin,
                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          AppColors
                              .yellow,
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
                          'LOG IN →',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}