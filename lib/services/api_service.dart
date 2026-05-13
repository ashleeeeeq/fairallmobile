import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: AppConfig.tokenKey);

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    print('API POST Request: $url');
    print('Request Body: $data');

    final headers = await _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return response;
    } catch (e) {
      print('Network error: $e');
      rethrow;
    }
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    print('API GET Request: $url');

    final headers = await _getHeaders();

    try {
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('✅ Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Network error: $e');
      rethrow;
    }
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      return response;
    } catch (e) {
      print('Network error: $e');
      rethrow;
    }
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await http.delete(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      return response;
    } catch (e) {
      print('Network error: $e');
      rethrow;
    }
  }

  static Future<void> setToken(String token) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
  }

  static Future<void> removeToken() async {
    await _storage.delete(key: AppConfig.tokenKey);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.tokenKey);
  }
}