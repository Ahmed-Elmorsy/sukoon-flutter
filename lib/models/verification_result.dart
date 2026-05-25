class ValidationSection {
  final bool idValid;

  const ValidationSection({required this.idValid});

  factory ValidationSection.fromJson(Map<String, dynamic> json) =>
      ValidationSection(idValid: json['id_valid'] == true);
}

class FaceMatchSection {
  final bool passed;

  const FaceMatchSection({required this.passed});

  factory FaceMatchSection.fromJson(Map<String, dynamic> json) =>
      FaceMatchSection(passed: json['passed'] == true);
}

class LivenessSection {
  final bool passed;

  const LivenessSection({required this.passed});

  factory LivenessSection.fromJson(Map<String, dynamic> json) =>
      LivenessSection(passed: json['passed'] == true);
}

class OcrFrontSection {
  final String name;
  final String address;
  final String idNumber;
  final String birthDate;

  const OcrFrontSection({
    this.name = '',
    this.address = '',
    this.idNumber = '',
    this.birthDate = '',
  });

  factory OcrFrontSection.fromJson(Map<String, dynamic> json) =>
      OcrFrontSection(
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        idNumber: json['id_number']?.toString() ?? '',
        birthDate: json['birth_date']?.toString() ?? '',
      );

  String get birthDateFormatted {
    if (birthDate.length == 8) {
      return '${birthDate.substring(6, 8)}/${birthDate.substring(4, 6)}/${birthDate.substring(0, 4)}';
    }
    return birthDate;
  }
}

class OcrBackSection {
  final String profession;
  final String gender;
  final String religion;
  final String maritalStatus;
  final String expiryDate;
  final String issueDate;

  const OcrBackSection({
    this.profession = '',
    this.gender = '',
    this.religion = '',
    this.maritalStatus = '',
    this.expiryDate = '',
    this.issueDate = '',
  });

  factory OcrBackSection.fromJson(Map<String, dynamic> json) =>
      OcrBackSection(
        profession: json['profession']?.toString() ?? '',
        gender: json['gender']?.toString() ?? '',
        religion: json['religion']?.toString() ?? '',
        maritalStatus: json['marital_status']?.toString() ?? '',
        expiryDate: json['expiry_date']?.toString() ?? '',
        issueDate: json['issue_date']?.toString() ?? '',
      );
}

class VerificationResult {
  final String requestId;
  final bool success;
  final ValidationSection? validation;
  final FaceMatchSection? faceMatch;
  final LivenessSection? liveness;
  final OcrFrontSection? ocrFront;
  final OcrBackSection? ocrBack;
  final bool idNumbersMatch;

  const VerificationResult({
    required this.requestId,
    required this.success,
    this.validation,
    this.faceMatch,
    this.liveness,
    this.ocrFront,
    this.ocrBack,
    this.idNumbersMatch = false,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    final sections =
        (json['sections'] as Map<String, dynamic>?) ?? {};
    // /result endpoint returns `status: "completed"`; saved files use `success: true`
    final isSuccess = json['success'] == true ||
        json['status']?.toString() == 'completed';
    return VerificationResult(
      requestId: json['request_id']?.toString() ?? '',
      success: isSuccess,
      validation: sections.containsKey('validation')
          ? ValidationSection.fromJson(
              sections['validation'] as Map<String, dynamic>)
          : null,
      faceMatch: sections.containsKey('face_match')
          ? FaceMatchSection.fromJson(
              sections['face_match'] as Map<String, dynamic>)
          : null,
      liveness: sections.containsKey('liveness')
          ? LivenessSection.fromJson(
              sections['liveness'] as Map<String, dynamic>)
          : null,
      ocrFront: sections.containsKey('ocr_front')
          ? OcrFrontSection.fromJson(
              sections['ocr_front'] as Map<String, dynamic>)
          : null,
      ocrBack: sections.containsKey('ocr_back')
          ? OcrBackSection.fromJson(
              sections['ocr_back'] as Map<String, dynamic>)
          : null,
      idNumbersMatch: sections['id_numbers_match'] == true,
    );
  }
}

class LivenessCheckResult {
  final bool passed;
  final String? error;

  const LivenessCheckResult({required this.passed, this.error});

  factory LivenessCheckResult.fromJson(Map<String, dynamic> json) {
    final liveness =
        (json['liveness'] as Map<String, dynamic>?) ?? {};
    return LivenessCheckResult(
      passed: liveness['passed'] == true,
      error: json['error'] as String?,
    );
  }
}
