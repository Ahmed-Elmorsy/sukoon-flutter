import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_api.dart';

class PaymentsApiService {
  static Future<Map<String, dynamic>> getPaymentOrders(String token) async {
    return apiLogged('GET', '/api/payment/orders', () => http.get(
      Uri.parse('$apiBase/api/payment/orders'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> getPaymentOrder(String token, int id) async {
    return apiLogged('GET', '/api/payment/orders/$id', () => http.get(
      Uri.parse('$apiBase/api/payment/orders/$id'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> getTransactions(String token) async {
    return apiLogged('GET', '/api/payment/transactions', () => http.get(
      Uri.parse('$apiBase/api/payment/transactions'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> submitRefundRequest(
      String token, int paymentOrderId, String reason) async {
    return apiLogged('POST', '/api/payment/refund-requests', () => http.post(
      Uri.parse('$apiBase/api/payment/refund-requests'),
      headers: apiHeaders(token),
      body: jsonEncode({'payment_order_id': paymentOrderId, 'reason': reason}),
    ));
  }

  static Future<Map<String, dynamic>> getRefundRequests(String token) async {
    return apiLogged('GET', '/api/admin/refund-requests', () => http.get(
      Uri.parse('$apiBase/api/admin/refund-requests'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> approveRefund(String token, int id) async {
    return apiLogged('POST', '/api/admin/refund-requests/$id/approve', () => http.post(
      Uri.parse('$apiBase/api/admin/refund-requests/$id/approve'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> rejectRefund(
      String token, int id, String reason) async {
    return apiLogged('POST', '/api/admin/refund-requests/$id/reject', () => http.post(
      Uri.parse('$apiBase/api/admin/refund-requests/$id/reject'),
      headers: apiHeaders(token),
      body: jsonEncode({'reason': reason}),
    ));
  }

  static Future<Map<String, dynamic>> retryPaymentLink(
      String token, int orderId) async {
    return apiLogged('POST', '/api/payment/orders/$orderId/retry', () => http.post(
      Uri.parse('$apiBase/api/payment/orders/$orderId/retry'),
      headers: apiHeaders(token),
    ));
  }

  static Future<Map<String, dynamic>> triggerPaymobWebhook(
      String hmac, Map<String, dynamic> payload) async {
    return apiLogged('POST', '/api/payments/webhook/paymob', () => http.post(
      Uri.parse('$apiBase/api/payments/webhook/paymob?hmac=$hmac'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    ));
  }
}

