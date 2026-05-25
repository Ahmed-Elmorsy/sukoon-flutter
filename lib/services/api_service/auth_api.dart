import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_logger.dart';
import 'base_api.dart';

class AuthApiService {
  static Future<Map<String, dynamic>> register({
    required String phone,
    required String email,
    required String password,
    required String gender,
    required String role,
  }) async {
    final payload = <String, dynamic>{
      'phone': phone,
      'email': email,
      'password': password,
      'gender': gender.toLowerCase(),
      'role': role,
    };
    return apiLogged('POST', '/api/auth/register', () => http.post(
      Uri.parse('$apiBase/api/auth/register'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ));
  }

  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    return apiLogged('POST', '/api/auth/login', () => http.post(
      Uri.parse('$apiBase/api/auth/login'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'login': login, 'password': password}),
    ));
  }

  static Future<Map<String, dynamic>> getMe(String token) async {
    return apiLogged('GET', '/api/auth/me', () => http.get(
      Uri.parse('$apiBase/api/auth/me'),
      headers: apiHeaders(token),
    ));
  }

  static Future<void> logout(String token) async {
    AppLogger.instance.info('API', 'POST /api/auth/logout');
    await http.post(
      Uri.parse('$apiBase/api/auth/logout'),
      headers: apiHeaders(token),
    );
    AppLogger.instance.info('AUTH', 'User logged out');
  }

  static Future<Map<String, dynamic>> forgotPassword(String login) async {
    return apiLogged('POST', '/api/auth/forgot-password', () => http.post(
      Uri.parse('$apiBase/api/auth/forgot-password'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'login': login}),
    ));
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String login,
    required String code,
    required String password,
  }) async {
    return apiLogged('POST', '/api/auth/reset-password', () => http.post(
      Uri.parse('$apiBase/api/auth/reset-password'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'login': login,
        'code': code,
        'password': password,
      }),
    ));
  }

  static Future<Map<String, dynamic>> resendOtp(String emailOrPhone) async {
    return apiLogged('POST', '/api/auth/resend-otp', () => http.post(
      Uri.parse('$apiBase/api/auth/resend-otp'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': emailOrPhone}),
    ));
  }

  static Future<Map<String, dynamic>> verifyOtp(String emailOrPhone, String code) async {
    return apiLogged('POST', '/api/auth/verify-otp', () => http.post(
      Uri.parse('$apiBase/api/auth/verify-otp'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': emailOrPhone, 'code': code}),
    ));
  }

  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String password,
  }) async {
    return apiLogged('POST', '/api/auth/change-password', () => http.post(
      Uri.parse('$apiBase/api/auth/change-password'),
      headers: apiHeaders(token),
      body: jsonEncode({
        'current_password': currentPassword,
        'password': password,
      }),
    ));
  }

  static Future<Map<String, dynamic>> refreshToken(String token) async {
    return apiLogged('POST', '/api/auth/token/refresh', () => http.post(
      Uri.parse('$apiBase/api/auth/token/refresh'),
      headers: apiHeaders(token),
    ));
  }

  static Future<void> saveFcmToken(String token, String fcmToken) async {
    try {
      await apiLogged('POST', '/api/auth/fcm-token', () => http.post(
        Uri.parse('$apiBase/api/auth/fcm-token'),
        headers: apiHeaders(token),
        body: jsonEncode({'fcm_token': fcmToken}),
      ));
    } catch (e) {
      AppLogger.instance.error('FCM', 'Failed to save FCM token: $e');
    }
  }
}
