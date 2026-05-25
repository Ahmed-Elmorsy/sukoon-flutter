import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/step_progress_bar.dart';
import '../../services/api_service.dart';
import '../../services/auth_session.dart';
import '../../services/profile_data.dart';
import '../../services/notification_service.dart';
import '../../services/localization.dart';
import 'otp_verification_screen.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String role;

  const RegistrationScreen({super.key, required this.role});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _gender = 'male';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final emailText = _emailController.text.trim();
      final enteredPhone = _phoneController.text.trim();
      final fullPhone = enteredPhone.startsWith('+') ? enteredPhone : '+20$enteredPhone';

      final backendRole = widget.role == 'renter'
          ? 'rental'
          : widget.role == 'admin'
              ? 'sponsor'
              : 'owner';

      final reg = await ApiService.register(
        phone: fullPhone,
        email: emailText,
        password: _passwordController.text,
        gender: _gender,
        role: backendRole,
      );
      if (reg['status'] != 200 && reg['status'] != 201) {
        final msg = reg['body']['message'] ?? 'Registration failed';
        _showError(msg.toString());
        return;
      }
      final login = await ApiService.login(
        login: emailText,
        password: _passwordController.text,
      );
      if (login['status'] != 200) {
        _showError('Login after registration failed');
        return;
      }
      final token = login['body']['token'] as String;
      final userMap = login['body']['user'] as Map<String, dynamic>? ?? {};
      final userId = userMap['id'] as int? ?? 0;

      final me = await ApiService.getMe(token);
      final meProfile = me['body']['profile'] as Map<String, dynamic>? ?? {};
      final roles = me['body']['roles'] as List<dynamic>? ?? [];
      
      String resolvedRole = 'renter';
      if (roles.isNotEmpty) {
        final roleName = roles[0]['role']?.toString();
        if (roleName == 'owner') {
          resolvedRole = 'owner';
        } else if (roleName == 'sponsor' || roleName == 'admin') {
          resolvedRole = 'admin';
        }
      }

      AuthSession.instance.save(
        token:   token,
        userId:  userId,
        role:    resolvedRole,
        name:    '${meProfile['first_name'] ?? ''} ${meProfile['last_name'] ?? ''}'.trim(),
        email:   emailText,
        phone:   me['body']['phone']?.toString() ?? '',
        gender:  me['body']['gender']?.toString() ?? '',
        dob:     meProfile['age']?.toString() ?? '',
        city:    meProfile['city']?.toString() ?? '',
        country: meProfile['country']?.toString() ?? '',
        idNumber:      meProfile['id_number']?.toString() ?? '',
        birthDate:     meProfile['birth_date']?.toString() ?? '',
        address:       meProfile['address']?.toString() ?? '',
        profession:    meProfile['profession']?.toString() ?? '',
        religion:      meProfile['religion']?.toString() ?? '',
        maritalStatus: meProfile['marital_status']?.toString() ?? '',
        idExpiryDate:  meProfile['id_expiry_date']?.toString() ?? '',
        idIssueDate:   meProfile['id_issue_date']?.toString() ?? '',
        idVerified:    meProfile['id_verified'] == true,
      );
      try {
        final fcmToken = await NotificationService.instance.getToken();
        if (fcmToken != null) await ApiService.saveFcmToken(token, fcmToken);
      } catch (_) {}
      
      ProfileData.instance
        ..firstName = ''
        ..lastName  = '';
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(phone: fullPhone, role: resolvedRole),
        ),
        (_) => false,
      );
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = S.isAr;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryBlue),
            label: Text(
              isAr ? 'رجوع' : 'Back',
              style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 16),
            ),
          ),
          leadingWidth: 100,
          title: Text(
            S.text('create_account'),
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const StepProgressBar(currentStep: 1, totalSteps: 3),
                // Mobile Number
                Text(
                  S.text('mobile_number'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        children: [
                          Text('🇪🇬', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            '+20',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '10 0000 0000',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isAr ? 'مطلوب' : 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Email Address
                Text(
                  S.text('email_address'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return isAr ? 'الرجاء إدخال البريد الإلكتروني' : 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return isAr ? 'الرجاء إدخال بريد إلكتروني صالح' : 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Password
                Text(
                  S.text('password'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return isAr ? 'الرجاء إدخال كلمة المرور' : 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return isAr
                          ? 'يجب أن تتكون كلمة المرور من ٦ أحرف على الأقل'
                          : 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Confirm Password
                Text(
                  S.text('confirm_password'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.grey,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return isAr ? 'كلمات المرور غير متطابقة' : 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Gender
                Text(
                  S.text('gender'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildGenderOption(S.text('male'), 'male'),
                    const SizedBox(width: 32),
                    _buildGenderOption(S.text('female'), 'female'),
                  ],
                ),
                const SizedBox(height: 24),
                // Terms
                Center(
                  child: Text(
                    S.text('terms_privacy'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _createAccount,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(S.text('create_account')),
                  ),
                ),
                const SizedBox(height: 20),
                // Sign In Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAr ? 'لديك حساب بالفعل؟  ' : 'Already have an account?  ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: Text(
                          isAr ? 'تسجيل الدخول' : 'Sign In',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String label, String value) {
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _gender == value
                    ? AppTheme.primaryBlue
                    : AppTheme.lightGrey,
                width: 2,
              ),
            ),
            child: _gender == value
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: _gender == value ? AppTheme.textDark : AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
