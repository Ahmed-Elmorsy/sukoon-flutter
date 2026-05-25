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
  }
}
