import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/decorative_background.dart';
import '../../services/profile_data.dart';
import '../../services/api_service.dart';
import '../../services/auth_session.dart';
import '../../services/localization.dart';
import 'identity_photo_screen.dart';
import 'complete_profile_screen.dart';

class AboutYourselfScreen extends StatefulWidget {
  final String role;

  const AboutYourselfScreen({super.key, required this.role});

  @override
  State<AboutYourselfScreen> createState() => _AboutYourselfScreenState();
}

class _AboutYourselfScreenState extends State<AboutYourselfScreen> {
  String _occupation = 'employee';
  final _jobTitleController  = TextEditingController();
  final _companyController   = TextEditingController();
  final _universityController = TextEditingController();
  final _facultyController    = TextEditingController();

  final _companyNameController = TextEditingController();
  final _companyDetailsController = TextEditingController();
  final _targetAudienceController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyController.dispose();
    _universityController.dispose();
    _facultyController.dispose();
    _companyNameController.dispose();
    _companyDetailsController.dispose();
    _targetAudienceController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final isAr = S.isAr;

    if (widget.role == 'admin') {
      final name = _companyNameController.text.trim();
      final details = _companyDetailsController.text.trim();
      if (name.isEmpty || details.isEmpty) {
        _showError(isAr ? 'الرجاء ملء الحقول المطلوبة' : 'Please fill all required fields');
        return;
      }
      setState(() => _loading = true);
      try {
        final res = await ApiService.saveSponsorProfile(
          token: AuthSession.instance.token,
          companyName: name,
          companyDetails: details,
          targetAudience: _targetAudienceController.text.trim(),
        );
        if (res['status'] == 200 || res['status'] == 201) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IdentityPhotoScreen(role: widget.role),
            ),
          );
        } else {
          final msg = res['body']['message'] ?? 'Failed to save sponsor details';
          _showError(msg.toString());
        }
      } catch (e) {
        _showError('Network error: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    final backendType = _occupation == 'prefer_not' ? 'prefer_not_to_say' : _occupation;
    setState(() => _loading = true);
    try {
      ProfileData.instance
        ..rentalType  = backendType
        ..jobTitle    = _jobTitleController.text.trim()
        ..company     = _companyController.text.trim()
        ..university  = _universityController.text.trim()
        ..faculty     = _facultyController.text.trim();

      final res = await ApiService.saveRentalProfile(
        token: AuthSession.instance.token,
        type: backendType,
        university: _universityController.text.trim(),
        faculty: _facultyController.text.trim(),
        company: _companyController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
      );

      if (res['status'] == 200 || res['status'] == 201) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(role: widget.role),
          ),
        );
      } else {
        final msg = res['body']['message'] ?? 'Failed to update details';
        _showError(msg.toString());
      }
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
        ),
        body: DecorativeBackground(
          showTopRightBubble: true,
          showTopLeftBubble: false,
          showBottomRightBubble: false,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            widget.role == 'admin'
                                ? (isAr ? 'معلومات الشركة الراعية' : 'Sponsor Details')
                                : S.text('tell_us_about'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.role == 'admin'
                                ? (isAr ? 'أخبرنا المزيد عن شركتك وأهدافك' : 'Tell us more about your company and targets')
                                : S.text('about_desc'),
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.textGrey,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (widget.role != 'admin') ...[
                            Text(
                              S.text('i_am_a'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRadioOption(S.text('employee'), 'employee'),
                            const SizedBox(height: 12),
                            _buildRadioOption(S.text('student'), 'student'),
                            const SizedBox(height: 12),
                            _buildRadioOption(S.text('other'), 'other'),
                            const SizedBox(height: 12),
                            _buildRadioOption(S.text('prefer_not_say'), 'prefer_not'),
                            const SizedBox(height: 24),
                            // Details (shown conditionally based on selection)
                            if (_occupation == 'employee') _buildEmployeeDetails(),
                            if (_occupation == 'student') _buildStudentDetails(),
                          ] else ...[
                            _buildSponsorDetails(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _continue,
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(S.text('continue')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, String value) {
    final isSelected = _occupation == value;
    return GestureDetector(
      onTap: () => setState(() => _occupation = value),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.lightGrey,
                width: 2,
              ),
            ),
            child: isSelected
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
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? AppTheme.textDark : AppTheme.textGrey,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsContainer({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.selectedCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: S.isAr ? BorderSide.none : BorderSide(
            color: AppTheme.primaryBlue.withValues(alpha: 0.5),
            width: 3,
          ),
          right: S.isAr ? BorderSide(
            color: AppTheme.primaryBlue.withValues(alpha: 0.5),
            width: 3,
          ) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeDetails() {
    final isAr = S.isAr;
    return _buildDetailsContainer(
      title: S.text('emp_details'),
      children: [
        _buildField(
          S.text('job_title'),
          _jobTitleController,
          isAr ? 'مثال: مهندس برمجيات' : 'e.g. Software Engineer',
        ),
        const SizedBox(height: 16),
        _buildField(
          S.text('company_opt'),
          _companyController,
          isAr ? 'مثال: شركة أكيل' : 'e.g. Acme Corp',
        ),
      ],
    );
  }

  Widget _buildStudentDetails() {
    final isAr = S.isAr;
    return _buildDetailsContainer(
      title: S.text('std_details'),
      children: [
        _buildField(
          S.text('university'),
          _universityController,
          isAr ? 'مثال: جامعة القاهرة' : 'e.g. Cairo University',
        ),
        const SizedBox(height: 16),
        _buildField(
          S.text('faculty'),
          _facultyController,
          isAr ? 'مثال: الهندسة' : 'e.g. Engineering',
        ),
      ],
    );
  }

  Widget _buildSponsorDetails() {
    final isAr = S.isAr;
    return _buildDetailsContainer(
      title: isAr ? 'معلومات الشركة' : 'Company Information',
      children: [
        _buildField(
          isAr ? 'اسم الشركة *' : 'Company Name *',
          _companyNameController,
          isAr ? 'مثال: شركة سكون' : 'e.g. Sukoon Corp',
        ),
        const SizedBox(height: 16),
        _buildField(
          isAr ? 'تفاصيل الشركة *' : 'Company Details *',
          _companyDetailsController,
          isAr ? 'ماذا تفعل الشركة؟' : 'What does the company do?',
        ),
        const SizedBox(height: 16),
        _buildField(
          isAr ? 'الجمهور المستهدف (اختياري)' : 'Target Audience (Optional)',
          _targetAudienceController,
          isAr ? 'مثال: الطلاب والشباب' : 'e.g. Students & Youth',
        ),
      ],
    );
  }
}
