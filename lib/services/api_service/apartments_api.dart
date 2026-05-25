import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_logger.dart';
import 'base_api.dart';

class ApartmentsApiService {
  static Future<Map<String, dynamic>> getApartments(String token) async {
    final res = await apiLogged('GET', '/api/apartments', () => http.get(
      Uri.parse('$apiBase/api/apartments'),
      headers: apiHeaders(token),
    ));
    if (res['status'] == 200 && res['body'] is Map && res['body']['data'] is List) {
      res['body'] = res['body']['data'];
    }
    return res;
  }

  static Future<Map<String, dynamic>> getApartment(String token, int id) async {
    return apiLogged('GET', '/api/apartments/$id', () => http.get(
      Uri.parse('$apiBase/api/apartments/$id'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> createApartment(
      String token, Map<String, String> fields) async {
    AppLogger.instance.info('API', 'POST /api/apartments', fields);
    final req = http.MultipartRequest('POST', Uri.parse('$apiBase/api/apartments'));
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $token';
    req.fields.addAll(fields);
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);
    AppLogger.instance.api('POST', '/api/apartments', res.statusCode, body);
    return {'status': res.statusCode, 'body': body};
  }

  static Future<Map<String, dynamic>> updateApartment(
      String token, int id, Map<String, String> fields) async {
    AppLogger.instance.info('API', 'PUT /api/apartments/$id', fields);
    final req = http.MultipartRequest('PUT', Uri.parse('$apiBase/api/apartments/$id'));
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $token';
    req.fields.addAll(fields);
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);
    AppLogger.instance.api('PUT', '/api/apartments/$id', res.statusCode, body);
    return {'status': res.statusCode, 'body': body};
  }

  static Future<Map<String, dynamic>> deleteApartment(
      String token, int id) async {
    return apiLogged('DELETE', '/api/apartments/$id', () => http.delete(
      Uri.parse('$apiBase/api/apartments/$id'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> joinApartment(
      String token, int id) async {
    return apiLogged('POST', '/api/apartments/$id/join', () => http.post(
      Uri.parse('$apiBase/api/apartments/$id/join'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> leaveApartment(
      String token, int id) async {
    return apiLogged('POST', '/api/apartments/$id/leave', () => http.post(
      Uri.parse('$apiBase/api/apartments/$id/leave'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> getApartmentMembers(
      String token, int apartmentId) async {
    return apiLogged('GET', '/api/apartments/$apartmentId/members', () => http.get(
      Uri.parse('$apiBase/api/apartments/$apartmentId/members'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> removeApartmentMember(
      String token, int apartmentId, int userId) async {
    return apiLogged('POST', '/api/apartments/$apartmentId/remove-member', () => http.post(
      Uri.parse('$apiBase/api/apartments/$apartmentId/remove-member'),
      headers: apiHeaders(token),
      body: jsonEncode({'user_id': userId}),
    ));
  }

  static Future<Map<String, dynamic>> addApartmentMember(
      String token, int apartmentId, String email) async {
    return apiLogged('POST', '/api/apartments/$apartmentId/add-member', () => http.post(
      Uri.parse('$apiBase/api/apartments/$apartmentId/add-member'),
      headers: apiHeaders(token),
      body: jsonEncode({'email': email}),
    ));
  }
}
