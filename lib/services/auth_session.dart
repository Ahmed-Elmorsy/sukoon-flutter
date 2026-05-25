class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  String language = 'en'; // 'en' | 'ar'
  String token   = '';
  int    userId  = 0;
  String role    = '';   // 'renter' | 'owner' | 'admin'
  String name    = '';   // first_name from profile
  String email   = '';
  String phone   = '';
  String gender  = '';
  String dob     = '';
  String city    = '';
  String country = '';

  // OCR / ID verification fields
  String idNumber      = '';
  String birthDate     = '';
  String address       = '';
  String profession    = '';
  String religion      = '';
  String maritalStatus = '';
  String idExpiryDate  = '';
  String idIssueDate   = '';
  bool   idVerified    = false;

  // Payout fields for Owner
  String payoutInfo   = '';
  String payoutType   = ''; // 'wallet' | 'bank'
  String payoutNumber = '';
  bool hasPaidPlatformFee = false;

  // Identity Document fields
  String identityDocStatus          = 'none'; // 'none' | 'pending' | 'approved' | 'rejected'
  String identityDocType            = '';     // 'national_id' | 'passport' | 'other'
  String identityDocNumber          = '';
  String identityDocRejectionReason = '';

  bool get isLoggedIn => token.isNotEmpty;

  void save({
    required String token,
    required int    userId,
    required String role,
    required String name,
    required String email,
    String phone   = '',
    String gender  = '',
    String dob     = '',
    String city    = '',
    String country = '',
    String idNumber      = '',
    String birthDate     = '',
    String address       = '',
    String profession    = '',
    String religion      = '',
    String maritalStatus = '',
    String idExpiryDate  = '',
    String idIssueDate   = '',
    bool   idVerified    = false,
    String payoutInfo    = '',
    String payoutType    = '',
    String payoutNumber  = '',
    bool hasPaidPlatformFee = false,
    String identityDocStatus = 'none',
    String identityDocType = '',
    String identityDocNumber = '',
    String identityDocRejectionReason = '',
  }) {
    this.token   = token;
    this.userId  = userId;
    this.role    = role;
    this.name    = name;
    this.email   = email;
    this.phone   = phone;
    this.gender  = gender;
    this.dob     = dob;
    this.city    = city;
    this.country = country;
    this.idNumber      = idNumber;
    this.birthDate     = birthDate;
    this.address       = address;
    this.profession    = profession;
    this.religion      = religion;
    this.maritalStatus = maritalStatus;
    this.idExpiryDate  = idExpiryDate;
    this.idIssueDate   = idIssueDate;
    this.idVerified    = idVerified;
    this.payoutInfo    = payoutInfo;
    this.payoutType    = payoutType;
    this.payoutNumber  = payoutNumber;
    this.hasPaidPlatformFee = hasPaidPlatformFee;
    this.identityDocStatus = identityDocStatus;
    this.identityDocType = identityDocType;
    this.identityDocNumber = identityDocNumber;
    this.identityDocRejectionReason = identityDocRejectionReason;
  }

  void updateFromMe(Map<String, dynamic> body) {
    phone = body['phone']?.toString() ?? '';
    gender = body['gender']?.toString() ?? '';
    payoutInfo = body['payout_info']?.toString() ?? '';
    payoutType = body['payout_type']?.toString() ?? '';
    payoutNumber = body['payout_number']?.toString() ?? '';
    hasPaidPlatformFee = body['has_paid_platform_fee'] == true;

    final profile = body['profile'] as Map<String, dynamic>? ?? {};
    name = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
    dob = profile['age']?.toString() ?? '';
    city = profile['city']?.toString() ?? '';
    country = profile['country']?.toString() ?? '';

    final idDoc = body['identity_document'] as Map<String, dynamic>?;
    if (idDoc != null) {
      identityDocStatus = idDoc['status']?.toString() ?? 'none';
      identityDocType = idDoc['type']?.toString() ?? '';
      identityDocNumber = idDoc['document_number']?.toString() ?? '';
      identityDocRejectionReason = idDoc['rejection_reason']?.toString() ?? '';
      idVerified = idDoc['status'] == 'approved' || idDoc['is_verified'] == true;
      
      // Also map fields extracted from OCR if present
      if (idDoc['ocr_data'] is Map) {
        final ocr = idDoc['ocr_data'] as Map<String, dynamic>;
        idNumber = ocr['id_number']?.toString() ?? idNumber;
        birthDate = ocr['birth_date']?.toString() ?? birthDate;
        address = ocr['address']?.toString() ?? address;
        profession = ocr['profession']?.toString() ?? profession;
        religion = ocr['religion']?.toString() ?? religion;
        maritalStatus = ocr['marital_status']?.toString() ?? maritalStatus;
        idExpiryDate = ocr['expiry_date']?.toString() ?? idExpiryDate;
        idIssueDate = ocr['issue_date']?.toString() ?? idIssueDate;
      }
    } else {
      identityDocStatus = 'none';
      identityDocType = '';
      identityDocNumber = '';
      identityDocRejectionReason = '';
      idVerified = body['is_verified'] == true;
    }
  }

  void clear() {
    token   = '';
    userId  = 0;
    role    = '';
    name    = '';
    email   = '';
    phone   = '';
    gender  = '';
    dob     = '';
    city    = '';
    country = '';
    idNumber      = '';
    birthDate     = '';
    address       = '';
    profession    = '';
    religion      = '';
    maritalStatus = '';
    idExpiryDate  = '';
    idIssueDate   = '';
    idVerified    = false;
    payoutInfo    = '';
    payoutType    = '';
    payoutNumber  = '';
    hasPaidPlatformFee = false;
    identityDocStatus = 'none';
    identityDocType = '';
    identityDocNumber = '';
    identityDocRejectionReason = '';
  }
}
