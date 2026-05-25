import '../models/verification_result.dart';

class VerificationSession {
  static VerificationResult? result;

  static bool get isFullyVerified =>
      result != null &&
      result!.success == true &&
      (result!.validation?.idValid ?? false) &&
      (result!.liveness?.passed ?? false);
      // face_match excluded — unreliable with small ID photo crops

  static bool get isDocumentSubmitted => result != null;

  static bool get isFaceVerified => result?.faceMatch?.passed ?? false;

  static bool get isLivenessVerified => result?.liveness?.passed ?? false;

  static void clear() => result = null;
}
