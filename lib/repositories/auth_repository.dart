import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../config/app_config.dart';
import '../models/forgot_password_model.dart';

class AuthRepository {
  // REAL API LOGIN - Connects to your database
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('REAL API Login attempt: $email');
      print('URL: ${AppConfig.baseUrl}${AppConfig.login}');

      final response = await ApiService.post(AppConfig.login, {
        'email': email,
        'password': password,
      });

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Your API returns 'access_token' (not 'token')
        final String token = data['access_token'] ?? data['token'] ?? '';
        final String refreshToken = data['refresh_token'] ?? '';
        final Map<String, dynamic> userData = data['user'] ?? data['data'] ?? data;

        print('🔑 TOKEN RECEIVED: $token');
        print('🔑 TOKEN LENGTH: ${token.length}');
        print('🔑 TOKEN IS EMPTY: ${token.isEmpty}');

        // Save token first
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.tokenKey, token);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setString(AppConfig.userKey, jsonEncode(userData));

        // Also save in secure storage
        await ApiService.setToken(token);

        // Verify save
        final savedToken = prefs.getString(AppConfig.tokenKey);
        print('🔑 TOKEN SAVED IN SHAREDPREFERENCES: $savedToken');

        final secureToken = await ApiService.getToken();
        print('🔑 TOKEN SAVED IN SECURESTORAGE: $secureToken');

        // Try to fetch full profile with relationships
        User fullUser = User.fromJson(userData);

        try {
          // Wait a moment for token to be set in ApiService headers
          await Future.delayed(const Duration(milliseconds: 100));

          final profileResponse = await ApiService.get(AppConfig.user);
          if (profileResponse.statusCode == 200) {
            final Map<String, dynamic> profileData = jsonDecode(profileResponse.body);
            final Map<String, dynamic> fullUserData = profileData['data'] ?? profileData['user'] ?? profileData;

            // Update stored user data with full profile
            await prefs.setString(AppConfig.userKey, jsonEncode(fullUserData));
            fullUser = User.fromJson(fullUserData);
            print('✅ Full profile loaded with relationships');
          }
        } catch (e) {
          print('⚠️ Could not fetch full profile: $e');
        }

        return {
          'success': true,
          'user': fullUser,
          'token': token,
        };
      } else if (response.statusCode == 401) {
        final Map<String, dynamic> error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Invalid email or password',
        };
      } else if (response.statusCode == 403) {
        final Map<String, dynamic> error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Please verify your email before logging in',
          'requiresVerification': true,
          'email': error['email'],
          'userId': error['user_id'],
        };
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed',
          'errors': error['errors'] ?? {},
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      final errorText = e.toString();
      final isNetworkError = errorText.contains('SocketException') ||
          errorText.contains('Failed host lookup') ||
          errorText.contains('Connection refused') ||
          errorText.contains('TimeoutException') ||
          errorText.contains('ClientException');
      return {
        'success': false,
        'message': isNetworkError
            ? 'Connection error. Make sure the backend is running at ${AppConfig.baseUrl}'
            : 'Unable to complete login. Please try again.',
      };
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);
      if (token != null && token.isNotEmpty) {
        await ApiService.post(AppConfig.logout, {});
      }
    } catch (e) {
      print('Logout API error: $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.tokenKey);
      await prefs.remove('refresh_token');
      await prefs.remove(AppConfig.userKey);
      print('🔓 User logged out');
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        return {'success': false, 'message': 'No refresh token available'};
      }

      final response = await ApiService.post(AppConfig.refresh, {});

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String newToken = data['access_token'] ?? '';

        await prefs.setString(AppConfig.tokenKey, newToken);

        return {
          'success': true,
          'token': newToken,
        };
      } else {
        return {'success': false, 'message': 'Failed to refresh token'};
      }
    } catch (e) {
      print('Refresh token error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConfig.userKey);

    if (userJson != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userJson);
        return User.fromJson(userData);
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConfig.tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<ForgotPasswordResponse> forgotPassword(String email) async {
    try {
      final response = await ApiService.post(AppConfig.forgotPassword, {
        'email': email,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ForgotPasswordResponse(
          success: true,
          message: data['message'] ?? 'Reset code sent to your email',
        );
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        return ForgotPasswordResponse(
          success: false,
          message: error['message'] ?? 'Failed to send reset code',
        );
      }
    } catch (e) {
      return ForgotPasswordResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  Future<ForgotPasswordResponse> verifyResetCode(String email, String code) async {
    try {
      final response = await ApiService.post(AppConfig.verifyResetCode, {
        'email': email,
        'code': code,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ForgotPasswordResponse(
          success: true,
          message: data['message'] ?? 'Code verified successfully',
        );
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        return ForgotPasswordResponse(
          success: false,
          message: error['message'] ?? 'Invalid verification code',
        );
      }
    } catch (e) {
      return ForgotPasswordResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  Future<ForgotPasswordResponse> resetPassword(
      String email,
      String code,
      String password,
      String passwordConfirmation
      ) async {
    try {
      final response = await ApiService.post(AppConfig.resetPassword, {
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'code': code,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ForgotPasswordResponse(
          success: true,
          message: data['message'] ?? 'Password reset successfully',
        );
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        return ForgotPasswordResponse(
          success: false,
          message: error['message'] ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      return ForgotPasswordResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>> donorRegister(Map<String, dynamic> donorData) async {
    try {
      print('Donor registration attempt');
      print('URL: ${AppConfig.baseUrl}${AppConfig.donorRegister}');

      final response = await ApiService.post(AppConfig.donorRegister, donorData);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful. Please verify your email.',
          'user': data['user'],
        };
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Registration failed',
          'errors': error['errors'] ?? {},
        };
      }
    } catch (e) {
      print('❌ Registration error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  // Refresh user data from server (gets latest profile with relationships)
  Future<User?> refreshUserData() async {
    try {
      final response = await ApiService.get(AppConfig.user);
      print('Refresh response status: ${response.statusCode}');
      print('Refresh response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, dynamic> userData = data['data'] ?? data['user'] ?? data;

        print('User data from refresh:');
        print('   - ID: ${userData['id']}');
        print('   - User Type: ${userData['user_type']}');
        print('   - Avatar Path: ${userData['avatar_path']}');

        if (userData['beneficiary'] != null) {
          print('   - Beneficiary: ${userData['beneficiary']['first_name']} ${userData['beneficiary']['last_name']}');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.userKey, jsonEncode(userData));

        return User.fromJson(userData);
      } else {
        print('Refresh failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Refresh error: $e');
      return null;
    }
  }
}