import 'package:http/http.dart' as http;
import 'base_api.dart';

class NotificationsApiService {
  static Future<Map<String, dynamic>> getNotifications(String token) async {
    return apiLogged('GET', '/api/notifications', () => http.get(
      Uri.parse('$apiBase/api/notifications'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> markNotificationRead(
      String token, dynamic id) async {
    return apiLogged('POST', '/api/notifications/$id/read', () => http.post(
      Uri.parse('$apiBase/api/notifications/$id/read'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> markAllNotificationsRead(
      String token) async {
    return apiLogged('POST', '/api/notifications/read-all', () => http.post(
      Uri.parse('$apiBase/api/notifications/read-all'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> deleteAllNotifications(
      String token) async {
    return apiLogged('DELETE', '/api/notifications', () => http.delete(
      Uri.parse('$apiBase/api/notifications'),
      headers: apiHeaders(token),
    ));
  }
}

