import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../app_logger.dart';
import 'base_api.dart';

class ProfileApiService {
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
    return apiLogged('POST', '/api/auth/onboarding/rental-profile', () => http.post(
      Uri.parse('$apiBase/api/auth/onboarding/rental-profile'),
      headers: apiHeaders(token),
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
      Uri.parse('$apiBase/api/auth/onboarding/user-profile'),
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
    return apiLogged('POST', '/api/auth/onboarding/sponsor-profile', () => http.post(
      Uri.parse('$apiBase/api/auth/onboarding/sponsor-profile'),
      headers: apiHeaders(token),
      body: jsonEncode(payload),
    ));
  }

  static Future<Map<String, dynamic>> uploadIdentityDocuments({
    required String token,
    required List<Map<String, dynamic>> documents,
  }) async {
    AppLogger.instance.info('API', 'POST /api/identity/documents — count: ${documents.length}');
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBase/api/identity/documents'),
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

  static Future<Map<String, dynamic>> saveOcrData(
      String token, Map<String, dynamic> ocrData) async {
    return apiLogged('POST', '/api/auth/profile/ocr', () => http.post(
      Uri.parse('$apiBase/api/auth/profile/ocr'),
      headers: apiHeaders(token),
      body: jsonEncode(ocrData),
    ));
  }

  static Future<Map<String, dynamic>> updatePayoutInfo({
    required String token,
    String? payoutInfo,
    String? payoutType,
    String? payoutNumber,
  }) async {
    final payload = <String, dynamic>{
      if (payoutInfo != null) 'payout_info': payoutInfo,
      if (payoutType != null) 'payout_type': payoutType,
      if (payoutNumber != null) 'payout_number': payoutNumber,
    };
    return apiLogged('POST', '/api/owner/payout', () => http.post(
      Uri.parse('$apiBase/api/owner/payout'),
      headers: apiHeaders(token),
      body: jsonEncode(payload),
    ));
  }

  static Future<Map<String, dynamic>> uploadOwnerIdentityDocument({
    required String token,
    required String type,
    required String documentNumber,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    AppLogger.instance.info('API', 'POST /api/owner/identity-document');
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBase/api/owner/identity-document'),
    );
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['type'] = type;
    req.fields['document_number'] = documentNumber;
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);
    AppLogger.instance.api('POST', '/api/owner/identity-document', res.statusCode, body);
    return {'status': res.statusCode, 'body': body};
  }

  static Future<Map<String, dynamic>> uploadTenantIdentityDocument({
    required String token,
    required String type,
    required String documentNumber,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    AppLogger.instance.info('API', 'POST /api/tenant/identity-document');
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBase/api/tenant/identity-document'),
    );
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['type'] = type;
    req.fields['document_number'] = documentNumber;
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);
    AppLogger.instance.api('POST', '/api/tenant/identity-document', res.statusCode, body);
    return {'status': res.statusCode, 'body': body};
  }

  static Future<Map<String, dynamic>> uploadTenantContract({
    required String token,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    AppLogger.instance.info('API', 'POST /api/tenant/contracts');
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBase/api/tenant/contracts'),
    );
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $token';
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);
    AppLogger.instance.api('POST', '/api/tenant/contracts', res.statusCode, body);
    return {'status': res.statusCode, 'body': body};
  }

  static Future<Map<String, dynamic>> getTenantPaymentStatus(String token) async {
    return apiLogged('GET', '/api/tenant/payment-status', () => http.get(
      Uri.parse('$apiBase/api/tenant/payment-status'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> requestTenantRefund(String token) async {
    return apiLogged('POST', '/api/tenant/refund', () => http.post(
      Uri.parse('$apiBase/api/tenant/refund'),
      headers: apiHeaders(token),
    ));
  }
}
