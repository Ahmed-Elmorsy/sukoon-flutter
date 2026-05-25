import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'app_logger.dart';

class ApiService {
  static String get _base => AppConfig.apiBaseUrl;

  static Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── AUTH ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _logged(
    String method,
    String path,
    Future<http.Response> Function() call,
  ) async {
    AppLogger.instance.info('API', '$method $path');
    try {
      final res = await call().timeout(const Duration(seconds: 30));
      var body = jsonDecode(res.body);
      AppLogger.instance.api(method, path, res.statusCode, body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (body is Map && body.containsKey('success') && body['success'] == true) {
          body = body['data'] ?? body;
        }
      }
      return {'status': res.statusCode, 'body': body};
    } on Exception catch (e) {
      AppLogger.instance.error('API', '$method $path → $e');
      return {'status': 0, 'body': {'error': e.toString()}};
    }
  }

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
    return _logged('POST', '/api/auth/register', () => http.post(
      Uri.parse('$_base/api/auth/register'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ));
  }

  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    return _logged('POST', '/api/auth/login', () => http.post(
      Uri.parse('$_base/api/auth/login'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'login': login, 'password': password}),
    ));
  }

  static Future<Map<String, dynamic>> getMe(String token) async {
    return _logged('GET', '/api/auth/me', () => http.get(
      Uri.parse('$_base/api/auth/me'),
      headers: _headers(token),
    ));
  }

  static Future<void> logout(String token) async {
    AppLogger.instance.info('API', 'POST /api/auth/logout');
    await http.post(
      Uri.parse('$_base/api/auth/logout'),
      headers: _headers(token),
    );
    AppLogger.instance.info('AUTH', 'User logged out');
  }

  // ── PROFILE ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> saveRentalProfile({
    required String token,
    required String type,
    String? university,
    String? faculty,
    String? company,
    String? jobTitle,
  }) async {
    final payload = <String, dynamic>{
      'type': type,
      if (type == 'student') 'university': university,
      if (type == 'student') 'faculty': faculty,
      if (type == 'employee') 'company': company,
      if (type == 'employee') 'job_title': jobTitle,
    };
    return _logged('POST', '/api/auth/onboarding/rental-profile', () => http.post(
      Uri.parse('$_base/api/auth/onboarding/rental-profile'),
      headers: _headers(token),
      body: jsonEncode(payload),
    ));
  }

  static Future<Map<String, dynamic>> saveUserProfile({
    required String token,
    required String firstName,
    String? middleName,
    required String lastName,
    required int age,
    required String country,
    required String city,
    Uint8List? photoBytes,
    String? photoName,
  }) async {
    AppLogger.instance.info('API', 'POST /api/auth/onboarding/user-profile');
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/auth/onboarding/user-profile'),
    );
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['first_name'] = firstName;
    if (middleName != null && middleName.isNotEmpty) {
      req.fields['middle_name'] = middleName;
    }
    req.fields['last_name'] = lastName;
    req.fields['age'] = age.toString();
    req.fields['country'] = country;
    req.fields['city'] = city;

    if (photoBytes != null && photoName != null) {
      req.files.add(http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: photoName,
      ));
    }

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    var body = jsonDecode(res.body);
    AppLogger.instance.api('POST', '/api/auth/onboarding/user-profile', res.statusCode, body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is Map && body.containsKey('success') && body['success'] == true) {
        body = body['data'] ?? body;
      }
    }
    return {'status': res.statusCode, 'body': body};
  }

  static Future<Map<String, dynamic>> saveSponsorProfile({
    required String token,
    required String companyName,
    required String companyDetails,
    String? targetAudience,
  }) async {
    final payload = <String, dynamic>{
      'company_name': companyName,
      'company_details': companyDetails,
      if (targetAudience != null && targetAudience.isNotEmpty) 'target_audience': targetAudience,
    };
    return _logged('POST', '/api/auth/onboarding/sponsor-profile', () => http.post(
      Uri.parse('$_base/api/auth/onboarding/sponsor-profile'),
      headers: _headers(token),
      body: jsonEncode(payload),
    ));
  }

  // ── APARTMENTS ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> getApartments(String token) async {
    final res = await _logged('GET', '/api/apartments', () => http.get(
      Uri.parse('$_base/api/apartments'),
      headers: _headers(token),
    ));
    // Unwrap paginated response: Laravel returns {data:[...], current_page, ...}
    if (res['status'] == 200 && res['body'] is Map && res['body']['data'] is List) {
      res['body'] = res['body']['data'];
    }
    return res;
  }

  static Future<Map<String, dynamic>> getApartment(String token, int id) async {
    return _logged('GET', '/api/apartments/$id', () => http.get(
      Uri.parse('$_base/api/apartments/$id'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> createApartment(
      String token, Map<String, String> fields) async {
    AppLogger.instance.info('API', 'POST /api/apartments', fields);
    final req = http.MultipartRequest('POST', Uri.parse('$_base/api/apartments'));
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
    final req = http.MultipartRequest('PUT', Uri.parse('$_base/api/apartments/$id'));
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
    return _logged('DELETE', '/api/apartments/$id', () => http.delete(
      Uri.parse('$_base/api/apartments/$id'),
      headers: _headers(token),
    ));
  }

  // ── CONTRACTS ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getContracts(String token) async {
    return _logged('GET', '/api/contracts', () => http.get(
      Uri.parse('$_base/api/contracts'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> getOwnerContracts(String token) async {
    return _logged('GET', '/api/contracts/owner', () => http.get(
      Uri.parse('$_base/api/contracts/owner'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> getOwners(String token) async {
    return _logged('GET', '/api/owners', () => http.get(
      Uri.parse('$_base/api/owners'),
      headers: _headers(token),
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
      Uri.parse('$_base/api/contracts'),
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
    return _logged('POST', '/api/contracts/$id/accept', () => http.post(
      Uri.parse('$_base/api/contracts/$id/accept'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> refuseContract(
      String token, int id, String reason) async {
    return _logged('POST', '/api/contracts/$id/refuse', () => http.post(
      Uri.parse('$_base/api/contracts/$id/refuse'),
      headers: _headers(token),
      body: jsonEncode({'reason': reason}),
    ));
  }

  static Future<Map<String, dynamic>> getAdminContracts(String token) async {
    return _logged('GET', '/api/admin/contracts', () => http.get(
      Uri.parse('$_base/api/admin/contracts'),
      headers: _headers(token),
    ));
  }

  // ── IDENTITY DOCUMENTS ──────────────────────────────────────

  static Future<Map<String, dynamic>> uploadIdentityDocuments({
    required String token,
    required List<Map<String, dynamic>> documents,
  }) async {
    AppLogger.instance.info('API', 'POST /api/identity/documents — count: ${documents.length}');
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/identity/documents'),
    );
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $token';
    for (int i = 0; i < documents.length; i++) {
      final doc = documents[i];
      final bytes = doc['bytes'] as List<int>;
      final type  = doc['type']  as String;
      req.files.add(http.MultipartFile.fromBytes(
        'documents[$i][file]',
        bytes,
        filename: '${type}_$i.jpg',
      ));
      req.fields['documents[$i][document_type]'] = type;
    }
    final streamed = await req.send();
    final res  = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);
    AppLogger.instance.api('POST', '/api/identity/documents', res.statusCode, body);
    return {'status': res.statusCode, 'body': body};
  }

  // ── SINGLE CONTRACT ─────────────────────────────────────────

  static Future<Map<String, dynamic>> getContract(
      String token, int id) async {
    return _logged('GET', '/api/contracts/$id', () => http.get(
      Uri.parse('$_base/api/contracts/$id'),
      headers: _headers(token),
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
      Uri.parse('$_base/api/contracts/$id'),
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
    return _logged('DELETE', '/api/contracts/$id', () => http.delete(
      Uri.parse('$_base/api/contracts/$id'),
      headers: _headers(token),
    ));
  }

  // ── TOKEN ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> refreshToken(String token) async {
    return _logged('POST', '/api/auth/token/refresh', () => http.post(
      Uri.parse('$_base/api/auth/token/refresh'),
      headers: _headers(token),
    ));
  }

  // ── USERS (Admin) ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUsers(String token) async {
    return _logged('GET', '/api/admin/users', () => http.get(
      Uri.parse('$_base/api/admin/users'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> createUser(
      String token, Map<String, dynamic> data) async {
    return _logged('POST', '/api/admin/users', () => http.post(
      Uri.parse('$_base/api/admin/users'),
      headers: _headers(token),
      body: jsonEncode(data),
    ));
  }

  static Future<Map<String, dynamic>> updateUser(
      String token, int id, Map<String, dynamic> data) async {
    return _logged('PUT', '/api/admin/users/$id', () => http.put(
      Uri.parse('$_base/api/admin/users/$id'),
      headers: _headers(token),
      body: jsonEncode(data),
    ));
  }

  static Future<Map<String, dynamic>> deleteUser(
      String token, int id) async {
    return _logged('DELETE', '/api/admin/users/$id', () => http.delete(
      Uri.parse('$_base/api/admin/users/$id'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> promoteToAdmin(
      String token, int id) async {
    return _logged('POST', '/api/admin/users/$id/promote', () => http.post(
      Uri.parse('$_base/api/admin/users/$id/promote'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> demoteFromAdmin(
      String token, int id) async {
    return _logged('POST', '/api/admin/users/$id/demote', () => http.post(
      Uri.parse('$_base/api/admin/users/$id/demote'),
      headers: _headers(token),
    ));
  }

  // ── FCM TOKEN ────────────────────────────────────────────────

  static Future<void> saveFcmToken(String token, String fcmToken) async {
    try {
      await _logged('POST', '/api/auth/fcm-token', () => http.post(
        Uri.parse('$_base/api/auth/fcm-token'),
        headers: _headers(token),
        body: jsonEncode({'fcm_token': fcmToken}),
      ));
    } catch (e) {
      AppLogger.instance.error('FCM', 'Failed to save FCM token: $e');
    }
  }

  // ── JOIN / LEAVE APARTMENT ───────────────────────────────────

  static Future<Map<String, dynamic>> joinApartment(
      String token, int id) async {
    return _logged('POST', '/api/apartments/$id/join', () => http.post(
      Uri.parse('$_base/api/apartments/$id/join'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> leaveApartment(
      String token, int id) async {
    return _logged('POST', '/api/apartments/$id/leave', () => http.post(
      Uri.parse('$_base/api/apartments/$id/leave'),
      headers: _headers(token),
    ));
  }

  // ── TENANT CONTRACTS ─────────────────────────────────────────

  static Future<Map<String, dynamic>> getMyContract(
      String token, int apartmentId) async {
    return _logged('GET', '/api/apartments/$apartmentId/contracts', () => http.get(
      Uri.parse('$_base/api/apartments/$apartmentId/contracts'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> deleteMyContract(
      String token, int apartmentId) async {
    return _logged('DELETE', '/api/apartments/$apartmentId/contracts', () => http.delete(
      Uri.parse('$_base/api/apartments/$apartmentId/contracts'),
      headers: _headers(token),
    ));
  }

  // ── NOTIFICATIONS ────────────────────────────────────────────

  static Future<Map<String, dynamic>> getNotifications(String token) async {
    return _logged('GET', '/api/notifications', () => http.get(
      Uri.parse('$_base/api/notifications'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> markNotificationRead(
      String token, int id) async {
    return _logged('POST', '/api/notifications/$id/read', () => http.post(
      Uri.parse('$_base/api/notifications/$id/read'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> deleteAllNotifications(
      String token) async {
    return _logged('DELETE', '/api/notifications', () => http.delete(
      Uri.parse('$_base/api/notifications'),
      headers: _headers(token),
    ));
  }

  // ── OCR / ID VERIFICATION DATA ────────────────────────────

  static Future<Map<String, dynamic>> saveOcrData(
      String token, Map<String, dynamic> ocrData) async {
    return _logged('POST', '/api/auth/profile/ocr', () => http.post(
      Uri.parse('$_base/api/auth/profile/ocr'),
      headers: _headers(token),
      body: jsonEncode(ocrData),
    ));
  }

  // ── PAYMENT ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPaymentOrders(String token) async {
    return _logged('GET', '/api/payment/orders', () => http.get(
      Uri.parse('$_base/api/payment/orders'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> getPaymentOrder(String token, int id) async {
    return _logged('GET', '/api/payment/orders/$id', () => http.get(
      Uri.parse('$_base/api/payment/orders/$id'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> getTransactions(String token) async {
    return _logged('GET', '/api/payment/transactions', () => http.get(
      Uri.parse('$_base/api/payment/transactions'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> submitRefundRequest(
      String token, int paymentOrderId, String reason) async {
    return _logged('POST', '/api/payment/refund-requests', () => http.post(
      Uri.parse('$_base/api/payment/refund-requests'),
      headers: _headers(token),
      body: jsonEncode({'payment_order_id': paymentOrderId, 'reason': reason}),
    ));
  }

  static Future<Map<String, dynamic>> getRefundRequests(String token) async {
    return _logged('GET', '/api/admin/refund-requests', () => http.get(
      Uri.parse('$_base/api/admin/refund-requests'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> approveRefund(String token, int id) async {
    return _logged('POST', '/api/admin/refund-requests/$id/approve', () => http.post(
      Uri.parse('$_base/api/admin/refund-requests/$id/approve'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> rejectRefund(
      String token, int id, String reason) async {
    return _logged('POST', '/api/admin/refund-requests/$id/reject', () => http.post(
      Uri.parse('$_base/api/admin/refund-requests/$id/reject'),
      headers: _headers(token),
      body: jsonEncode({'reason': reason}),
    ));
  }

  // ── PAYMENT RETRY ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> retryPaymentLink(
      String token, int orderId) async {
    return _logged('POST', '/api/payment/orders/$orderId/retry', () => http.post(
      Uri.parse('$_base/api/payment/orders/$orderId/retry'),
      headers: _headers(token),
    ));
  }

  // ── APARTMENT MEMBERS ─────────────────────────────────────────

  static Future<Map<String, dynamic>> getApartmentMembers(
      String token, int apartmentId) async {
    return _logged('GET', '/api/apartments/$apartmentId/members', () => http.get(
      Uri.parse('$_base/api/apartments/$apartmentId/members'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> removeApartmentMember(
      String token, int apartmentId, int userId) async {
    return _logged('POST', '/api/apartments/$apartmentId/remove-member', () => http.post(
      Uri.parse('$_base/api/apartments/$apartmentId/remove-member'),
      headers: _headers(token),
      body: jsonEncode({'user_id': userId}),
    ));
  }

  static Future<Map<String, dynamic>> addApartmentMember(
      String token, int apartmentId, String email) async {
    return _logged('POST', '/api/apartments/$apartmentId/add-member', () => http.post(
      Uri.parse('$_base/api/apartments/$apartmentId/add-member'),
      headers: _headers(token),
      body: jsonEncode({'email': email}),
    ));
  }

  // ── ADMIN APARTMENT VERIFICATION ─────────────────────────────

  static Future<Map<String, dynamic>> verifyApartment(
      String token, int id) async {
    return _logged('POST', '/api/admin/apartments/$id/verify', () => http.post(
      Uri.parse('$_base/api/admin/apartments/$id/verify'),
      headers: _headers(token),
    ));
  }

  static Future<Map<String, dynamic>> refuseApartment(
      String token, int id, {String? reason}) async {
    return _logged('POST', '/api/admin/apartments/$id/refuse', () => http.post(
      Uri.parse('$_base/api/admin/apartments/$id/refuse'),
      headers: _headers(token),
      body: jsonEncode({'reason': reason}),
    ));
  }
}
