import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../app_logger.dart';

final String apiBase = AppConfig.apiBaseUrl;

Map<String, String> apiHeaders(String token) => {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

Future<Map<String, dynamic>> apiLogged(
    String method, String path, Future<http.Response> Function() call) async {
  try {
    AppLogger.instance.info('API', '$method $path');
    final res = await call().timeout(const Duration(seconds: 15));
    var body = jsonDecode(res.body);
    AppLogger.instance.api(method, path, res.statusCode, body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is Map &&
          body.containsKey('success') &&
          body['success'] == true) {
        body = body['data'] ?? body;
      }
    }
    return {'status': res.statusCode, 'body': body};
  } on Exception catch (e) {
    AppLogger.instance.error('API', '$method $path → $e');
    return {
      'status': 0,
      'body': {'error': e.toString()}
    };
  }
}
