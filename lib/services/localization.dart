import 'auth_session.dart';

class S {
  static String text(String key) {
    final isAr = AuthSession.instance.language == 'ar';
    return isAr ? (_ar[key] ?? _en[key] ?? key) : (_en[key] ?? key);
  }

  static bool get isAr => AuthSession.instance.language == 'ar';

  static final Map<String, String> _en = {
    // Language Screen
    'trusted_platform': 'Your trusted rental platform',
    'choose_lang': 'Choose Your Language',
    'select_lang_pref': 'Select the language you prefer',
    
    // Role selection
    'who_are_you': 'Who Are You?',
    'choose_role_skoon': 'Choose how you want to use Skoon',
    'i_am_renter': 'I am a Renter',
    'renter_desc': 'Looking for a property to rent',
    'i_am_owner': 'I am an Owner',
    'owner_desc': 'List and manage your properties',
    'i_am_sponsor': 'I am a Sponsor',
    'sponsor_desc': 'Sponsor apartments and manage promotions',
    'continue': 'Continue',

    // Create Account
    'create_account': 'Create Account',
    'step_1_3': 'Step 1 of 3',
    'mobile_number': 'Mobile Number',
    'email_address': 'Email Address',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'gender': 'Gender',
    'male': 'Male',
    'female': 'Female',
    'terms_privacy': 'By continuing you agree to our Terms & Privacy Policy',
    'already_have_acc': 'Already have an account? Sign In',

    // OTP
    'verify_phone': 'Verify Phone',
    'verify_your_num': 'Verify Your Number',
    'otp_desc': 'We\'ve sent a 6-digit code to your mobile number. Please enter it below.',
    'didnt_receive_otp': 'Didn\'t receive the code? Resend in',
    'verify_continue': 'Verify & Continue',

    // Complete Profile
    'complete_profile': 'Complete Profile',
    'step_2_3': 'Step 2 of 3',
    'add_photo': 'Add Photo',
    'first_name': 'First Name',
    'middle_name': 'Middle Name',
    'last_name': 'Last Name',
    'dob': 'Date of Birth',
    'country': 'Country',
    'city': 'City',
    'save_continue': 'Save & Continue',

    // About Yourself
    'tell_us_about': 'Tell Us About Yourself',
    'about_desc': 'This helps us personalize your experience and find the right rental options for you.',
    'i_am_a': 'I am a:',
    'employee': 'Employee',
    'student': 'Student',
    'other': 'Other',
    'prefer_not_say': 'Prefer not to say',
    'emp_details': 'Employee Details',
    'job_title': 'Job Title',
    'company_opt': 'Company (Optional)',
    'std_details': 'Student Details',
    'university': 'University',
    'faculty': 'Faculty',

    // Identity Photo
    'id_verification': 'Identity Verification',
    'step_3_3': 'Step 3 of 3',
    'take_selfie': 'Take a Selfie',
    'selfie_desc': 'Position your face within the frame and ensure good lighting before taking your photo.',
    'align_face': 'Align face here',
    'take_photo': 'Take Photo',

    // Document Verification
    'doc_verification': 'Document Verification',
    'verify_identity': 'Verify Your Identity',
    'doc_desc': 'Upload a government-issued ID to complete your verification. Your data is encrypted and secure.',
    'national_id': 'National ID',
    'passport': 'Passport',
    'drivers_license': 'Driver\'s License',
    'front_side': 'Front Side',
    'back_side': 'Back Side',
    'tap_upload_photo': 'Tap to upload or take photo',
    'doc_encrypted_note': 'Your documents are encrypted and stored securely',
    'submit_docs': 'Submit Documents',
    
    // Payments Flow
    'payment_method': 'Payment Method',
    'payment_method_desc': 'Choose how you want to pay for your rent',
    'credit_debit_card': 'Credit / Debit Card',
    'card_desc': 'Pay securely with Visa or Mastercard',
    'digital_wallet': 'Digital Wallet (InstaPay / Mobile Wallet)',
    'wallet_desc': 'Transfer via InstaPay or Vodafone Cash',
    'total_breakdown': 'Total Breakdown',
    'card_number': 'Card Number',
    'card_holder': 'Card Holder Name',
    'expiry_date_pay': 'Expiry Date',
    'cvv': 'CVV',
    'pay_now_btn': 'Pay',
    'wallet_instructions': 'Please transfer the exact amount to the following wallet / InstaPay address:',
    'wallet_number': 'Wallet / InstaPay Address',
    'upload_receipt': 'Upload Transfer Receipt',
    'receipt_desc': 'Upload a screenshot of the transfer confirmation receipt',
    'submit_payment': 'Submit Payment Verification',
    'payment_success': 'Payment Success!',
    'payment_success_desc': 'Your payment has been successfully processed. The owner has been notified.',
    'view_receipt': 'View Receipt',
    'go_to_dashboard': 'Go to Dashboard',

    // Payments Screen
    'back': 'Back',
    'payments': 'Payments',
    'orders': 'Orders',
    'transactions': 'Transactions',
    'no_orders': 'No payment orders yet',
    'no_transactions': 'No transactions yet',
    'order_no': 'Order',
    'created': 'Created',
    'expires': 'Expires',
    'pay_now': 'Pay Now',
    'generate_link': 'Generate Payment Link',
    'request_refund': 'Request Refund',
    'refund': 'Refund',
    'payment': 'Payment',
    'pending': 'Pending',
    'paid': 'Paid',
    'success': 'Success',
    'refunded': 'Refunded',
    'failed': 'Failed',
  };

  static final Map<String, String> _ar = {
    // Language Screen
    'trusted_platform': 'حاضنتك الموثوقة للإيجار',
    'choose_lang': 'اختر اللغة',
    'select_lang_pref': 'حدد اللغة التي تفضلها',

    // Role selection
    'who_are_you': 'من أنت؟',
    'choose_role_skoon': 'اختر كيف تريد استخدام Skoon',
    'i_am_renter': 'أنا مستأجر',
    'renter_desc': 'أبحث عن شقة للإيجار',
    'i_am_owner': 'أنا مالك',
    'owner_desc': 'أعرض وأدير عقاراتي',
    'i_am_sponsor': 'أنا راعي',
    'sponsor_desc': 'رعاية الشقق وإدارة الترويج',
    'continue': 'متابعة',

    // Create Account
    'create_account': 'إنشاء حساب',
    'step_1_3': 'الخطوة ١ من ٣',
    'mobile_number': 'رقم الهاتف',
    'email_address': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'confirm_password': 'تأكيد كلمة المرور',
    'gender': 'النوع',
    'male': 'ذكر',
    'female': 'أنثى',
    'terms_privacy': 'بالاستمرار أنت توافق على الشروط وسياسة الخصوصية',
    'already_have_acc': 'لديك حساب بالفعل؟ تسجيل الدخول',

    // OTP
    'verify_phone': 'تأكيد الهاتف',
    'verify_your_num': 'أكد رقمك',
    'otp_desc': 'أرسلنا كود مكون من ٦ أرقام إلى هاتفك. برجاء إدخال الكود بالأسفل.',
    'didnt_receive_otp': 'لم تستلم الكود؟ إعادة الإرسال خلال',
    'verify_continue': 'تأكيد ومتابعة',

    // Complete Profile
    'complete_profile': 'إكمال الملف',
    'step_2_3': 'الخطوة ٢ من ٣',
    'add_photo': 'إضافة صورة',
    'first_name': 'الاسم الأول',
    'middle_name': 'الاسم الأوسط',
    'last_name': 'اسم العائلة',
    'dob': 'تاريخ الميلاد',
    'country': 'الدولة',
    'city': 'المدينة',
    'save_continue': 'حفظ ومتابعة',

    // About Yourself
    'tell_us_about': 'عرفنا بنفسك',
    'about_desc': 'يساعدنا هذا في تخصيص تجربتك والعثور على خيارات الإيجار المناسبة لك.',
    'i_am_a': 'أنا:',
    'employee': 'موظف',
    'student': 'طالب',
    'other': 'أخرى',
    'prefer_not_say': 'أفضل عدم الإجابة',
    'emp_details': 'بيانات الموظف',
    'job_title': 'المسمى الوظيفي',
    'company_opt': 'الشركة (اختياري)',
    'std_details': 'بيانات الطالب',
    'university': 'الجامعة',
    'faculty': 'الكلية',

    // Identity Photo
    'id_verification': 'التحقق من الهوية',
    'step_3_3': 'الخطوة ٣ من ٣',
    'take_selfie': 'التقط صورة شخصية',
    'selfie_desc': 'ضع وجهك داخل الإطار وتأكد من الإضاءة الجيدة قبل التقاط الصورة.',
    'align_face': 'ضع وجهك هنا',
    'take_photo': 'التقاط صورة',

    // Document Verification
    'doc_verification': 'تأكيد المستندات',
    'verify_identity': 'تحقق من هويتك',
    'doc_desc': 'ارفع بطاقة هوية حكومية لإكمال التحقق. بياناتك مشفرة وآمنة.',
    'national_id': 'بطاقة',
    'passport': 'جواز سفر',
    'drivers_license': 'رخصة قيادة',
    'front_side': 'الوجه الأمامي',
    'back_side': 'الوجه الخلفي',
    'tap_upload_photo': 'اضغط للرفع أو التقاط صورة',
    'doc_encrypted_note': 'مستنداتك مشفرة ومحفوظة بأمان',
    'submit_docs': 'إرسال المستندات',

    // Payments Flow
    'payment_method': 'طريقة الدفع',
    'payment_method_desc': 'اختر طريقة دفع الإيجار',
    'credit_debit_card': 'بطاقة الائتمان / الخصم',
    'card_desc': 'ادفع بأمان باستخدام فيزا أو ماستركارد',
    'digital_wallet': 'المحافظ الإلكترونية (إنستاباي / فودافون كاش)',
    'wallet_desc': 'التحويل عبر إنستاباي أو المحافظ الإلكترونية للهاتف المحمول',
    'total_breakdown': 'تفاصيل المبلغ الإجمالي',
    'card_number': 'رقم البطاقة',
    'card_holder': 'اسم صاحب البطاقة',
    'expiry_date_pay': 'تاريخ الانتهاء',
    'cvv': 'رمز التحقق (CVV)',
    'pay_now_btn': 'ادفع',
    'wallet_instructions': 'يرجى تحويل المبلغ بدقة إلى المحفظة أو عنوان إنستاباي التالي:',
    'wallet_number': 'رقم المحفظة / عنوان إنستاباي',
    'upload_receipt': 'رفع إيصال التحويل',
    'receipt_desc': 'قم برفع لقطة شاشة لإيصال تأكيد التحويل',
    'submit_payment': 'إرسال تأكيد الدفع',
    'payment_success': 'تم الدفع بنجاح!',
    'payment_success_desc': 'تمت معالجة دفعتك بنجاح. تم إشعار المالك.',
    'view_receipt': 'عرض الإيصال',
    'go_to_dashboard': 'الذهاب للرئيسية',

    // Payments Screen
    'back': 'رجوع',
    'payments': 'المدفوعات',
    'orders': 'الطلبات',
    'transactions': 'المعاملات',
    'no_orders': 'لا يوجد طلبات دفع بعد',
    'no_transactions': 'لا يوجد معاملات بعد',
    'order_no': 'طلب',
    'created': 'تم الإنشاء',
    'expires': 'ينتهي في',
    'pay_now': 'ادفع الآن',
    'generate_link': 'إنشاء رابط دفع',
    'request_refund': 'طلب استرداد',
    'refund': 'استرداد',
    'payment': 'دفعة',
    'pending': 'معلق',
    'paid': 'مدفوع',
    'success': 'ناجح',
    'refunded': 'مسترد',
    'failed': 'فشل',
  };
}
