import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_api.dart';

class AdminApiService {
  static Future<Map<String, dynamic>> getUsers(String token) async {
    return apiLogged('GET', '/api/admin/users', () => http.get(
      Uri.parse('$apiBase/api/admin/users'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> createUser(
      String token, Map<String, dynamic> data) async {
    return apiLogged('POST', '/api/admin/users', () => http.post(
      Uri.parse('$apiBase/api/admin/users'),
      headers: apiHeaders(token),
      body: jsonEncode(data),
    ));
  }

  static Future<Map<String, dynamic>> updateUser(
      String token, int id, Map<String, dynamic> data) async {
    return apiLogged('PUT', '/api/admin/users/$id', () => http.put(
      Uri.parse('$apiBase/api/admin/users/$id'),
      headers: apiHeaders(token),
      body: jsonEncode(data),
    ));
  }

  static Future<Map<String, dynamic>> deleteUser(
      String token, int id) async {
    return apiLogged('DELETE', '/api/admin/users/$id', () => http.delete(
      Uri.parse('$apiBase/api/admin/users/$id'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> promoteToAdmin(
      String token, int id) async {
    return apiLogged('POST', '/api/admin/users/$id/promote', () => http.post(
      Uri.parse('$apiBase/api/admin/users/$id/promote'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> demoteFromAdmin(
      String token, int id) async {
    return apiLogged('POST', '/api/admin/users/$id/demote', () => http.post(
      Uri.parse('$apiBase/api/admin/users/$id/demote'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> verifyApartment(
      String token, int id) async {
    return apiLogged('POST', '/api/admin/apartments/$id/verify', () => http.post(
      Uri.parse('$apiBase/api/admin/apartments/$id/verify'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> refuseApartment(
      String token, int id, {String? reason}) async {
    return apiLogged('POST', '/api/admin/apartments/$id/refuse', () => http.post(
      Uri.parse('$apiBase/api/admin/apartments/$id/refuse'),
      headers: apiHeaders(token),
      body: jsonEncode({'reason': reason}),
    ));
  }
}
