class ProfileData {
  ProfileData._();
  static final ProfileData instance = ProfileData._();

  // Step 2 — CompleteProfileScreen
  String firstName  = '';
  String middleName = '';
  String lastName   = '';
  String dob        = '';
  String country    = '';
  String city       = '';

  // Step 2 — derived age from dob
  int get age {
    if (dob.isEmpty) return 18;
    try {
      final parts = dob.split(' / ');
      final year  = int.parse(parts[2]);
      final now   = DateTime.now().year;
      return (now - year).clamp(15, 120);
    } catch (_) {
      return 18;
    }
  }

  // Step 3 — AboutYourselfScreen
  String rentalType    = '';   // 'student' | 'employee' | 'other' | 'prefer_not_to_say'
  String university    = '';
  String faculty       = '';
  String company       = '';
  String jobTitle      = '';

  void clear() {
    firstName  = '';
    middleName = '';
    lastName   = '';
    dob        = '';
    country    = '';
    city       = '';
    rentalType = '';
    university = '';
    faculty    = '';
    company    = '';
    jobTitle   = '';
  }
}
