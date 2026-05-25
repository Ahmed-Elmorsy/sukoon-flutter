import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../app_logger.dart';
import 'base_api.dart';

class ContractsApiService {
  static Future<Map<String, dynamic>> getContracts(String token) async {
    return apiLogged('GET', '/api/contracts', () => http.get(
      Uri.parse('$apiBase/api/contracts'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> getOwnerContracts(String token) async {
    return apiLogged('GET', '/api/contracts/owner', () => http.get(
      Uri.parse('$apiBase/api/contracts/owner'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> getOwners(String token) async {
    return apiLogged('GET', '/api/owners', () => http.get(
      Uri.parse('$apiBase/api/owners'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> createContract({
    required String token,
    required int apartmentId,
    required Uint8List documentBytes,
    required String fileName,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBase/api/contracts'),
    );
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['apartment_id'] = apartmentId.toString();
    req.fields['type'] = 'contract';
    req.files.add(http.MultipartFile.fromBytes(
      'document',
      documentBytes,
      filename: fileName,
    ));
    AppLogger.instance.info('API', 'POST /api/contracts — apartmentId: $apartmentId');
    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);
    AppLogger.instance.api('POST', '/api/contracts', res.statusCode, body);
    return {'status': res.statusCode, 'body': body};
  }

  static Future<Map<String, dynamic>> acceptContract(
      String token, int id) async {
    return apiLogged('POST', '/api/contracts/$id/accept', () => http.post(
      Uri.parse('$apiBase/api/contracts/$id/accept'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> refuseContract(
      String token, int id, String reason) async {
    return apiLogged('POST', '/api/contracts/$id/refuse', () => http.post(
      Uri.parse('$apiBase/api/contracts/$id/refuse'),
      headers: apiHeaders(token),
      body: jsonEncode({'reason': reason}),
    ));
  }

  static Future<Map<String, dynamic>> getAdminContracts(String token) async {
    return apiLogged('GET', '/api/admin/contracts', () => http.get(
      Uri.parse('$apiBase/api/admin/contracts'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> getContract(
      String token, int id) async {
    return apiLogged('GET', '/api/contracts/$id', () => http.get(
      Uri.parse('$apiBase/api/contracts/$id'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> updateContract({
    required String token,
    required int id,
    required Uint8List documentBytes,
    required String fileName,
    String type = 'contract',
  }) async {
    AppLogger.instance.info('API', 'PUT /api/contracts/$id');
    final req = http.MultipartRequest(
      'PUT',
      Uri.parse('$apiBase/api/contracts/$id'),
    );
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['type'] = type;
    req.files.add(http.MultipartFile.fromBytes('document', documentBytes, filename: fileName));
    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res  = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);
    AppLogger.instance.api('PUT', '/api/contracts/$id', res.statusCode, body);
    return {'status': res.statusCode, 'body': body};
  }

  static Future<Map<String, dynamic>> deleteContract(
      String token, int id) async {
    return apiLogged('DELETE', '/api/contracts/$id', () => http.delete(
      Uri.parse('$apiBase/api/contracts/$id'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> getMyContract(
      String token, int apartmentId) async {
    return apiLogged('GET', '/api/apartments/$apartmentId/contracts', () => http.get(
      Uri.parse('$apiBase/api/apartments/$apartmentId/contracts'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> deleteMyContract(
      String token, int apartmentId) async {
    return apiLogged('DELETE', '/api/apartments/$apartmentId/contracts', () => http.delete(
      Uri.parse('$apiBase/api/apartments/$apartmentId/contracts'),
      headers: apiHeaders(token),
    ));
  }
}
