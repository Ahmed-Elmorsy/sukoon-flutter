import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/verification_result.dart';

class IdVerificationService {
  static String get baseUrl => '${AppConfig.apiBaseUrl}/api/ml';

  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<LivenessCheckResult> checkLiveness(Uint8List selfieBytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/liveness'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'selfie',
          selfieBytes,
          filename: 'selfie.jpg',
        ),
      );
      final streamed =
          await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 120));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return LivenessCheckResult.fromJson(json);
      }
      return LivenessCheckResult(
          passed: false, error: 'Server error (${response.statusCode}): ${response.body}');
    } catch (e) {
      return LivenessCheckResult(passed: false, error: e.toString());
    }
  }

  Future<String?> submitVerification({
    required Uint8List frontBytes,
    required Uint8List backBytes,
    required Uint8List selfieBytes,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/verify'),
      );
      request.files.addAll([
        http.MultipartFile.fromBytes('front', frontBytes,
            filename: 'front.jpg'),
        http.MultipartFile.fromBytes('back', backBytes,
            filename: 'back.jpg'),
        http.MultipartFile.fromBytes('selfie', selfieBytes,
            filename: 'selfie.jpg'),
      ]);
      final streamed =
          await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 120));
      if (response.statusCode == 202) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['request_id'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Polls indefinitely until the backend reports `completed` or `failed`.
  /// Network errors are swallowed and retried — the loop only exits when the
  /// pipeline actually finishes. Caller can abort by simply ignoring the future
  /// (e.g. when the user navigates away).
  Future<VerificationResult?> pollResult(
    String requestId, {
    Duration interval = const Duration(seconds: 2),
  }) async {
    while (true) {
      try {
        final response = await http
            .get(Uri.parse('$baseUrl/result/$requestId'))
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          final json =
              jsonDecode(response.body) as Map<String, dynamic>;
          final status = json['status'] as String?;
          if (status == 'completed' || status == 'failed') {
            return VerificationResult.fromJson(json);
          }
        } else if (response.statusCode == 404) {
          // Job no longer exists on the server — nothing left to wait for.
          return null;
        }
      } catch (_) {
        // Network hiccup — keep trying.
      }
      await Future.delayed(interval);
    }
  }
}
