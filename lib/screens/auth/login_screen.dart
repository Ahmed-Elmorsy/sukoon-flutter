import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/decorative_background.dart';
import '../../services/api_service.dart';
import '../../services/auth_session.dart';
import '../../services/notification_service.dart';
import '../../services/app_logger.dart';
import '../../services/localization.dart';
import '../main_shell.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscure     = true;
  bool _loading     = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    AppLogger.instance.info('AUTH', 'Login attempt: ${_emailCtrl.text.trim()}');
    try {
      final login = await ApiService.login(
        login: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (login['status'] != 200) {
        _showError(login['body']['message']?.toString() ?? 'Login failed');
        return;
      }
      final token = login['body']['token'] as String;
      final userMap = login['body']['user'] as Map<String, dynamic>? ?? {};
      final userId = userMap['id'] as int? ?? 0;

      final me    = await ApiService.getMe(token);
      final profile = me['body']['profile'] as Map<String, dynamic>? ?? {};
      final roles   = me['body']['roles']   as List<dynamic>? ?? [];
      
      String role = 'renter';
      if (roles.isNotEmpty) {
        final roleName = roles[0]['role']?.toString();
        if (roleName == 'owner') {
          role = 'owner';
        } else if (roleName == 'sponsor' || roleName == 'admin') {
          role = 'admin';
        }
      }

      AuthSession.instance.save(
        token:   token,
        userId:  userId,
        role:    role,
        name:    '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
        email:   _emailCtrl.text.trim(),
        phone:   me['body']['phone']?.toString() ?? '',
        gender:  me['body']['gender']?.toString() ?? '',
        dob:     profile['age']?.toString() ?? '',
        city:    profile['city']?.toString() ?? '',
        country: profile['country']?.toString() ?? '',
        idNumber:      profile['id_number']?.toString() ?? '',
        birthDate:     profile['birth_date']?.toString() ?? '',
        address:       profile['address']?.toString() ?? '',
        profession:    profile['profession']?.toString() ?? '',
        religion:      profile['religion']?.toString() ?? '',
        maritalStatus: profile['marital_status']?.toString() ?? '',
        idExpiryDate:  profile['id_expiry_date']?.toString() ?? '',
        idIssueDate:   profile['id_issue_date']?.toString() ?? '',
        idVerified:    profile['id_verified'] == true,
      );
      AppLogger.instance.info('AUTH', 'Login success — role: $role, name: ${AuthSession.instance.name}');
      try {
        final fcmToken = await NotificationService.instance.getToken();
        AppLogger.instance.info('FCM', 'Token obtained: ${fcmToken != null ? 'YES (${fcmToken.substring(0, 20)}...)' : 'NO - running on Windows?'}');
        if (fcmToken != null) {
          await ApiService.saveFcmToken(token, fcmToken);
          AppLogger.instance.info('FCM', 'Token saved to backend successfully');
        }
      } catch (e) {
        AppLogger.instance.error('FCM', 'Failed to save FCM token: $e');
      }
      AppLogger.instance.nav('MainShell ($role)');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainShell(role: role)),
        (_) => false,
      );
    } catch (e) {
      _showError('Network error: $e');
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
        body: DecorativeBackground(
          showTopLeftBubble: true,
          showBottomRightBubble: false,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    // Logo / Title
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('🏠', style: TextStyle(fontSize: 36)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAr ? 'مرحباً بعودتك' : 'Welcome Back',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAr
                                ? 'تسجيل الدخول إلى حساب Skoon الخاص بك'
                                : 'Sign in to your Skoon account',
                            style: const TextStyle(fontSize: 15, color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Email
                    Text(
                      isAr ? 'البريد الإلكتروني' : 'Email Address',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'you@example.com'),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return isAr ? 'الرجاء إدخال البريد الإلكتروني' : 'Please enter your email';
                        }
                        if (!v.contains('@')) {
                          return isAr ? 'أدخل بريد إلكتروني صالح' : 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Password
                    Text(
                      isAr ? 'كلمة المرور' : 'Password',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.grey,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return isAr ? 'الرجاء إدخال كلمة المرور' : 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                isAr ? 'تسجيل الدخول' : 'Sign In',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Register link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isAr ? 'ليس لديك حساب؟  ' : "Don't have an account?  ",
                            style: const TextStyle(fontSize: 14, color: AppTheme.textGrey),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                            ),
                            child: Text(
                              isAr ? 'إنشاء حساب' : 'Register',
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
        ),
      ),
    );
  }
}
